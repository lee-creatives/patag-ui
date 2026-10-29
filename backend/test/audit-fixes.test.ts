// Regression tests for the issues found in the system audit.
import test from 'node:test';
import assert from 'node:assert/strict';
import { PNG, startServer } from './helpers.ts';

const citizenInput = (email: string) => ({
  name: 'Audit Citizen', email, password: 'Audit-Citizen-12345',
  address: { barangay: 'Guinhawa', city: 'Malolos', province: 'Bulacan' },
});
const report = (photo: object) => ({
  description: 'Audit pothole', severity: 'High', photos: [photo],
  location: { road: 'Audit Road', barangay: 'Guinhawa', city: 'Malolos', province: 'Bulacan', coordinates: { lat: 14.85, lng: 120.81 } },
});

test('web dialogs: null and empty fields are treated as not provided; dates are strict', async () => {
  const { call, close } = await startServer();
  try {
    const admin = (await call('/auth/demo', { role: 'admin' })).data.token;
    const nulls = { teamId: null, priority: null, targetDate: null, duplicateOf: null, jurisdiction: null };
    const verify = await call('/reports/PTG-2026-0101/events', { action: 'verify', note: 'Confirmed.', ...nulls }, admin);
    assert.equal(verify.status, 200);
    assert.equal(verify.data.status, 'Verified');
    const assign = await call('/reports/PTG-2026-0101/events', { action: 'assign', teamId: 'team-1', priority: 'High', targetDate: '', note: '' }, admin);
    assert.equal(assign.status, 200);
    assert.equal(assign.data.assignment.targetDate, null);
    for (const bad of ['2026-99-99', '2026-02-30', '2026-10-01<script>', '2026-10-01T00:00:00Z']) {
      assert.equal((await call('/reports/PTG-2026-0109/events', { action: 'assign', teamId: 'team-1', targetDate: bad }, admin)).status, 400, bad);
    }
  } finally { await close(); }
});

