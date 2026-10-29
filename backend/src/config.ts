// Reads backend/.env (loaded by `node --env-file-if-exists=.env`). Secrets never leave this process.
import { readFileSync } from 'node:fs';
import { networkInterfaces } from 'node:os';
import pg from 'pg';

const env = process.env;
const bool = (v: string | undefined) => /^(1|true|yes)$/i.test(v ?? '');

/** `--lan` (npm run api:lan) listens on every network interface so phones on the same Wi-Fi can connect. */
const lan = process.argv.includes('--lan');

/**
 * TRUST_PROXY: unset/false = use the socket address (local runs).
 * A number = trust that many proxy hops (e.g. 1 behind Render's load balancer).
 * Otherwise a comma-separated list of proxy IPs/CIDRs.
 */
export function parseTrustProxy(v: string | undefined): boolean | number | string[] {
  const value = (v ?? '').trim();
  if (!value || /^(0|false|no)$/i.test(value)) return false;
  if (/^\d+$/.test(value)) return Number(value);
  if (/^(true|yes)$/i.test(value)) return 1; // never trust an unlimited chain of X-Forwarded-For hops
  return value.split(',').map(s => s.trim()).filter(Boolean);
}

export const config = {
  port: Number(env.PORT || 4100),
  host: lan ? '0.0.0.0' : env.HOST || '127.0.0.1',
  allowDemo: bool(env.ALLOW_DEMO),
  allowDemoOnLan: bool(env.ALLOW_DEMO_ON_LAN),
  trustProxy: parseTrustProxy(env.TRUST_PROXY),
  corsOrigins: (env.CORS_ORIGINS || 'http://127.0.0.1:5173,http://127.0.0.1:5174,http://localhost:5173,http://localhost:5174')
    .split(',').map(s => s.trim()).filter(Boolean),
  supabaseUrl: env.SUPABASE_URL || '',
  supabaseSecretKey: env.SUPABASE_SECRET_KEY || '',
  bucket: env.STORAGE_BUCKET || 'report-photos',
};

const loopback = (host: string) => ['127.0.0.1', 'localhost', '::1'].includes(host);

/** Demo logins let anyone act as any seeded role, so they must not be reachable from the network by accident. */
export function demoExposureError(host: string, allowDemo: boolean, allowDemoOnLan: boolean) {
  if (!allowDemo || loopback(host) || allowDemoOnLan) return null;
  return `Refusing to start: ALLOW_DEMO=true while listening on ${host} would let anyone on the network log in as any demo account. ` +
    'Set ALLOW_DEMO=false, or HOST=127.0.0.1, or (for a classroom demo on a trusted network only) ALLOW_DEMO_ON_LAN=true.';
}

/** URLs a phone on the same network can use, e.g. http://192.168.1.23:4100/api. */
export function lanUrls(port: number) {
  return Object.values(networkInterfaces()).flat()
    .filter(i => i && i.family === 'IPv4' && !i.internal)
    .map(i => `http://${i!.address}:${port}/api`);
}

export function requireEnv(...names: string[]) {
  const missing = names.filter(n => !env[n]);
  if (missing.length) {
    console.error(`Missing ${missing.join(', ')} in backend/.env. Copy backend/.env.example and fill it in.`);
    process.exit(1);
  }
}

/** SUPABASE_DB_CA_CERT is a file path, or the PEM text itself (handy on hosts that only offer env vars). */
function caCert() {
  const v = env.SUPABASE_DB_CA_CERT;
  if (!v) return undefined;
  return v.includes('-----BEGIN CERTIFICATE-----') ? v.replace(/\\n/g, '\n') : readFileSync(v, 'utf8');
}

/** Postgres pool for the Supabase session pooler (or any DATABASE_URL). */
export function createPool() {
  const ca = caCert();
  if (!ca && !bool(env.DB_SSL_DISABLE)) {
    console.warn('SUPABASE_DB_CA_CERT not set: TLS is encrypted but the server certificate is not verified. Download the CA from Supabase > Database settings.');
  }
  const ssl = bool(env.DB_SSL_DISABLE) ? false : ca ? { ca, rejectUnauthorized: true } : { rejectUnauthorized: false };
  if (env.DATABASE_URL) return new pg.Pool({ connectionString: env.DATABASE_URL, ssl, max: 10 });
  requireEnv('SUPABASE_DB_HOST', 'SUPABASE_DB_USER', 'SUPABASE_DB_PASSWORD');
  return new pg.Pool({
    host: env.SUPABASE_DB_HOST, port: Number(env.SUPABASE_DB_PORT || 5432), database: env.SUPABASE_DB_NAME || 'postgres',
    user: env.SUPABASE_DB_USER, password: env.SUPABASE_DB_PASSWORD, ssl, max: 10,
  });
}
