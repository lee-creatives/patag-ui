// Fictional demonstration data, identical to dev-mock/domain.mjs seed() so existing
// walkthroughs and tests (PTG-2026-0101, team-1, admin-1 ...) keep working.
import type { HistoryEntry, Report, Settings, Team, User } from './domain.ts';

const roads: [string, string, number, number][] = [
  ['MacArthur Highway', 'Guinhawa', 14.8587, 120.8166], ['Paseo del Congreso', 'San Agustin', 14.8435, 120.8108],
  ['Santisima Trinidad Road', 'Santisima Trinidad', 14.8671, 120.8235], ['Mabini Street', 'Mojon', 14.8562, 120.8047],
  ['Paseo del Congreso', 'San Agustin', 14.8437, 120.8109], ['Cabanas Road', 'Longos', 14.8402, 120.8217],
  ['Sampaguita Street', 'Bulihan', 14.871, 120.812], ['A. Mabini Street', 'Mojon', 14.859, 120.801],
  ['Fausta Road', 'Mabolo', 14.846, 120.799], ['Camia Street', 'Bulihan', 14.875, 120.816],
  ['Riverside Road', 'Longos', 14.838, 120.825], ['Paseo Street', 'Guinhawa', 14.86, 120.819],
];
const order = ['Submitted', 'Under Review', 'Verified', 'Assigned', 'Submitted', 'In Progress', 'In Progress', 'Resolved', 'Verified', 'Rejected', 'Duplicate', 'In Progress'];
const assigned = ['Assigned', 'In Progress', 'Resolved'];

export const seedSettings: Settings = { agency: 'Malolos demo jurisdiction', city: 'Malolos', province: 'Bulacan' };

export const seedTeams: Omit<Team, 'members'>[] = [
  { id: 'team-1', name: 'Road Crew Alpha', active: true },
  { id: 'team-2', name: 'Road Crew Bravo', active: true },
];

const demoUser = (u: Pick<User, 'id' | 'name' | 'email' | 'role'> & Partial<User>): User =>
  ({ active: true, teamId: null, address: null, emailVerified: false, passwordHash: null, ...u });

// No password hashes: these are reachable only through /auth/demo when ALLOW_DEMO=true.
export const seedUsers: User[] = [
  demoUser({ id: 'citizen-1', name: 'Alex Dela Cruz', email: 'citizen@example.test', role: 'citizen' }),
  demoUser({ id: 'admin-1', name: 'Andrea Reyes', email: 'lgu@example.test', role: 'admin' }),
  demoUser({ id: 'maintenance-1', name: 'Mika Santos', email: 'crew@example.test', role: 'maintenance', teamId: 'team-1' }),
  demoUser({ id: 'maintenance-2', name: 'Paolo Cruz', email: 'crew2@example.test', role: 'maintenance', teamId: 'team-1' }),
  demoUser({ id: 'maintenance-3', name: 'Alma Reyes', email: 'crew3@example.test', role: 'maintenance', teamId: 'team-2' }),
  demoUser({ id: 'maintenance-4', name: 'Rico Garcia', email: 'crew4@example.test', role: 'maintenance', teamId: 'team-2' }),
];

export function seedReports(): Report[] {
  return roads.map(([road, barangay, lat, lng], i) => {
    const status = order[i];
    const history: HistoryEntry[] = [{ id: `h-${i}`, at: `2026-10-${String(9 + i).padStart(2, '0')}T02:30:00.000Z`, actor: 'Citizen demo', action: 'Submitted', from: null, to: 'Submitted', note: 'Photo and location received.' }];
    if (status !== 'Submitted') history.push({ id: `h-${i}-2`, at: `2026-10-${String(10 + i).padStart(2, '0')}T03:30:00.000Z`, actor: 'LGU demo', action: status, from: 'Submitted', to: status, note: 'Fictional demonstration history.' });
    const last = history.at(-1)!.at;
    const isAssigned = assigned.includes(status);
    return {
      id: `PTG-2026-${String(101 + i).padStart(4, '0')}`,
      title: ['Pothole near pedestrian crossing', 'Deep road damage beside intersection', 'Uneven road surface near tricycle stop'][i % 3],
      description: 'Road surface has broken beside the outer lane. Please inspect the damaged section, especially after rain.',
      hazards: i % 2 ? 'Water collects after rain.' : 'Near a pedestrian crossing.',
      severity: ['High', 'Medium', 'Low'][i % 3],
      status,
      location: { road, barangay, city: 'Malolos', province: 'Bulacan', landmark: 'Near the barangay waiting shed', coordinates: { lat, lng } },
      reporterId: 'citizen-1',
      jurisdiction: seedSettings.agency,
      createdAt: history[0].at,
      updatedAt: last,
      photos: [{ id: `p-${i}`, url: '/demo-evidence.svg', kind: 'before', name: 'Illustrated demo evidence', demo: true }],
      teamId: isAssigned ? 'team-1' : null,
      assignment: isAssigned ? { teamId: 'team-1', priority: 'High', note: 'Inspect the outer lane and use temporary traffic controls.', targetDate: '2026-10-26', at: last } : null,
      history,
      updates: [],
      completion: i === 6 || status === 'Resolved'
        ? { state: status === 'Resolved' ? 'Verified' : 'Awaiting Verification', note: 'Damaged material removed, base compacted, surface patched and lane cleared.', photos: [{ id: `after-${i}`, url: '/demo-after.svg', name: 'Illustrated demo repair', kind: 'after', demo: true }], at: '2026-10-21T01:00:00.000Z' }
        : null,
      feedback: null,
      flagged: false,
    };
  });
}
