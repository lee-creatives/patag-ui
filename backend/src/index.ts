import { buildApp } from './app.ts';
import { SupabaseBlobStore } from './blobs.ts';
import { config, createPool, requireEnv } from './config.ts';
import { migrate, pgDb } from './db.ts';
import { Store } from './store.ts';

requireEnv('SUPABASE_URL', 'SUPABASE_SECRET_KEY');
const db = pgDb(createPool());
await migrate(db, m => console.log(m));
const store = new Store(db);
const blobs = new SupabaseBlobStore(config.supabaseUrl, config.supabaseSecretKey, config.bucket);
const app = buildApp({ store, blobs, allowDemo: config.allowDemo, corsOrigins: config.corsOrigins, logger: true });

const purge = setInterval(() => store.purgeExpiredSessions().catch(() => {}), 60 * 60 * 1000);
purge.unref();

await app.listen({ port: config.port, host: config.host });
console.log(`PATAG API http://${config.host}:${config.port}/api${config.allowDemo ? '  (demo logins ENABLED: local use only)' : ''}`);

for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.once(signal, async () => { await app.close(); await db.close(); process.exit(0); });
}
