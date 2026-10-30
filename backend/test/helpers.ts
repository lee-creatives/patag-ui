import { PGlite, type Transaction } from '@electric-sql/pglite';
import { buildApp } from '../src/app.ts';
import { MemoryBlobStore } from '../src/blobs.ts';
import { migrate, type Db } from '../src/db.ts';
import { seedAll } from '../src/seed.ts';
import { Store } from '../src/store.ts';

// Real Postgres (WASM) so the migrations and every SQL statement are exercised.
function pgliteDb(pg: PGlite): Db {
  const wrap = (q: PGlite | Transaction): Db => ({
    query: (sql, params) => q.query(sql, params) as any,
    exec: async sql => { await q.exec(sql); },
    tx: fn => (q === pg ? pg.transaction(t => fn(wrap(t))) : fn(wrap(q))),
    close: () => pg.close(),
  });
  return wrap(pg);
}

export async function startServer({ allowDemo = true, bodyLimit = undefined as number | undefined, trustProxy = false as boolean | number, corsOrigins = ["http://127.0.0.1:5173"] } = {}) {
  const db = pgliteDb(await PGlite.create());
  await migrate(db);
  const store = new Store(db);
  await seedAll(store);
  const app = buildApp({ store, blobs: new MemoryBlobStore(), allowDemo, bodyLimit, trustProxy, corsOrigins });
  await app.listen({ port: 0, host: '127.0.0.1' });
  const address = app.server.address() as { port: number };
  const base = `http://127.0.0.1:${address.port}/api`;
  async function call(path: string, body?: unknown, token?: string, method?: string) {
    const res = await fetch(base + path, {
      method: method || (body ? 'POST' : 'GET'),
      headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
      body: body ? JSON.stringify(body) : undefined,
    });
    return { status: res.status, data: (await res.json()) as any, headers: res.headers };
  }
  return { base, call, store, close: async () => { await app.close(); await db.close(); } };
}

export const PNG = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
