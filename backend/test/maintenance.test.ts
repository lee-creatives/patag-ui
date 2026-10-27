// The exact request sequence maintenance-mobile performs, against real SQL.
import test from 'node:test';
import assert from 'node:assert/strict';
import { originAllowed } from '../src/app.ts';
import { PNG, startServer } from './helpers.ts';

const CREW = { name: 'Crew Mobile', email: 'crew-mobile@example.test', password: 'Crew-Mobile-12345', role: 'maintenance', teamId: 'team-1' };

test('crew mobile workflow: login, scoping, evidence, completion, return, resolve, notifications', async () => {
  const { call, close } = await startServer();
  try {
    const admin = (await call('/auth/demo', { role: 'admin' })).data.token;
    assert.equal((await call('/users', CREW, admin)).status, 201);

    // 1. Login through the maintenance portal; citizens are refused there.
    const login = await call('/auth/login', { email: CREW.email, password: CREW.password, role: 'maintenance' });
    assert.equal(login.status, 200);
    assert.equal(login.data.user.role, 'maintenance');
    assert.equal(login.data.user.teamId, 'team-1');
    const crew = login.data.token;
    await call('/auth/register', { name: 'Some Citizen', email: 'cit@example.test', password: 'Citizen-Pass-12345', address: { barangay: 'Guinhawa', city: 'Malolos', province: 'Bulacan' } });
    assert.equal((await call('/auth/login', { email: 'cit@example.test', password: 'Citizen-Pass-12345', role: 'maintenance' })).status, 401);

    // 2. Bootstrap is team-scoped; another team's report is forbidden.
    const boot = (await call('/bootstrap', undefined, crew)).data;
    assert.ok(boot.reports.length > 0);
    assert.ok(boot.reports.every((r: any) => r.teamId === 'team-1'));
    assert.ok(boot.teams.find((t: any) => t.id === 'team-1').members.includes('Crew Mobile'));
    assert.equal((await call('/reports/PTG-2026-0103/events', { action: 'assign', teamId: 'team-2' }, admin)).status, 200);
    assert.equal((await call('/reports/PTG-2026-0103', undefined, crew)).status, 403);
    assert.equal((await call('/reports/PTG-2026-0103/events', { action: 'start' }, crew)).status, 403);

    // 3. PTG-2026-0104 is Assigned to team-1 in the seed data.
    const id = 'PTG-2026-0104';
    const event = (action: string, payload = {}, token = crew) => call(`/reports/${id}/events`, { action, ...payload }, token);
    const before = (await call('/uploads', { data: PNG, name: 'before.png', kind: 'before' }, crew)).data;
    const r1 = await event('before-photos', { photos: [before] });
    assert.equal(r1.status, 200);
    assert.equal(r1.data.status, 'Assigned');
    assert.equal(r1.data.photos.at(-1).kind, 'before');

    // 6. The old app action names are rejected with a JSON error, not silently accepted.
    for (const action of ['start_repair', 'upload_evidence']) {
      const old = await event(action, { note: 'x' });
      assert.equal(old.status, 409);
      assert.equal(typeof old.data.error, 'string');
    }

    const started = await event('start', { note: 'Crew on site.' });
    assert.equal(started.data.status, 'In Progress');
    const progressPhoto = (await call('/uploads', { data: PNG, name: 'progress.png' }, crew)).data;
    const progress = await event('progress', { phase: 'Base preparation', note: 'Damaged material removed.', photos: [{ id: progressPhoto.id, url: progressPhoto.url, name: progressPhoto.name }] });
    assert.equal(progress.status, 200);
    assert.equal(progress.data.updates.at(-1).phase, 'Base preparation');
    assert.equal(progress.data.updates.at(-1).photos[0].kind, 'after');

    assert.equal((await event('complete', { note: 'Patched.' })).status, 400);
    assert.equal((await event('complete', { note: 'Patched.', photos: [] })).status, 409);
    const after = (await call('/uploads', { data: PNG, name: 'after.png', kind: 'after' }, crew)).data;
    const done = await event('complete', { note: 'Patch compacted and lane cleared.', photos: [after] });
    assert.equal(done.status, 200);
    assert.equal(done.data.status, 'In Progress');
    assert.equal(done.data.completion.state, 'Awaiting Verification');
    assert.equal(done.data.completion.photos[0].kind, 'after');
    assert.equal((await event('resolve')).status, 409);
    assert.equal((await event('before-photos', { photos: [before] })).status, 409);

    // 4. Admin returns the work; the crew is told; the crew completes again; admin resolves.
    assert.equal((await event('return', { note: 'Seal the patch edge.' }, admin)).data.completion.state, 'Additional Work Requested');
    const notes = (await call('/bootstrap', undefined, crew)).data.notifications;
    assert.ok(notes.some((n: any) => n.reportId === id && n.title === `${id}: more work requested`));
    assert.ok(notes.some((n: any) => n.reportId === 'PTG-2026-0103') === false, 'team-2 notifications are not shown to team-1');
    await event('complete', { note: 'Edge sealed.', photos: [after] });
    const resolved = await event('resolve', { note: 'Verified on site.' }, admin);
    assert.equal(resolved.data.status, 'Resolved');
    assert.ok((await call('/bootstrap', undefined, crew)).data.notifications.some((n: any) => n.title === `${id}: repair verified and resolved`));

    // 5. Marking read only touches this crew's notifications.
    const mine = (await call('/bootstrap', undefined, crew)).data.notifications;
    assert.equal((await call('/notifications/read', { id: mine[0].id }, crew)).status, 200);
    const afterOne = (await call('/bootstrap', undefined, crew)).data.notifications;
    assert.equal(afterOne.find((n: any) => n.id === mine[0].id).read, true);
    assert.ok(afterOne.some((n: any) => !n.read));
    const adminUnreadBefore = (await call('/bootstrap', undefined, admin)).data.notifications.filter((n: any) => !n.read).length;
    await call('/notifications/read', { id: 'all' }, crew);
    assert.ok((await call('/bootstrap', undefined, crew)).data.notifications.every((n: any) => n.read));
    assert.equal((await call('/bootstrap', undefined, admin)).data.notifications.filter((n: any) => !n.read).length, adminUnreadBefore);
  } finally { await close(); }
});

