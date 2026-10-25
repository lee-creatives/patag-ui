import { seedReports, seedSettings, seedTeams, seedUsers } from './seed-data.ts';
import type { Store } from './store.ts';

export async function seedAll(store: Store) {
  await store.tx(async tx => {
    const { rows } = await tx.db.query('select 1 from settings where id = 1');
    if (!rows.length) await tx.setSettings(seedSettings);
    for (const team of seedTeams) await tx.insertTeam(team);
    for (const user of seedUsers) await tx.insertUser(user);
    for (const report of seedReports()) await tx.insertReport(report);
  });
}
