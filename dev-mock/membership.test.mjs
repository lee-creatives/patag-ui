import test from 'node:test';
import assert from 'node:assert/strict';
import * as preview from '../browser-preview/domain.mjs';
import * as mock from './domain.mjs';
import { createServer } from './server.mjs';

function fixture(domain) {
  const db = domain.workspace(domain.seed());
  const admin = db.users.find(u => u.role === 'admin');
  const member = db.users.find(u => u.role === 'maintenance');
  const second = { ...member, id: 'second-member', email: 'second@example.test' };
  const inactive = { ...member, id: 'inactive-member', active: false };
  db.users.push(second, inactive);
  return { db, admin, member, second, inactive };
}
for (const [name, domain] of [['preview', preview], ['mock', mock]]) {
  test(name + ': crew create/edit uses IDs, preserves omitted/inactive links and supports unassigned profile edits', () => {
    const { db, admin, member, second, inactive } = fixture(domain);
    const oldTeam = member.teamId;
    const created = domain.manageWorkspace(db, admin, '/teams', { name: 'Selected crew', memberIds: [member.id, second.id] }, 'POST');
    assert.equal(member.teamId, created.id);
    assert.deepEqual(created.members, [member.name, second.name]);
    assert.equal(inactive.teamId, oldTeam);
    domain.manageWorkspace(db, admin, '/teams', { id: created.id, name: 'Renamed' }, 'PATCH');
    assert.equal(member.teamId, created.id);
    domain.manageWorkspace(db, admin, '/teams', { id: created.id, name: 'Renamed', memberIds: [second.id] }, 'PATCH');
    assert.equal(member.teamId, null); assert.equal(second.teamId, created.id);
    assert.deepEqual(created.members, [second.name]);
    domain.manageWorkspace(db, admin, '/users', { id: member.id, name: 'Unassigned edit' }, 'PATCH');
    assert.equal(member.teamId, null);
    domain.manageWorkspace(db, admin, '/teams', { id: created.id, name: 'Renamed', memberIds: [] }, 'PATCH');
    assert.equal(second.teamId, null); assert.deepEqual(created.members, []);
    domain.manageWorkspace(db, admin, '/teams', { id: oldTeam, name: 'Old crew', memberIds: [] }, 'PATCH');
    assert.equal(inactive.teamId, oldTeam);
  });
  test(name + ': invalid crew edits and non-admin callers never partially mutate the store', () => {
    for (const ids of [['maintenance-1', 'maintenance-1'], ['missing'], ['citizen-1'], ['inactive-member'], [null], 'invalid']) {
      const { db, admin } = fixture(domain); const before = structuredClone(db);
      assert.throws(() => domain.manageWorkspace(db, admin, '/teams', { id: 'team-1', name: 'Must not change', memberIds: ids }, 'PATCH'), e => e.status === 400);
      assert.deepEqual(db, before);
    }
    for (const role of ['citizen', 'maintenance']) {
      const { db } = fixture(domain); const before = structuredClone(db);
      assert.throws(() => domain.manageWorkspace(db, { role }, '/teams', { name: 'Denied', memberIds: [] }, 'POST'), e => e.status === 403);
      assert.deepEqual(db, before);
    }
    for (const body of [{ id: 'team-1', name: 'Rollback', active: false, memberIds: [] }, { name: 'Inactive target', active: false, memberIds: ['maintenance-1'] }]) {
      const { db, admin } = fixture(domain); const before = structuredClone(db);
      assert.throws(() => domain.manageWorkspace(db, admin, '/teams', body, body.id ? 'PATCH' : 'POST'), e => e.status === (body.id ? 409 : 400));
      assert.deepEqual(db, before);
    }
  });
}

test('mock: removed crew sessions cannot access old or unassigned reports or events', async () => {
  const server = await createServer({ persist: false });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${server.address().port}/api`;
  async function call(path, body, token, method) {
    const res = await fetch(base + path, { method: method || (body ? 'POST' : 'GET'), headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: 'Bearer ' + token } : {}) }, body: body ? JSON.stringify(body) : undefined });
    return { status: res.status, data: await res.json() };
  }
  try {
    const admin = (await call('/auth/demo', { role: 'admin' })).data.token;
    const crew = (await call('/auth/demo', { role: 'maintenance' })).data.token;
    const before = (await call('/bootstrap', undefined, crew)).data;
    const all = (await call('/bootstrap', undefined, admin)).data;
    const team = all.teams.find(t => t.id === before.user.teamId);
    const unassigned = all.reports.find(r => !r.teamId);
    assert.equal((await call('/teams', { id: team.id, name: team.name, memberIds: [] }, admin, 'PATCH')).status, 200);
    const after = (await call('/bootstrap', undefined, crew)).data;
    assert.deepEqual(after.reports, []); assert.deepEqual(after.notifications, []);
    for (const id of [before.reports[0].id, unassigned.id]) {
      assert.equal((await call('/reports/' + id, undefined, crew)).status, 403);
      assert.equal((await call('/reports/' + id + '/events', { action: 'start' }, crew)).status, 403);
    }
  } finally { await new Promise(resolve => server.close(resolve)); }
});