test('assignment notifies the team by name, and a moved crew member sees the new team on the next poll', async () => {
  const { call, close } = await startServer();
  try {
    const admin = (await call('/auth/demo', { role: 'admin' })).data.token;
    const created = (await call('/users', CREW, admin)).data;
    const crew = (await call('/auth/login', { email: CREW.email, password: CREW.password, role: 'maintenance' })).data.token;
    await call('/reports/PTG-2026-0109/events', { action: 'assign', teamId: 'team-1', priority: 'Medium' }, admin);
    assert.ok((await call('/bootstrap', undefined, crew)).data.notifications.some((n: any) => n.title === 'PTG-2026-0109 assigned to Road Crew Alpha'));

    assert.equal((await call('/users', { id: created.id, teamId: 'team-2' }, admin, 'PATCH')).status, 200);
    const boot = (await call('/bootstrap', undefined, crew)).data;
    assert.equal(boot.user.teamId, 'team-2');
    assert.ok(boot.reports.every((r: any) => r.teamId === 'team-2'));
    assert.ok(!boot.reports.some((r: any) => r.id === 'PTG-2026-0109'));
  } finally { await close(); }
});

test('local wildcard CORS is limited to localhost', () => {
  const allowed = ['http://127.0.0.1:5173', 'http://localhost:*'];
  assert.ok(originAllowed('http://127.0.0.1:5173', allowed));
  assert.ok(originAllowed('http://localhost:61234', allowed));
  assert.ok(!originAllowed('http://127.0.0.1:61234', allowed));
  assert.ok(!originAllowed('http://localhost.evil.example:80', allowed));
  assert.ok(!originAllowed('https://localhost:443', allowed));
  assert.ok(!originAllowed('http://localhost:1', []));
});
