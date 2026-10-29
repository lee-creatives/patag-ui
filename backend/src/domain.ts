// Workflow rules, privacy projection and validation. Ported from dev-mock/domain.mjs,
// which docs/status-transitions.md and the clients were built against.
import { randomUUID } from 'node:crypto';

export const statuses = ['Submitted', 'Under Review', 'Verified', 'Assigned', 'In Progress', 'Resolved', 'Rejected', 'Duplicate'] as const;
export const severities = ['Low', 'Medium', 'High'] as const;
export const roles = ['citizen', 'admin', 'maintenance'] as const;
export const closedStatuses = ['Resolved', 'Rejected', 'Duplicate'];
export const hiddenFromPublic = ['Rejected', 'Duplicate'];

export type Status = (typeof statuses)[number];
export type Role = (typeof roles)[number];

export interface Coordinates { lat: number; lng: number }
export interface Location { road: string; barangay: string; city: string; province: string; landmark: string; coordinates: Coordinates }
export interface Photo { id: string; url: string; name: string; kind: string; demo?: boolean }
/** actor is the role (contract field); actorId/actorName record which account did it. */
export interface HistoryEntry { id: string; at: string; actor: string; actorId?: string; actorName?: string; action: string; from: string | null; to: string; note: string }
export interface Assignment { teamId: string; note: string; priority: string; targetDate: string | null; at: string }
export interface ProgressUpdate { at: string; note: string; phase: string; photos: Photo[] }
export interface Completion { state: string; note: string; photos: Photo[]; at: string }
export interface Feedback { rating: number; text: string; at: string }
export interface Address { line: string; barangay: string; city: string; province: string }

export interface Report {
  id: string; title: string; description: string; hazards: string; severity: string; status: string;
  location: Location; photos: Photo[]; reporterId: string; jurisdiction: string; createdAt: string; updatedAt: string;
  teamId: string | null; assignment: Assignment | null; history: HistoryEntry[]; updates: ProgressUpdate[];
  completion: Completion | null; feedback: Feedback | null; flagged: boolean;
  duplicateOf?: string; publicPhotosApproved?: boolean;
}

export interface User {
  id: string; name: string; email: string; role: Role; active: boolean;
  teamId: string | null; address: Address | null; emailVerified: boolean; passwordHash: string | null;
}
export interface Team { id: string; name: string; active: boolean; members: string[] }
export interface Settings { agency: string; city: string; province: string }
export interface Notification { id: string; role: Role; userId: string | null; teamId: string | null; reportId: string; title: string; at: string; read: boolean }

export class HttpError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}
export const fail = (status: number, message: string): never => { throw new HttpError(status, message); };

// Real uploaded evidence only; seeded SVG illustrations cannot be resubmitted.
export const UPLOAD_URL = /^\/uploads\/[a-f0-9-]{36}\.(png|jpg|webp)$/;
export const UPLOAD_NAME = /^[a-f0-9-]{36}\.(png|jpg|webp)$/;

export function publicUser(u: User) {
  return {
    id: u.id, name: u.name, email: u.email, role: u.role, active: u.active,
    ...(u.teamId ? { teamId: u.teamId } : {}),
    ...(u.address ? { address: u.address } : {}),
    emailVerified: u.emailVerified,
  };
}

export const distance = (a: Coordinates, b: Coordinates) => {
  const r = Math.PI / 180, dlat = (b.lat - a.lat) * r, dlng = (b.lng - a.lng) * r;
  return 6371000 * 2 * Math.asin(Math.sqrt(Math.sin(dlat / 2) ** 2 + Math.cos(a.lat * r) * Math.cos(b.lat * r) * Math.sin(dlng / 2) ** 2));
};

