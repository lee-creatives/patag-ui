// HTTP behaviour against real SQL. The first four cases are ported from dev-mock/*.test.mjs.
import test from 'node:test';
import assert from 'node:assert/strict';
import { PNG, startServer } from './helpers.ts';

const reportInput = (photo: object) => ({
  title: 'Workflow test pothole', description: 'Damaged outer lane', hazards: 'Water collects', severity: 'High', photos: [photo],
  location: { road: 'Test Road', barangay: 'Guinhawa', city: 'Malolos', province: 'Bulacan', landmark: 'Test waiting shed', coordinates: { lat: 14.85, lng: 120.81 } },
});

test('cross-role flow, evidence validation, privacy, ownership, feedback and notifications', async () => {
  const { base, call, close } = await startServer();
  try {
    assert.equal((await call('/bootstrap')).status, 401);
    const citizen = (await call('/auth/demo', { role: 'citizen' })).data.token;
    const admin = (await call('/auth/demo', { role: 'admin' })).data.token;
    const crew = (await call('/auth/demo', { role: 'maintenance' })).data.token;
    assert.equal((await call('/uploads', { data: 'data:image/png;base64,dGhpcyBpcyBub3QgYSBwbmc=', name: 'invalid.png' }, citizen)).status, 400);
    const photo = (await call('/uploads', { name: 'test-evidence.png', data: PNG }, citizen)).data;
    assert.match(photo.url, /^\/uploads\/[a-f0-9-]{36}\.png$/);
    const image = await fetch(base + photo.url);
    assert.equal(image.status, 200);
    assert.equal(image.headers.get('content-type'), 'image/png');

    assert.equal((await call('/reports', { ...reportInput(photo), photos: [] }, citizen)).status, 400);
    assert.equal((await call('/reports', reportInput(photo), admin)).status, 403);
    const created = await call('/reports', reportInput(photo), citizen);
    assert.equal(created.status, 201);
    assert.equal(created.data.status, 'Submitted');
    assert.match(created.data.id, /^PTG-\d{4}-\d{4}$/);
    const id = created.data.id;
    assert.equal((await call('/reports/' + id, undefined, crew)).status, 403);
    assert.equal((await call('/reports/' + id, undefined, citizen)).data.id, id);

    const event = (action: string, payload = {}, token = admin) => call(`/reports/${id}/events`, { action, ...payload }, token);
    assert.equal((await event('assign', { teamId: 'team-1' })).status, 409);
    assert.equal((await event('verify', {}, citizen)).status, 409);
    assert.equal((await event('verify')).data.status, 'Verified');
    await event('assign', { teamId: 'team-1', note: 'Inspect the outer lane' });
    assert.ok((await call('/bootstrap', undefined, crew)).data.reports.some((r: any) => r.id === id));

    const before = await event('before-photos', { photos: [photo] }, crew);
    assert.equal(before.status, 200);
    assert.equal(before.data.photos.length, created.data.photos.length + 1);
    assert.equal(before.data.status, 'Assigned');
    await event('start', {}, crew);
    await event('progress', { note: 'Site prepared' }, crew);
    assert.equal((await event('resolve', {}, crew)).status, 409);
    assert.equal((await event('complete', { note: 'Repaired' }, crew)).status, 400);
    const completion = await event('complete', { note: 'Repaired with compacted base and asphalt patch', photos: [photo] }, crew);
    assert.equal(completion.data.status, 'In Progress');
    assert.equal(completion.data.completion.state, 'Awaiting Verification');
    assert.equal((await event('resolve')).data.status, 'Resolved');

    assert.equal((await call(`/reports/${id}/feedback`, { rating: 5, text: 'Road is smooth again.' }, citizen)).status, 201);
    assert.equal((await call(`/reports/${id}/feedback`, { rating: 5, text: 'repeat' }, citizen)).status, 409);
    const pub = (await call('/public/reports')).data.find((r: any) => r.id === id);
    assert.equal(pub.reporterId, undefined);
    assert.equal(pub.assignment, undefined);
    assert.equal(pub.feedback, undefined);

    const citizenNotes = (await call('/bootstrap', undefined, citizen)).data.notifications;
    assert.ok(citizenNotes.some((n: any) => n.reportId === id));
    assert.equal((await call('/notifications/read', { id: 'all' }, citizen)).status, 200);
    assert.ok((await call('/bootstrap', undefined, citizen)).data.notifications.every((n: any) => n.read));
  } finally { await close(); }
});

