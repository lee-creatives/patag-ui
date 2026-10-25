import { createPool } from '../src/config.ts';
import { migrate, pgDb } from '../src/db.ts';

const db = pgDb(createPool());
try {
  await migrate(db, m => console.log(m));
  console.log('Database is up to date.');
} finally {
  await db.close();
}
