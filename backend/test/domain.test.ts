// Ported from dev-mock/server.test.mjs and dev-mock/project2.test.mjs (pure domain cases).
import test from 'node:test';
import assert from 'node:assert/strict';
import { candidates, publicReport, transition } from '../src/domain.ts';
import { seedReports, seedTeams } from '../src/seed-data.ts';

const teams = seedTeams.map(t => ({ ...t, members: [] }));
const photo = { id: 'test', url: '/uploads/00000000-0000-0000-0000-000000000000.png', name: 'after.png', kind: 'after' };

test('role transitions and duplicate suggestions preserve workflow', () => {
  const reports = seedReports(), r = reports[0];
  assert.ok(candidates(reports, reports[4]).length);
  assert.throws(() => transition(r, 'maintenance', 'resolve'), /LGU verification/);
  assert.throws(() => transition(r, 'admin', 'assign', { teamId: 'team-1' }, teams), /not allowed/);
  transition(r, 'admin', 'review'); transition(r, 'admin', 'verify'); transition(r, 'admin', 'assign', { teamId: 'team-1' }, teams);
  assert.equal(r.status, 'Assigned');
  transition(r, 'maintenance', 'start');
  assert.throws(() => transition(r, 'maintenance', 'complete', { note: 'done' }), /after photos/);
  transition(r, 'maintenance', 'complete', { note: 'Surface repaired', photos: [photo] });
  assert.equal(r.status, 'In Progress');
  assert.throws(() => transition(r, 'maintenance', 'complete', { note: 'again', photos: [photo] }), /LGU verification/);
  transition(r, 'admin', 'return', { note: 'Please inspect the edge' });
  assert.equal(r.completion!.state, 'Additional Work Requested');
  transition(r, 'maintenance', 'complete', { note: 'Edge repaired', photos: [photo] });
  transition(r, 'admin', 'resolve');
  assert.equal(r.status, 'Resolved');
  assert.equal(r.history.at(-1)!.action, 'resolve');
});

test('invalid transitions, forwarding and duplicate confirmation stay explicit', () => {
  const reports = seedReports(), r = reports[0];
  assert.throws(() => transition(r, 'citizen', 'verify'));
  assert.throws(() => transition(r, 'admin', 'resolve'));
  assert.throws(() => transition(r, 'admin', 'reject', { note: '' }));
  assert.throws(() => transition(r, 'admin', 'assign', { teamId: 'missing' }, teams));
  transition(r, 'admin', 'forward', { jurisdiction: 'Provincial road office', note: 'Jurisdiction check' });
  assert.equal(r.jurisdiction, 'Provincial road office'); assert.equal(r.status, 'Submitted');
  transition(r, 'admin', 'flag', { note: 'Inspect evidence' }); assert.equal(r.flagged, true);
  assert.throws(() => transition(r, 'admin', 'duplicate', { duplicateOf: r.id }));
  transition(r, 'admin', 'duplicate', { duplicateOf: reports[1].id }); assert.equal(r.status, 'Duplicate');
  assert.equal(candidates(reports, { ...reports[1], id: 'new', location: { ...reports[1].location, coordinates: { lat: 0, lng: 0 } } }).length, 0);
});

test('public projection omits private notes and private fields', () => {
  const r: any = seedReports().find(r => r.completion)!;
  r.description = 'Private contact 09123456789'; r.title = 'Reporter name'; r.feedback = { text: 'Call me privately' }; r.internalSecret = 'hidden';
  r.updates = [{ note: 'Staff contact' }];
  r.history.push({ id: 'private', at: r.updatedAt, action: 'flag', from: r.status, to: r.status, note: 'Private contact', actor: 'Staff name' });
  r.completion.note = 'Private repair contact'; r.location.landmark = 'Reporter house'; r.photos[0].name = 'reporter-name.png';
  const p: any = publicReport(r), text = JSON.stringify(p);
  for (const key of ['reporterId', 'assignment', 'teamId', 'feedback', 'updates', 'internalSecret', 'flagged', 'jurisdiction']) assert.equal(p[key], undefined, key);
  for (const value of ['09123456789', 'Staff name', 'Private repair contact', 'Reporter house', 'reporter-name.png']) assert.ok(!text.includes(value), value);
  assert.ok(p.photos.length); assert.equal(p.status, r.status); assert.ok(p.history.every((h: object) => !('actor' in h))); assert.ok(p.completion.photos.length);
});
