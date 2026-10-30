import test from 'node:test';
import assert from 'node:assert/strict';
import { startServer } from './helpers.ts';

test('team membership uses account IDs atomically, preserves omitted links and denies ineligible callers', async () => {
  const { call, store, close } = await startServer();
  try {
    const admin = (await call('/auth/demo', { role: 'admin' })).data.token;
    const crew = (await call('/auth/demo', { role: 'maintenance' })).data.token;
    const citizen = (await call('/auth/demo', { role: 'citizen' })).data.token;
    const users = (await call('/bootstrap', undefined, admin)).data.users;
    const member = users.find((u: any) => u.role === 'maintenance' && u.active);
    const other = await store.insertUser({ name: member.name, email: 'same-name@example.test', role: 'maintenance', active: true, teamId: member.teamId, address: null, emailVerified: false, passwordHash: null });
    const inactive = await store.insertUser({ name: 'Inactive crew', email: 'inactive-members@example.test', role: 'maintenance', active: false, teamId: member.teamId, address: null, emailVerified: false, passwordHash: null });
    for (const token of [undefined, crew, citizen]) {
      assert.equal((await call('/teams', { name: 'Denied', memberIds: [member.id] }, token)).status, token ? 403 : 401);
    }
    for (const ids of [[member.id, member.id], ['unknown'], [users.find((u: any) => u.role === 'citizen').id], [inactive!.id], 'not-an-array', [null]]) {
      assert.equal((await call('/teams', { name: 'Invalid selection', memberIds: ids }, admin)).status, 400);
      assert.equal(await store.teamNameTaken('Invalid selection', null), false);
    }
    const created = await call('/teams', { name: 'Selected crew', memberIds: [member.id, other!.id] }, admin);
    assert.equal(created.status, 201);
    assert.deepEqual(created.data.members, [member.name, member.name]);
    assert.equal((await store.userById(member.id))!.teamId, created.data.id);
    assert.equal((await store.userById(inactive!.id))!.teamId, member.teamId);
    assert.equal((await call('/teams', { id: created.data.id, name: 'Renamed crew' }, admin, 'PATCH')).status, 200);
    assert.equal((await store.userById(other!.id))!.teamId, created.data.id);
    assert.equal((await call('/teams', { id: created.data.id, name: 'Should rollback', memberIds: ['unknown'] }, admin, 'PATCH')).status, 400);
    assert.equal((await store.teamById(created.data.id))!.name, 'Renamed crew');
    assert.equal((await store.userById(member.id))!.teamId, created.data.id);
    assert.equal((await call('/teams', { id: created.data.id, name: 'Renamed crew', memberIds: [other!.id] }, admin, 'PATCH')).status, 200);
    assert.equal((await store.userById(member.id))!.teamId, null);
    assert.equal((await call('/teams', { name: 'Inactive selection', active: false, memberIds: [other!.id] }, admin)).status, 400);
    assert.equal((await store.userById(other!.id))!.teamId, created.data.id);
  } finally { await close(); }
});

test('removed crew has no report or notification access and can be reassigned', async () => {
  const { call, store, close } = await startServer();
  try {
    const admin = (await call('/auth/demo', { role: 'admin' })).data.token;
    const login = (await call('/auth/demo', { role: 'maintenance' })).data;
    const before = (await call('/bootstrap', undefined, login.token)).data;
    const assigned = before.reports[0];
    assert.ok(assigned);
    const unassigned = (await store.listReports({})).find(r => !r.teamId)!;
    assert.ok(unassigned);
    const team = await store.teamById(login.user.teamId);
    assert.equal((await call('/teams', { id: team!.id, name: 'Must rollback', active: false, memberIds: [] }, admin, 'PATCH')).status, 409);
    assert.equal((await store.teamById(team!.id))!.name, team!.name);
    assert.equal((await store.userById(login.user.id))!.teamId, team!.id);
    assert.equal((await call('/teams', { id: team!.id, name: team!.name, memberIds: [] }, admin, 'PATCH')).status, 200);
    const after = (await call('/bootstrap', undefined, login.token)).data;
    assert.deepEqual(after.reports, []);
    assert.deepEqual(after.notifications, []);
    for (const id of [assigned.id, unassigned.id]) {
      assert.equal((await call('/reports/' + id, undefined, login.token)).status, 403);
      assert.equal((await call('/reports/' + id + '/events', { action: 'start' }, login.token)).status, 403);
    }
    assert.equal((await call('/users', { id: login.user.id, name: 'Unassigned member' }, admin, 'PATCH')).status, 200);
    assert.equal((await call('/teams', { id: team!.id, name: team!.name, memberIds: [login.user.id] }, admin, 'PATCH')).status, 200);
    assert.ok((await call('/bootstrap', undefined, login.token)).data.reports.some((r: any) => r.id === assigned.id));
  } finally { await close(); }
});


test('concurrent unrelated account edits cannot undo crew transfer', async () => {
  const { call, store, close } = await startServer();
  try {
    const admin = (await call('/auth/demo', { role: 'admin' })).data.token;
    const member = (await store.listUsers()).find(u => u.role === 'maintenance' && u.active)!;
    const team = (await call('/teams', { name: 'Concurrent target' }, admin)).data;
    const [edit, move] = await Promise.all([
      call('/users', { id: member.id, name: 'Updated concurrently', password: 'Concurrent-Test-123!' }, admin, 'PATCH'),
      call('/teams', { id: team.id, name: team.name, memberIds: [member.id] }, admin, 'PATCH'),
    ]);
    assert.equal(edit.status, 200); assert.equal(move.status, 200);
    assert.equal((await store.userById(member.id))!.teamId, team.id);
    assert.equal((await store.userById(member.id))!.name, 'Updated concurrently');
  } finally { await close(); }
});
