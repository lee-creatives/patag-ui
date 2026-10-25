// Creates (or resets the password of) a real LGU administrator account.
// Usage: set ADMIN_EMAIL, ADMIN_NAME and ADMIN_PASSWORD in the environment, then `npm run create-admin`.
import { createPool, requireEnv } from '../src/config.ts';
import { migrate, pgDb } from '../src/db.ts';
import { registrationFields } from '../src/domain.ts';
import { hashPassword } from '../src/passwords.ts';
import { Store } from '../src/store.ts';

requireEnv('ADMIN_EMAIL', 'ADMIN_NAME', 'ADMIN_PASSWORD');
const f = registrationFields({ name: process.env.ADMIN_NAME, email: process.env.ADMIN_EMAIL, password: process.env.ADMIN_PASSWORD });
const db = pgDb(createPool());
try {
  await migrate(db);
  const store = new Store(db);
  const passwordHash = await hashPassword(f.password);
  const existing = await store.userByEmail(f.email);
  if (existing) {
    await store.updateUser({ ...existing, role: 'admin', teamId: null, active: true, passwordHash });
    console.log(`Updated ${f.email}: role admin, password reset.`);
  } else {
    await store.insertUser({ name: f.name, email: f.email, role: 'admin', active: true, teamId: null, address: null, emailVerified: true, passwordHash });
    console.log(`Created administrator ${f.email}.`);
  }
} catch (e) {
  console.error((e as Error).message);
  process.exitCode = 1;
} finally {
  await db.close();
}