/** Same road and within 150 m. Suggestions only; never merged automatically. */
export function candidates(reports: Report[], draft: { id?: string; location: { road: string; coordinates: Coordinates } }) {
  const road = draft.location.road.trim().toLowerCase();
  return reports
    .filter(r => r.id !== draft.id && !hiddenFromPublic.includes(r.status))
    .map(r => ({ report: r, distance: Math.round(distance(r.location.coordinates, draft.location.coordinates)) }))
    .filter(x => x.distance <= 150 && x.report.location.road.trim().toLowerCase() === road);
}

interface EventPayload {
  note?: string; approved?: unknown; duplicateOf?: string; jurisdiction?: string; teamId?: string;
  priority?: string; targetDate?: string | null; phase?: string; photos?: Photo[];
}

/** Applies one workflow action in place. Throws 409 for anything the state machine disallows. */
export function transition(report: Report, role: Role, action: string, payload: EventPayload = {}, availableTeams: Pick<Team, 'id' | 'active'>[] = [], by?: { id: string; name: string }) {
  const current = report.status;
  let next = current;
  const deny = (m: string) => fail(409, m);
  const note = payload.note?.trim() ?? '';
  const now = () => new Date().toISOString();
  if (role === 'admin') {
    if (action === 'publication') {
      if (typeof payload.approved !== 'boolean') deny('Choose a photo publication state.');
      report.publicPhotosApproved = payload.approved as boolean;
    } else if (action === 'review' && current === 'Submitted') next = 'Under Review';
    else if (action === 'verify' && ['Submitted', 'Under Review'].includes(current)) next = 'Verified';
    else if (action === 'reject' && ['Submitted', 'Under Review'].includes(current)) {
      if (!note) deny('Give a reason for rejection.');
      next = 'Rejected';
    } else if (action === 'duplicate' && ['Submitted', 'Under Review'].includes(current)) {
      if (!payload.duplicateOf || payload.duplicateOf === report.id) deny('Select an existing original report.');
      next = 'Duplicate';
      report.duplicateOf = payload.duplicateOf;
    } else if (action === 'flag') {
      if (!note) deny('Add follow-up instructions.');
      report.flagged = true;
    } else if (action === 'forward') {
      if (!payload.jurisdiction?.trim()) deny('Enter the responsible agency.');
      report.jurisdiction = payload.jurisdiction!.trim();
    } else if (action === 'assign' && current === 'Verified') {
      if (!availableTeams.some(t => t.id === payload.teamId && t.active)) deny('Choose an active team.');
      next = 'Assigned';
      report.teamId = payload.teamId!;
      report.assignment = { teamId: payload.teamId!, note, priority: payload.priority || report.severity, targetDate: payload.targetDate || null, at: now() };
    } else if (action === 'resolve' && current === 'In Progress' && report.completion?.state === 'Awaiting Verification') {
      next = 'Resolved';
      report.completion.state = 'Verified';
    } else if (action === 'return' && report.completion?.state === 'Awaiting Verification') {
      if (!note) deny('Explain the additional work.');
      next = 'In Progress';
      report.completion.state = 'Additional Work Requested';
    } else deny('This action is not allowed from the current report status.');
  } else if (role === 'maintenance') {
    if (action === 'before-photos' && ['Assigned', 'In Progress'].includes(current) && report.completion?.state !== 'Awaiting Verification') {
      if (!payload.photos?.length) deny('Upload before-repair photos.');
      report.publicPhotosApproved = false;
      report.photos.push(...payload.photos!.map(p => ({ ...p, kind: 'before' })));
    } else if (action === 'start' && current === 'Assigned') next = 'In Progress';
    else if (action === 'progress' && current === 'In Progress') {
      if (!note) deny('Add a progress note.');
      report.updates.push({ at: now(), note, phase: payload.phase || 'Repair', photos: payload.photos || [] });
    } else if (action === 'complete' && current === 'In Progress' && report.completion?.state !== 'Awaiting Verification') {
      if (!note || !payload.photos?.length) deny('Repair notes and after photos are required.');
      report.publicPhotosApproved = false;
      report.completion = { state: 'Awaiting Verification', note, photos: payload.photos!.map(p => ({ ...p, kind: 'after' })), at: now() };
    } else deny('Maintenance can start work, update progress or submit evidence; LGU verification is required for resolution.');
  } else deny('Only operational roles can change report status.');
  report.status = next;
  report.updatedAt = now();
  const entryNote = action === 'publication'
    ? (payload.approved ? 'Evidence photos approved for the public map.' : 'Evidence photos withdrawn from the public map.') + (note ? ` ${note}` : '')
    : note;
  report.history.push({
    id: randomUUID(), at: report.updatedAt, actor: role, ...(by ? { actorId: by.id, actorName: by.name } : {}),
    action, from: current, to: next, note: entryNote,
  });
  return report;
}

