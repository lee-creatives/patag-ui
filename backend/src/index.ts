import { buildApp } from './app.ts';
import { SupabaseBlobStore } from './blobs.ts';
import { config, createPool, demoExposureError, lanUrls, requireEnv } from './config.ts';
import { migrate, pgDb } from './db.ts';
import { createGeocoder } from './geocode.ts';
import { Store } from './store.ts';

const exposure = demoExposureError(config.host, config.allowDemo, config.allowDemoOnLan);
if (exposure) {
  console.error(exposure);
  process.exit(1);
}
requireEnv('SUPABASE_URL', 'SUPABASE_SECRET_KEY');
const db = pgDb(createPool());
await migrate(db, m => console.log(m));
const store = new Store(db);
const blobs = new SupabaseBlobStore(config.supabaseUrl, config.supabaseSecretKey, config.bucket);
const app = buildApp({
  store, blobs, allowDemo: config.allowDemo, corsOrigins: config.corsOrigins, trustProxy: config.trustProxy, logger: true,
  geocode: createGeocoder({ token: config.mapboxToken, log: m => console.warn(m) }),
});

const purge = setInterval(() => store.purgeExpiredSessions().catch(() => {}), 60 * 60 * 1000);
purge.unref();

await app.listen({ port: config.port, host: config.host });
const demo = config.allowDemo ? '  (demo logins ENABLED: local use only)' : '';
if (config.host === '0.0.0.0') {
  console.log(`PATAG API listening on all interfaces, port ${config.port}${demo}`);
  console.log('  This PC / Android emulator: http://127.0.0.1:%d/api  (emulator: http://10.0.2.2:%d/api)', config.port, config.port);
  for (const url of lanUrls(config.port)) console.log(`  Phones on the same Wi-Fi:   ${url}`);
} else {
  console.log(`PATAG API http://${config.host}:${config.port}/api${demo}`);
}

for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.once(signal, async () => { await app.close(); await db.close(); process.exit(0); });
}