test('registration, login, ownership isolation, profile and logout', async () => {
  const { call, close } = await startServer();
  try {
    const input = { name: 'Audit Citizen', email: 'audit@example.test', password: 'Audit-Test-12345', address: { line: '', barangay: 'Guinhawa', city: 'Malolos', province: 'Bulacan' } };
    assert.equal((await call('/auth/register', { ...input, password: 'short' })).status, 400);
    const registered = await call('/auth/register', input);
    assert.equal(registered.status, 201);
    const token = registered.data.token;
    assert.equal(registered.data.user.passwordHash, undefined);
    assert.equal((await call('/auth/register', input)).status, 409);
    assert.equal((await call('/auth/login', { email: input.email, password: 'wrong-password-123' })).status, 401);
    assert.equal((await call('/auth/login', input)).status, 200);
    assert.equal((await call('/reports/PTG-2026-0101', undefined, token)).status, 403);
    assert.equal((await call('/reports/PTG-2026-0101/feedback', { rating: 5, text: 'not mine' }, token)).status, 403);
    assert.equal((await call('/reports/PTG-0000-0000', undefined, token)).status, 404);
    const bootstrap = await call('/bootstrap', undefined, token);
    assert.equal(bootstrap.data.reports.length, 0);
    assert.equal(bootstrap.data.notifications.length, 0);
    assert.equal(bootstrap.data.users.length, 0);
    assert.deepEqual(bootstrap.data.statuses.length, 8);

    const updated = await call('/me', { name: input.name, email: input.email, address: { line: '12 Mabini', barangay: 'Guinhawa', city: 'Malolos', province: 'Bulacan' } }, token, 'PATCH');
    assert.equal(updated.status, 200);
    assert.equal(updated.data.address.line, '12 Mabini');
    assert.equal((await call('/me', { name: input.name, email: input.email, address: { barangay: '', city: 'Malolos', province: 'Bulacan' } }, token, 'PATCH')).status, 400);
    assert.equal((await call('/me', { name: input.name, email: 'other@example.test' }, token, 'PATCH')).status, 400);
    assert.ok(!JSON.stringify((await call('/public/reports')).data).includes('12 Mabini'));
    assert.equal((await call('/users', { id: 'admin-1', active: false }, token, 'PATCH')).status, 403);

    const logout = await call('/auth/logout', {}, token);
    assert.equal(logout.status, 200);
    assert.equal((await call('/bootstrap', undefined, token)).status, 401);
  } finally { await close(); }
});

