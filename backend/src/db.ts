import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

/** The minimal database surface the store needs; implemented by pg and (in tests) PGlite. */
export interface Db {
  query<T = Record<string, any>>(sql: string, params?: unknown[]): Promise<{ rows: T[] }>;
  /** Runs one or more statements without parameters. */
  exec(sql: string): Promise<void>;
  /** Runs fn inside a transaction; nested calls reuse the outer transaction. */
  tx<T>(fn: (db: Db) => Promise<T>): Promise<T>;
  close(): Promise<void>;
}

export function pgDb(pool: pg.Pool): Db {
  return {
    query: (sql, params) => pool.query(sql, params as any[]) as any,
    exec: async sql => { await pool.query(sql); },
    async tx(fn) {
      const client = await pool.connect();
      const inner: Db = {
        query: (sql, params) => client.query(sql, params as any[]) as any,
        exec: async sql => { await client.query(sql); },
        tx: f => f(inner),
        close: async () => {},
      };
      try {
        await client.query('begin');
        const result = await fn(inner);
        await client.query('commit');
        return result;
      } catch (e) {
        await client.query('rollback').catch(() => {});
        throw e;
      } finally {
        client.release();
      }
    },
    close: () => pool.end(),
  };
}

const migrationsDir = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'migrations');

/** Applies migrations/*.sql in name order, each once, each in its own transaction. */
export async function migrate(db: Db, log: (m: string) => void = () => {}) {
  await db.exec(`create table if not exists schema_migrations (name text primary key, applied_at timestamptz not null default now());
    alter table schema_migrations enable row level security;`);
  const done = new Set((await db.query<{ name: string }>('select name from schema_migrations')).rows.map(r => r.name));
  const files = (await readdir(migrationsDir)).filter(f => f.endsWith('.sql')).sort();
  for (const file of files) {
    if (done.has(file)) continue;
    const sql = await readFile(path.join(migrationsDir, file), 'utf8');
    await db.tx(async t => {
      await t.exec(sql);
      await t.query('insert into schema_migrations (name) values ($1)', [file]);
    });
    log(`applied ${file}`);
  }
}
