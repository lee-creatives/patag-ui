// Reads backend/.env (loaded by `node --env-file-if-exists=.env`). Secrets never leave this process.
import { readFileSync } from 'node:fs';
import pg from 'pg';

const env = process.env;
const bool = (v: string | undefined) => /^(1|true|yes)$/i.test(v ?? '');

export const config = {
  port: Number(env.PORT || 4100),
  host: env.HOST || '127.0.0.1',
  allowDemo: bool(env.ALLOW_DEMO),
  corsOrigins: (env.CORS_ORIGINS || 'http://127.0.0.1:5173,http://127.0.0.1:5174,http://localhost:5173,http://localhost:5174')
    .split(',').map(s => s.trim()).filter(Boolean),
  supabaseUrl: env.SUPABASE_URL || '',
  supabaseSecretKey: env.SUPABASE_SECRET_KEY || '',
  bucket: env.STORAGE_BUCKET || 'report-photos',
};

export function requireEnv(...names: string[]) {
  const missing = names.filter(n => !env[n]);
  if (missing.length) {
    console.error(`Missing ${missing.join(', ')} in backend/.env. Copy backend/.env.example and fill it in.`);
    process.exit(1);
  }
}

/** Postgres pool for the Supabase session pooler (or any DATABASE_URL). */
export function createPool() {
  const ca = env.SUPABASE_DB_CA_CERT ? readFileSync(env.SUPABASE_DB_CA_CERT, 'utf8') : undefined;
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