test('workspace settings, crew provisioning and public photo approval connect across roles', async () => {
  const { call, close } = await startServer();
  try {
    const admin = (await call('/auth/demo', { role: 'admin' })).data.token;
    const citizen = (await call('/auth/demo', { role: 'citizen' })).data.token;
    assert.equal((await call('/settings', { agency: 'Office', city: 'Malolos', province: 'Bulacan' }, citizen, 'PATCH')).status, 403);
    assert.equal((await call('/settings', { agency: 'Office', city: 'Malolos', province: 'Bulacan' }, admin, 'PATCH')).status, 200);
    assert.equal((await call('/bootstrap', undefined, citizen)).data.settings.agency, 'Office');

    const team = (await call('/teams', { name: 'Audit team', active: true }, admin)).data;
    assert.equal((await call('/teams', { name: 'audit TEAM' }, admin)).status, 409);
    assert.equal((await call('/users', { name: 'Crew Test', email: 'crew-test@example.test', password: 'Preview-Test-123', role: 'maintenance' }, admin)).status, 400);
    const account = await call('/users', { name: 'Crew Test', email: 'crew-test@example.test', password: 'Preview-Test-123', role: 'maintenance', teamId: team.id }, admin);
    assert.equal(account.status, 201);
    assert.equal(account.data.passwordHash, undefined);
    assert.ok((await call('/bootstrap', undefined, admin)).data.teams.find((t: any) => t.id === team.id).members.includes('Crew Test'));
    const crew = (await call('/auth/login', { email: 'crew-test@example.test', password: 'Preview-Test-123' })).data.token;
    assert.ok(crew);

    const id = 'PTG-2026-0103';
    assert.equal((await call(`/reports/${id}/events`, { action: 'assign', teamId: team.id }, admin)).status, 200);
    assert.ok((await call('/bootstrap', undefined, crew)).data.reports.some((r: any) => r.id === id));
    assert.equal((await call('/teams', { id: team.id, name: team.name, active: false }, admin, 'PATCH')).status, 409);

    const upload = (await call('/uploads', { data: PNG, name: 'private.png' }, crew)).data;
    await call(`/reports/${id}/events`, { action: 'before-photos', photos: [upload] }, crew);
    const publicPhotos = async () => (await call('/public/reports')).data.find((r: any) => r.id === id).photos;
    assert.ok(!(await publicPhotos()).some((p: any) => p.url === upload.url));
    assert.equal((await call(`/reports/${id}/events`, { action: 'publication', approved: true }, crew)).status, 409);
    assert.equal((await call(`/reports/${id}/events`, { action: 'publication', approved: true }, admin)).status, 200);
    assert.ok((await publicPhotos()).some((p: any) => p.url === upload.url));
    await call(`/reports/${id}/events`, { action: 'publication', approved: false }, admin);
    assert.ok(!(await publicPhotos()).some((p: any) => p.url === upload.url));

    // Disabling an account revokes its sessions.
    assert.equal((await call('/users', { id: account.data.id, active: false }, admin, 'PATCH')).status, 200);
    assert.equal((await call('/bootstrap', undefined, crew)).status, 401);
  } finally { await close(); }
});

test('normalization, portal restriction, demo disabled, forged tokens and throttling', async () => {
  const { call, close } = await startServer({ allowDemo: false });
  try {
    assert.equal((await call('/auth/demo', { role: 'admin' })).status, 404);
    const input = { name: '  Test Reporter  ', email: '  NORMALIZED@example.test ', password: 'Several roads lead home!', address: { line: ' 12 Mabini St ', barangay: ' Guinhawa ', city: ' Malolos ', province: ' Bulacan ' }, role: 'admin', active: false, teamId: 'team-1' };
    assert.equal((await call('/auth/register', { ...input, address: {} })).status, 400);
    const created = await call('/auth/register', input);
    assert.equal(created.status, 201);
    assert.deepEqual(created.data.user.address, { line: '12 Mabini St', barangay: 'Guinhawa', city: 'Malolos', province: 'Bulacan' });
    assert.equal(created.data.user.role, 'citizen');
    assert.equal(created.data.user.email, 'normalized@example.test');
    assert.equal(created.data.user.active, true);
    assert.equal(created.data.user.teamId, undefined);
    assert.equal(created.data.user.emailVerified, false);
    assert.equal((await call('/auth/register', { ...input, email: 'normalized@example.test' })).status, 409);
    assert.equal((await call('/auth/login', { email: 'NORMALIZED@EXAMPLE.TEST', password: input.password, role: 'admin' })).status, 401);
    const login = await call('/auth/login', { email: 'NORMALIZED@EXAMPLE.TEST', password: input.password, role: 'citizen' });
    assert.equal(login.status, 200);
    assert.equal((await call('/bootstrap', null, 'preview:' + created.data.user.id + ':forged')).status, 401);
    // Seeded demo accounts have no password and cannot be logged into.
    assert.equal((await call('/auth/login', { email: 'lgu@example.test', password: 'anything-at-all-123' })).status, 401);
    await call('/auth/logout', {}, login.data.token);
    assert.equal((await call('/bootstrap', null, login.data.token)).status, 401);
    let last;
    for (let i = 0; i < 21; i++) last = await call('/auth/login', { email: 'absent@example.test', password: 'wrong' });
    assert.equal(last!.status, 429);
  } finally { await close(); }
});