test('rate limit cannot be dodged with a query string', async () => {
  const { base, close } = await startServer();
  try {
    let last = 0;
    for (let i = 0; i < 21; i++) {
      last = (await fetch(`${base}/auth/login?n=${i}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: 'absent@example.test', password: 'wrong' }),
      })).status;
    }
    assert.equal(last, 429);
  } finally { await close(); }
});

test('history records who acted; publication notes say what changed', async () => {
  const { call, close } = await startServer();
  try {
    const admin = (await call('/auth/demo', { role: 'admin' })).data.token;
    const verified = (await call('/reports/PTG-2026-0101/events', { action: 'verify', note: 'Looks right.' }, admin)).data;
    const entry = verified.history.at(-1);
    assert.equal(entry.actor, 'admin');
    assert.equal(entry.actorId, 'admin-1');
    assert.equal(entry.actorName, 'Andrea Reyes');
    const published = (await call('/reports/PTG-2026-0101/events', { action: 'publication', approved: false }, admin)).data;
    assert.match(published.history.at(-1).note, /withdrawn/);

    const citizen = (await call('/auth/register', citizenInput('who@example.test'))).data;
    const photo = (await call('/uploads', { data: PNG, name: 'p.png' }, citizen.token)).data;
    const created = (await call('/reports', report(photo), citizen.token)).data;
    assert.equal(created.history[0].actorName, 'Audit Citizen');
  } finally { await close(); }
});

test('notifications reach only the people who need them', async () => {
  const { call, close } = await startServer();
  try {
    const admin = (await call('/auth/demo', { role: 'admin' })).data.token;
    const crew = (await call('/auth/demo', { role: 'maintenance' })).data.token;
    const reg = (await call('/auth/register', citizenInput('notes@example.test'))).data;
    const photo = (await call('/uploads', { data: PNG, name: 'p.png' }, reg.token)).data;
    const id = (await call('/reports', report(photo), reg.token)).data.id;
    const notes = async (token: string) => (await call('/bootstrap', undefined, token)).data.notifications.filter((n: any) => n.reportId === id);
    const ev = (action: string, payload = {}, token = admin) => call(`/reports/${id}/events`, { action, ...payload }, token);

    assert.equal((await notes(admin)).length, 1, 'admins hear about new reports');
    await ev('flag', { note: 'Internal follow-up' });
    await ev('forward', { jurisdiction: 'Provincial office' });
    await ev('publication', { approved: true });
    assert.equal((await notes(reg.token)).length, 1, 'internal admin actions do not notify the citizen');
    assert.equal((await notes(admin)).length, 1, 'admins are not notified of their own actions');

    await ev('verify');
    assert.equal((await notes(reg.token)).length, 2, 'status change notifies the citizen');
    await ev('assign', { teamId: 'team-1' });
    assert.equal((await notes(crew)).length, 1, 'team hears about the assignment');
    await ev('start', {}, crew);
    assert.equal((await notes(crew)).length, 1, 'crew is not notified of its own action');
    assert.equal((await notes(admin)).length, 2, 'admins hear the crew started');
  } finally { await close(); }
});

test('photos must be uploaded by the person attaching them (or already be on the report)', async () => {
  const { call, close } = await startServer();
  try {
    const a = (await call('/auth/register', citizenInput('a@example.test'))).data.token;
    const b = (await call('/auth/register', citizenInput('b@example.test'))).data.token;
    const aPhoto = (await call('/uploads', { data: PNG, name: 'a.png' }, a)).data;
    assert.equal((await call('/reports', report(aPhoto), b)).status, 400, "B cannot submit A's photo");
    const id = (await call('/reports', report(aPhoto), a)).data.id;

    const admin = (await call('/auth/demo', { role: 'admin' })).data.token;
    const crew = (await call('/auth/demo', { role: 'maintenance' })).data.token;
    await call(`/reports/${id}/events`, { action: 'verify' }, admin);
    await call(`/reports/${id}/events`, { action: 'assign', teamId: 'team-1' }, admin);
    // The report's own evidence may be referenced again (e.g. by a teammate's completion screen).
    assert.equal((await call(`/reports/${id}/events`, { action: 'before-photos', photos: [aPhoto] }, crew)).status, 200);
    const strangers = (await call('/uploads', { data: PNG, name: 's.png' }, b)).data;
    assert.equal((await call(`/reports/${id}/events`, { action: 'before-photos', photos: [strangers] }, crew)).status, 400);
  } finally { await close(); }
});

test('profile edits cannot undo an admin role/active change', async () => {
  const { call, store, close } = await startServer();
  try {
    const admin = (await call('/auth/demo', { role: 'admin' })).data.token;
    const reg = (await call('/auth/register', citizenInput('profile@example.test'))).data;
    await call('/users', { id: reg.user.id, active: false }, admin, 'PATCH');
    // A /me write that started before the deactivation must not set active back to true.
    await store.updateProfile(reg.user.id, 'New Name', undefined);
    const user = await store.userById(reg.user.id);
    assert.equal(user!.active, false);
    assert.equal(user!.name, 'New Name');
  } finally { await close(); }
});

test('duplicates must point at a visible original; citizens get 403 on events; no staff names for citizens', async () => {
  const { call, close } = await startServer();
  try {
    const admin = (await call('/auth/demo', { role: 'admin' })).data.token;
    const citizen = (await call('/auth/demo', { role: 'citizen' })).data.token;
    // PTG-2026-0110 is Rejected and 0111 is Duplicate in the seed data.
    for (const target of ['PTG-2026-0110', 'PTG-2026-0111', 'PTG-2026-0101', 'nope']) {
      assert.equal((await call('/reports/PTG-2026-0101/events', { action: 'duplicate', duplicateOf: target }, admin)).status, 400, target);
    }
    assert.equal((await call('/reports/PTG-2026-0101/events', { action: 'duplicate', duplicateOf: 'PTG-2026-0102' }, admin)).status, 200);
    assert.equal((await call('/reports/PTG-2026-0102/events', { action: 'review' }, citizen)).status, 403);
    const teams = (await call('/bootstrap', undefined, citizen)).data.teams;
    assert.ok(teams.length && teams.every((t: any) => t.members.length === 0));
    assert.ok((await call('/bootstrap', undefined, admin)).data.teams.some((t: any) => t.members.length > 0));
  } finally { await close(); }
});