// Public maps expose road progress, not account, assignment or private note data.
export function publicReport(r: Report) {
  const visible = (p: Photo) => p.demo || r.publicPhotosApproved === true;
  const photo = (p: Photo) => ({ id: p.id, url: p.url, kind: p.kind, name: 'Road evidence', ...(p.demo ? { demo: true } : {}) });
  return {
    id: r.id,
    title: `Pothole on ${r.location.road}`,
    description: `Reported road damage. Current status: ${r.status}.`,
    severity: r.severity,
    status: r.status,
    location: { road: r.location.road, barangay: r.location.barangay, city: r.location.city, province: r.location.province, coordinates: r.location.coordinates },
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    photos: r.photos.filter(visible).map(photo),
    history: r.history
      .filter(h => h.from !== h.to || h.action === 'complete')
      .map(h => ({ id: h.id, at: h.at, action: h.action, from: h.from, to: h.to, note: h.action === 'complete' ? 'Repair submitted for LGU verification.' : `Status updated to ${h.to}.` })),
    completion: r.completion
      ? { state: r.completion.state, at: r.completion.at, photos: r.completion.photos.filter(visible).map(photo), note: 'Repair evidence submitted for administrative review.' }
      : null,
  };
}

const str = (v: unknown) => (typeof v === 'string' ? v.trim() : '');
export const EMAIL = /^\S+@\S+\.\S+$/;

export function addressFields(raw: unknown, required = true): Address {
  const r = (raw && typeof raw === 'object' ? raw : {}) as Record<string, unknown>;
  const address = { line: str(r.line), barangay: str(r.barangay), city: str(r.city), province: str(r.province) };
  if (required && (!address.barangay || !address.city || !address.province)) fail(400, 'Enter your barangay, city or municipality, and province.');
  if (Object.values(address).some(v => v.length > 120)) fail(400, 'Keep each address field within 120 characters.');
  return address;
}

export function registrationFields(body: Record<string, unknown>, { addressRequired = false } = {}) {
  const name = str(body.name);
  const email = str(body.email).toLowerCase();
  const password = body.password;
  if (!name || name.length > 100) fail(400, 'Enter your name (up to 100 characters).');
  if (email.length > 254 || !EMAIL.test(email)) fail(400, 'Enter a valid email address.');
  if (typeof password !== 'string' || [...password].length < 15 || [...password].length > 128) fail(400, 'Use a password of 15 to 128 characters. A few unrelated words work well.');
  const pw = password as string;
  if (/^(.)\1+$/.test(pw) || ['passwordpassword', '123456789012345', 'qwertyuiopasdfgh'].includes(pw.toLowerCase())) fail(400, 'Choose a less predictable password.');
  const address = addressFields(body.address, addressRequired);
  return { name, email, password: pw, address };
}

export const validCoordinates = (c: unknown): c is Coordinates => {
  const v = c as Coordinates | undefined;
  return !!v && typeof v.lat === 'number' && typeof v.lng === 'number' && Number.isFinite(v.lat) && Number.isFinite(v.lng) && Math.abs(v.lat) <= 90 && Math.abs(v.lng) <= 180;
};