test('duplicates, upload checks, JSON errors and CORS', async () => {
  const { base, call, close } = await startServer();
  try {
    const citizen = (await call('/auth/demo', { role: 'citizen' })).data.token;
    // Seed PTG-2026-0102 and 0105 are both on Paseo del Congreso, ~20 m apart.
    const dupes = await call('/duplicates', { location: { road: 'paseo del congreso', coordinates: { lat: 14.8436, lng: 120.8108 } } }, citizen);
    assert.equal(dupes.status, 200);
    assert.deepEqual(dupes.data.map((d: any) => d.report.id).sort(), ['PTG-2026-0102', 'PTG-2026-0105']);
    assert.ok(dupes.data.every((d: any) => Number.isInteger(d.distance) && d.report.reporterId === undefined));
    assert.equal((await call('/duplicates', { location: { road: 'Other Road', coordinates: { lat: 14.8436, lng: 120.8108 } } }, citizen)).data.length, 0);
    assert.equal((await call('/duplicates', { location: { road: 'x', coordinates: { lat: 200, lng: 0 } } }, citizen)).status, 400);

    // Photo URLs must point at real uploads; demo SVGs cannot be resubmitted.
    const fake = { id: 'x', url: '/uploads/11111111-1111-1111-1111-111111111111.png', name: 'x.png', kind: 'before' };
    assert.equal((await call('/reports', { ...reportInput(fake) }, citizen)).status, 400);
    assert.equal((await call('/reports', { ...reportInput({ id: 'd', url: '/demo-evidence.svg' }) }, citizen)).status, 400);
    assert.equal((await call('/uploads', { data: 'data:image/gif;base64,R0lGODlhAQABAAAAACw=' }, citizen)).status, 400);
    assert.equal((await call('/uploads/../../etc/passwd')).status, 404);
    assert.equal((await call('/uploads/11111111-1111-1111-1111-111111111111.png')).status, 404);

    const bad = await fetch(base + '/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{oops' });
    assert.equal(bad.status, 400);
    assert.equal(((await bad.json()) as any).error, 'Invalid JSON.');
    const missing = await call('/nope');
    assert.equal(missing.status, 404);
    assert.equal(missing.data.error, 'Endpoint not found.');

    const allowed = await fetch(base + '/health', { headers: { Origin: 'http://127.0.0.1:5173' } });
    assert.equal(allowed.headers.get('access-control-allow-origin'), 'http://127.0.0.1:5173');
    const blocked = await fetch(base + '/health', { headers: { Origin: 'https://evil.example' } });
    assert.equal(blocked.headers.get('access-control-allow-origin'), null);
    const preflight = await fetch(base + '/reports', { method: 'OPTIONS', headers: { Origin: 'http://127.0.0.1:5173' } });
    assert.equal(preflight.status, 204);

  } finally { await close(); }
});

test('oversized bodies get a JSON 413', async () => {
  const { call, close } = await startServer({ bodyLimit: 4096 });
  try {
    const citizen = (await call('/auth/demo', { role: 'citizen' })).data.token;
    const big = await call('/uploads', { data: 'data:image/png;base64,' + 'A'.repeat(8000) }, citizen);
    assert.equal(big.status, 413);
    assert.equal(big.data.error, 'Photo must be under 8 MB.');
  } finally { await close(); }
});
