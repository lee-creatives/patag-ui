// HTTP API implementing docs/api-contract.md. Every response, including errors, is JSON
// except image bytes; errors are always { "error": "..." }.
import Fastify, { type FastifyReply, type FastifyRequest } from 'fastify';
import { randomUUID } from 'node:crypto';
import { z } from 'zod';
import type { BlobStore } from './blobs.ts';
import { demoSvg } from './demo-svg.ts';
import {
  EMAIL, HttpError, UPLOAD_NAME, UPLOAD_URL, addressFields, candidates, fail, publicReport, publicUser,
  hiddenFromPublic, registrationFields, roles, statuses, transition, validCoordinates, validatePassword,
  type Photo, type Report, type Role, type User,
} from './domain.ts';
import { hashPassword, newToken, sha256, verifyPassword } from './passwords.ts';
import type { ReverseGeocode } from './geocode.ts';
import type { Store } from './store.ts';

export interface AppOptions {
  store: Store;
  blobs: BlobStore;
  allowDemo?: boolean;
  corsOrigins?: string[];
  logger?: boolean;
  bodyLimit?: number;
  /** Fastify trustProxy: false locally; hop count or proxy IPs behind a hosting load balancer. */
  trustProxy?: boolean | number | string[];
  /** Reverse geocoder for the report form's map pin; when absent the endpoint returns empty fields. */
  geocode?: ReverseGeocode;
}

const SESSION_MS = 8 * 60 * 60 * 1000;
const MAX_PHOTO = 8 * 1024 * 1024;
const BODY_LIMIT = 12 * 1024 * 1024; // base64 of an 8 MB photo plus JSON overhead

const photoRef = z.object({
  id: z.string().min(1).max(100),
  url: z.string().regex(UPLOAD_URL),
  name: z.string().max(200).optional(),
  kind: z.string().max(20).optional(),
});
const text = (max: number) => z.string().trim().min(1).max(max);
const reportInput = z.object({
  title: z.string().trim().max(120).optional(),
  description: text(2000),
  hazards: z.string().trim().max(500).optional(),
  severity: z.enum(['Low', 'Medium', 'High']),
  photos: z.array(photoRef).min(1).max(10),
  location: z.object({
    road: text(120), barangay: text(120), city: text(120), province: text(120),
    landmark: z.string().trim().max(200).optional(),
    coordinates: z.object({ lat: z.number().min(-90).max(90), lng: z.number().min(-180).max(180) }),
  }),
});
/** Forms send null or "" for fields a dialog doesn't have: treat them as not provided. */
const blankToUndefined = (v: unknown) => (v === null || (typeof v === 'string' && v.trim() === '') ? undefined : v);
const isoDate = z.string().regex(/^\d{4}-\d{2}-\d{2}$/).refine(v => {
  const d = new Date(v + 'T00:00:00Z');
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === v;
}, 'Invalid date');
const eventInput = z.object({
  action: z.string().min(1).max(40),
  note: z.preprocess(v => (v === null ? undefined : v), z.string().max(2000).optional()),
  approved: z.unknown().optional(),
  duplicateOf: z.preprocess(blankToUndefined, z.string().max(40).optional()),
  jurisdiction: z.preprocess(blankToUndefined, z.string().max(200).optional()),
  teamId: z.preprocess(blankToUndefined, z.string().max(100).optional()),
  priority: z.preprocess(blankToUndefined, z.enum(['Low', 'Medium', 'High']).optional()),
  targetDate: z.preprocess(blankToUndefined, isoDate.optional()),
  phase: z.preprocess(blankToUndefined, z.string().max(60).optional()),
  photos: z.array(photoRef).max(10).optional(),
});

const sanitizePhoto = (p: z.infer<typeof photoRef>, kind: string): Photo =>
  ({ id: p.id, url: p.url, name: (p.name || 'Road evidence').slice(0, 200), kind });

const uploadName = (url: string) => url.slice('/uploads/'.length);

function eventTitle(r: Report, action: string, teams: { id: string; name: string }[]) {
  switch (action) {
    case 'assign': return `${r.id} assigned to ${teams.find(t => t.id === r.teamId)?.name ?? 'a road crew'}`;
    case 'start': return `${r.id}: repair started`;
    case 'progress': return `${r.id}: repair progress updated`;
    case 'before-photos': return `${r.id}: before-repair photos added`;
    case 'complete': return `${r.id}: repair ready for LGU verification`;
    case 'return': return `${r.id}: more work requested`;
    case 'resolve': return `${r.id}: repair verified and resolved`;
    default: return `${r.id}: ${r.status}`;
  }
}

/** Exact origins, plus "http://localhost:*" / "http://127.0.0.1:*" for any local port (Flutter web dev). */
export function originAllowed(origin: string, allowed: string[]) {
  if (allowed.includes(origin)) return true;
  const m = /^(http:\/\/(?:localhost|127\.0\.0\.1)):\d{1,5}$/.exec(origin);
  return !!m && allowed.includes(`${m[1]}:*`);
}

export function buildApp({ store, blobs, allowDemo = false, corsOrigins = [], logger = false, bodyLimit = BODY_LIMIT, trustProxy = false, geocode }: AppOptions) {
  // A hop count becomes Fastify's trust function: trust only the nearest N proxies.
  const trust = typeof trustProxy === 'number' ? (_address: string, hop: number) => hop < trustProxy : trustProxy;
  const app = Fastify({ logger, bodyLimit, trustProxy: trust });

  // Accept an empty JSON body as {} (Flutter sends Content-Type on every request).
  app.removeContentTypeParser('application/json');
  app.addContentTypeParser('application/json', { parseAs: 'string' }, (_req, body, done) => {
    try { done(null, body ? JSON.parse(body as string) : {}); } catch { done(new HttpError(400, 'Invalid JSON.'), undefined); }
  });

  app.addHook('onRequest', async (req, reply) => {
    const origin = req.headers.origin;
    if (origin && originAllowed(origin, corsOrigins)) {
      reply.header('Access-Control-Allow-Origin', origin);
      reply.header('Access-Control-Allow-Headers', 'Content-Type,Authorization');
      reply.header('Access-Control-Allow-Methods', 'GET,POST,PATCH,DELETE,OPTIONS');
      reply.header('Access-Control-Max-Age', '600');
    }
    reply.header('Vary', 'Origin');
    reply.header('X-Content-Type-Options', 'nosniff');
    if (req.method === 'OPTIONS') return reply.code(204).send();
  });

  app.setErrorHandler((err: any, req, reply) => {
    if (err instanceof HttpError) return reply.code(err.status).send({ error: err.message });
    if (err.code === 'FST_ERR_CTP_BODY_TOO_LARGE') return reply.code(413).send({ error: 'Photo must be under 8 MB.' });
    if (err.code === 'FST_ERR_CTP_INVALID_MEDIA_TYPE') return reply.code(415).send({ error: 'Send JSON with Content-Type: application/json.' });
    if (err.statusCode && err.statusCode < 500) return reply.code(err.statusCode).send({ error: 'Invalid request.' });
    req.log.error(err);
    return reply.code(500).send({ error: 'PATAG could not complete this request. Please try again.' });
  });
  app.setNotFoundHandler((_req, reply) => reply.code(404).send({ error: 'Endpoint not found.' }));

  // ---- helpers
  const body = (req: FastifyRequest) => (req.body && typeof req.body === 'object' && !Array.isArray(req.body) ? req.body : {}) as Record<string, any>;
  const bearer = (req: FastifyRequest) => (req.headers.authorization || '').replace(/^Bearer\s+/i, '').trim();
  async function currentUser(req: FastifyRequest) {
    const token = bearer(req);
    const user = token ? await store.sessionUser(sha256(token)) : null;
    if (!user) fail(401, 'Session expired. Sign in again.');
    return user!;
  }
  async function issue(user: User) {
    const token = newToken();
    await store.createSession(sha256(token), user.id, new Date(Date.now() + SESSION_MS));
    return { token, user: publicUser(user) };
  }
  const attempts = new Map<string, { count: number; until: number }>();
  function throttle(req: FastifyRequest) {
    const key = `${req.ip}:${req.routeOptions.url ?? req.url.split('?')[0]}`, now = Date.now();
    if (attempts.size >= 10_000) {
      for (const [k, v] of attempts) if (v.until < now) attempts.delete(k);
      // Still full of live entries: drop the oldest instead of growing without bound.
      while (attempts.size >= 10_000) attempts.delete(attempts.keys().next().value!);
    }
    let a = attempts.get(key);
    if (!a || a.until < now) { a = { count: 0, until: now + 60_000 }; attempts.set(key, a); }
    if (++a.count > 20) fail(429, 'Too many attempts. Wait a minute and try again.');
  }
  /**
   * Citizen: when their report's status changes. Team: assignment, returned work, resolution.
   * Admins: new reports and crew progress. Internal admin actions (flag, forward, publication) notify nobody.
   */
  async function notify(s: Store, r: Report, title: string, action: string, by: Role) {
    const last = r.history.at(-1);
    const statusChanged = action === 'Submitted' || (!!last && last.from !== last.to);
    const toCitizen = by !== 'citizen' && statusChanged || action === 'Submitted';
    const toTeam = !!r.teamId && by !== 'maintenance' && ['assign', 'return', 'resolve'].includes(action);
    const toAdmin = action === 'Submitted' || (by === 'maintenance' && ['start', 'complete'].includes(action));
    await s.addNotifications([
      ...(toCitizen ? [{ role: 'citizen' as const, userId: r.reporterId, teamId: null, reportId: r.id, title }] : []),
      ...(toAdmin ? [{ role: 'admin' as const, userId: null, teamId: null, reportId: r.id, title }] : []),
      ...(toTeam ? [{ role: 'maintenance' as const, userId: null, teamId: r.teamId, reportId: r.id, title }] : []),
    ]);
  }
  /** Photos must be real uploads by this user, unless they are already part of this report's evidence. */
  async function requireUploads(s: Store, photos: { url: string }[], user: User, report?: Report) {
    const already = new Set(report ? [
      ...report.photos, ...report.updates.flatMap(u => u.photos), ...(report.completion?.photos ?? []),
    ].map(p => p.url) : []);
    const fresh = photos.map(p => p.url).filter(u => !already.has(u)).map(uploadName);
    if (!(await s.uploadsOwnedBy(fresh, user.id))) fail(400, 'Upload the photo first, then attach it.');
  }
  function canSee(user: User, r: Report) {
    return user.role === 'admin' || (user.role === 'citizen' ? r.reporterId === user.id : !!user.teamId && r.teamId === user.teamId);
  }

  // ---- public
  app.register(async api => {
    api.get('/health', async () => ({ ok: true, mode: 'supabase' }));

    api.get('/demo-evidence.svg', async (_q, reply) => reply.type('image/svg+xml').send(demoSvg(false)));
    api.get('/demo-after.svg', async (_q, reply) => reply.type('image/svg+xml').send(demoSvg(true)));

    // Evidence URLs are unguessable UUIDs and served without auth so Image.network / <img> work.
    api.get('/uploads/:file', async (req: FastifyRequest<{ Params: { file: string } }>, reply: FastifyReply) => {
      const name = req.params.file;
      if (!UPLOAD_NAME.test(name)) fail(404, 'Photo not found.');
      const blob = await blobs.get(name);
      if (!blob) fail(404, 'Photo not found.');
      const ext = name.split('.').pop();
      return reply
        .type(ext === 'jpg' ? 'image/jpeg' : `image/${ext}`)
        .header('Cache-Control', 'private, max-age=86400, immutable')
        .header('Content-Security-Policy', "default-src 'none'")
        .send(blob!.bytes);
    });

    api.get('/public/reports', async () => (await store.listPublicReports()).map(publicReport));

    // ---- auth
    if (allowDemo) {
      api.get('/auth/demo/accounts', async () => (await store.listDemoUsers()).map(publicUser));
      api.post('/auth/demo', async req => {
        const b = body(req);
        const user = await store.demoUser(String(b.role || ''), typeof b.userId === 'string' ? b.userId : undefined);
        if (!user) fail(403, 'Demo role unavailable.');
        return issue(user!);
      });
    }

    api.post('/auth/register', async (req, reply) => {
      throttle(req);
      const f = registrationFields(body(req), { addressRequired: true });
      // role/team/active in the body are ignored: registration always creates an active citizen.
      const user = await store.insertUser({
        name: f.name, email: f.email, role: 'citizen', active: true, teamId: null, address: f.address,
        emailVerified: false, passwordHash: await hashPassword(f.password),
      });
      if (!user) fail(409, 'Unable to create an account with these details. Try signing in or recovering access.');
      return reply.code(201).send(await issue(user!));
    });

    api.post('/auth/login', async req => {
      throttle(req);
      const b = body(req);
      const email = typeof b.email === 'string' ? b.email.trim().toLowerCase() : '';
      const password = typeof b.password === 'string' && b.password.length <= 256 ? b.password : '';
      const user = email ? await store.userByEmail(email) : null;
      const valid = await verifyPassword(password, user?.passwordHash ?? null);
      if (!valid || !user!.active || (b.role && user!.role !== b.role)) fail(401, 'Email or password is incorrect for this portal.');
      return issue(user!);
    });

    api.post('/auth/recovery', async req => {
      const email = body(req).email;
      if (typeof email !== 'string' || !EMAIL.test(email.trim())) fail(400, 'Enter a valid email.');
      // Same answer whether or not the account exists. No email transport is configured yet.
      return { message: 'If an account exists for that email, recovery instructions will be sent. Email delivery is not configured in this build.' };
    });

    // ---- authenticated
    api.post('/auth/logout', async req => {
      await currentUser(req);
      await store.deleteSession(sha256(bearer(req)));
      return { ok: true };
    });

    api.get('/bootstrap', async req => {
      const user = await currentUser(req);
      const reports = user.role === 'admin' ? await store.listReports({})
        : user.role === 'citizen' ? await store.listReports({ reporterId: user.id })
        : await store.listReports({ teamId: user.teamId });
      const [teams, settings, notifications, users] = await Promise.all([
        store.listTeams(), store.getSettings(), store.notificationsFor(user),
        user.role === 'admin' ? store.listUsers() : Promise.resolve([]),
      ]);
      const visibleTeams = user.role === 'citizen' ? teams.map(t => ({ ...t, members: [] })) : teams;
      return { reports, teams: visibleTeams, settings, demo: allowDemo, users: users.map(publicUser), notifications, user: publicUser(user), statuses };
    });

    api.patch('/me', async req => {
      const user = await currentUser(req);
      const b = body(req);
      const name = typeof b.name === 'string' ? b.name.trim() : '';
      if (!name || name.length > 100 || typeof b.email !== 'string' || !EMAIL.test(b.email.trim())) fail(400, 'Name and valid email are required.');
      if (b.email.trim().toLowerCase() !== user.email.toLowerCase()) fail(400, 'Email changes require verified account recovery.');
      const address = b.address && user.role === 'citizen' ? addressFields(b.address) : undefined;
      const updated = await store.updateProfile(user.id, name, address);
      if (!updated) fail(401, 'Session expired. Sign in again.');
      return publicUser(updated!);
    });

    api.post('/notifications/read', async req => {
      const user = await currentUser(req);
      const id = body(req).id;
      if (typeof id !== 'string' || !id) fail(400, 'Choose a notification.');
      await store.markNotificationsRead(user, id);
      return { ok: true };
    });

    api.post('/uploads', async (req, reply) => {
      const user = await currentUser(req);
      const b = body(req);
      const m = /^data:image\/(png|jpeg|webp);base64,([A-Za-z0-9+/=]+)$/.exec(typeof b.data === 'string' ? b.data : '');
      if (!m) fail(400, 'Choose a PNG, JPEG or WebP image.');
      const type = m![1];
      const bytes = Buffer.from(m![2], 'base64');
      if (bytes.length > MAX_PHOTO || bytes.length < 8) fail(400, 'Invalid image or file exceeds 8 MB.');
      const magic = type === 'png' ? bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))
        : type === 'jpeg' ? bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff
        : bytes.toString('ascii', 0, 4) === 'RIFF' && bytes.toString('ascii', 8, 12) === 'WEBP';
      if (!magic) fail(400, 'Image content does not match its type.');
      const contentType = `image/${type}`;
      const name = `${randomUUID()}.${type === 'jpeg' ? 'jpg' : type}`;
      await blobs.put(name, bytes, contentType);
      await store.recordUpload(name, user.id, contentType, bytes.length);
      const display = typeof b.name === 'string' && b.name.trim() ? b.name.trim().slice(0, 200) : name;
      return reply.code(201).send({ id: randomUUID(), url: `/uploads/${name}`, name: display, kind: b.kind === 'after' ? 'after' : 'before' });
    });

    // Address suggestion for a map pin. A convenience only: failures return empty fields, never an error.
    const geoUse = new Map<string, { count: number; until: number }>();
    api.get('/geocode/reverse', async (req: FastifyRequest<{ Querystring: Record<string, string | undefined> }>) => {
      const user = await currentUser(req);
      const lat = Number(req.query.lat), lng = Number(req.query.lng);
      if (!validCoordinates({ lat, lng }) || req.query.lat === undefined || req.query.lng === undefined) fail(400, 'Valid coordinates are required.');
      const lang = req.query.lang === 'fil' ? 'fil' : 'en';
      const now = Date.now();
      let u = geoUse.get(user.id);
      if (!u || u.until < now) { u = { count: 0, until: now + 60_000 }; geoUse.set(user.id, u); }
      if (++u.count > 30) fail(429, 'Too many address lookups. Wait a minute and try again.');
      if (geoUse.size > 10_000) for (const [k, v] of geoUse) if (v.until < now) geoUse.delete(k);
      const empty = { road: '', barangay: '', city: '', province: '', source: 'none' as const };
      return geocode ? geocode(lat, lng, lang) : empty;
    });

    api.post('/duplicates', async req => {
      await currentUser(req);
      const b = body(req);
      if (!validCoordinates(b.location?.coordinates)) fail(400, 'Valid coordinates are required.');
      const road = typeof b.location.road === 'string' ? b.location.road : '';
      if (!road.trim()) return [];
      const draft = { id: typeof b.id === 'string' ? b.id : undefined, location: { road, coordinates: b.location.coordinates } };
      return candidates(await store.reportsOnRoad(road), draft).map(x => ({ ...x, report: publicReport(x.report) }));
    });

    api.post('/reports', async (req, reply) => {
      const user = await currentUser(req);
      if (user.role !== 'citizen') fail(403, 'Only citizen accounts can submit reports.');
      const parsed = reportInput.safeParse(body(req));
      if (!parsed.success) fail(400, 'Evidence photo, description, road, barangay, city, province, valid coordinates and severity are required.');
      const input = parsed.data!;
      await requireUploads(store, input.photos, user);
      const [id, settings] = [await store.nextReportId(), await store.getSettings()];
      const at = new Date().toISOString();
      const report: Report = {
        id, title: input.title || 'Pothole report', description: input.description, hazards: input.hazards ?? '',
        severity: input.severity, status: 'Submitted',
        location: { ...input.location, landmark: input.location.landmark ?? '' },
        photos: input.photos.map(p => sanitizePhoto(p, 'before')), reporterId: user.id, jurisdiction: settings.agency,
        createdAt: at, updatedAt: at, teamId: null, assignment: null,
        history: [{ id: randomUUID(), at, actor: 'citizen', actorId: user.id, actorName: user.name, action: 'Submitted', from: null, to: 'Submitted', note: 'Citizen report received; administrative review required.' }],
        updates: [], completion: null, feedback: null, flagged: false,
      };
      await store.tx(async tx => {
        await tx.insertReport(report);
        await notify(tx, report, 'Report submitted for review', 'Submitted', 'citizen');
      });
      return reply.code(201).send(report);
    });

    api.get('/reports/:id', async (req: FastifyRequest<{ Params: { id: string } }>) => {
      const user = await currentUser(req);
      const r = await store.getReport(req.params.id);
      if (!r) fail(404, 'Report not found.');
      if (!canSee(user, r!)) fail(403, 'This report belongs to another account or team.');
      return r;
    });

    api.post('/reports/:id/events', async (req: FastifyRequest<{ Params: { id: string } }>) => {
      const user = await currentUser(req);
      const parsed = eventInput.safeParse(body(req));
      if (!parsed.success) fail(400, 'Check the action details and try again.');
      const e = parsed.data!;
      if (user.role === 'citizen') fail(403, 'Only LGU staff and road crews can change a report.');
      if (['complete', 'before-photos'].includes(e.action) && !e.photos) fail(400, 'Upload real repair photos first.');
      return store.tx(async tx => {
        const r = await tx.getReport(req.params.id, { forUpdate: true });
        if (!r) fail(404, 'Report not found.');
        if (!canSee(user, r!)) fail(403, 'This report belongs to another account or team.');
        if (e.photos?.length) await requireUploads(tx, e.photos, user, r!);
        if (e.action === 'duplicate') {
          const original = e.duplicateOf && e.duplicateOf !== r!.id ? await tx.getReport(e.duplicateOf) : null;
          if (!original || hiddenFromPublic.includes(original.status)) fail(400, 'Original report not found.');
        }
        // complete = after photos, before-photos = before; progress photos default to after.
        const kindOf = (p: z.infer<typeof photoRef>) =>
          e.action === 'complete' ? 'after' : e.action === 'before-photos' ? 'before' : p.kind === 'before' ? 'before' : 'after';
        const photos = e.photos?.map(p => sanitizePhoto(p, kindOf(p)));
        const teams = e.action === 'assign' ? await tx.listTeams() : [];
        transition(r!, user.role, e.action, { ...e, photos }, teams, { id: user.id, name: user.name });
        await tx.saveReport(r!);
        await notify(tx, r!, eventTitle(r!, e.action, teams), e.action, user.role);
        return r;
      });
    });

    api.post('/reports/:id/feedback', async (req: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) => {
      const user = await currentUser(req);
      const feedback = await store.tx(async tx => {
        const r = await tx.getReport(req.params.id, { forUpdate: true });
        if (!r) fail(404, 'Report not found.');
        if (user.role !== 'citizen' || r!.reporterId !== user.id) fail(403, 'This report belongs to another account or team.');
        if (r!.status !== 'Resolved' || r!.feedback) fail(409, 'Feedback is available once for resolved reports.');
        const b = body(req);
        const feedbackText = typeof b.text === 'string' ? b.text.trim() : '';
        if (!Number.isInteger(b.rating) || b.rating < 1 || b.rating > 5 || !feedbackText || feedbackText.length > 1000) fail(400, 'Choose a rating and add feedback.');
        r!.feedback = { rating: b.rating, text: feedbackText, at: new Date().toISOString() };
        await tx.saveReport(r!);
        return r!.feedback;
      });
      return reply.code(201).send(feedback);
    });

    // ---- admin workspace
    async function admin(req: FastifyRequest) {
      const user = await currentUser(req);
      if (user.role !== 'admin') fail(403, 'Administrator access required.');
      return user;
    }

    api.patch('/settings', async req => {
      await admin(req);
      const b = body(req);
      const s = { agency: String(b.agency ?? '').trim(), city: String(b.city ?? '').trim(), province: String(b.province ?? '').trim() };
      if (!s.agency || !s.city || !s.province) fail(400, 'Agency, city and province are required.');
      if (Object.values(s).some(v => v.length > 120)) fail(400, 'Keep each field within 120 characters.');
      return store.setSettings(s);
    });

    async function saveTeam(req: FastifyRequest, create: boolean) {
      await admin(req);
      const b = body(req);
      const name = typeof b.name === 'string' ? b.name.trim() : '';
      if (!name || name.length > 100) fail(400, 'Team name is required.');
      if (b.memberIds !== undefined && (!Array.isArray(b.memberIds) || b.memberIds.length > 1000 ||
          b.memberIds.some((id: unknown) => typeof id !== 'string' || !id || id.length > 100) ||
          new Set(b.memberIds).size !== b.memberIds.length)) fail(400, 'Choose unique member account IDs.');
      const memberIds = b.memberIds as string[] | undefined;
      return store.tx(async tx => {
        // Serialize team edits and transfers, then validate locked account rows before changing any links.
        await tx.db.query('select id from teams order by id for update');
        const existing = create ? null : await tx.teamById(String(b.id ?? ''));
        if (!create && !existing) fail(404, 'Team not found.');
        if (await tx.teamNameTaken(name, existing?.id ?? null)) fail(409, 'A team with that name already exists.');
        const active = b.active !== false;
        if (memberIds !== undefined) {
          await tx.db.query('select id from users where id = any($1::text[]) or team_id = $2 order by id for update', [memberIds, existing?.id ?? null]);
          const users = await tx.listUsers();
          if (memberIds.some(id => !users.some(u => u.id === id && u.active && u.role === 'maintenance')))
            fail(400, 'Choose active road crew accounts only.');
          if (!active && memberIds.length) fail(400, 'Members require an active maintenance team.');
        }
        const team = create ? await tx.insertTeam({ name, active }) : await tx.updateTeam({ id: existing!.id, name, active });
        if (!team) fail(409, 'A team with that name already exists.');
        if (memberIds !== undefined) await tx.replaceTeamMembers(team!.id, memberIds);
        if (!active && await tx.teamHasOpenWorkOrMembers(team!.id)) fail(409, 'Move active members and finish assigned tasks before deactivating this team.');
        return tx.teamById(team!.id);
      });
    }
    api.post('/teams', async (req, reply) => reply.code(201).send(await saveTeam(req, true)));
    api.patch('/teams', async req => saveTeam(req, false));

    async function teamCheck(tx: Store, role: string, teamId: string | null | undefined, allowUnassigned = false) {
      if (role !== 'maintenance' || (allowUnassigned && !teamId)) return null;
      const team = teamId ? await tx.teamById(teamId) : null;
      if (!team?.active) fail(400, 'Choose an active maintenance team.');
      return team!.id;
    }

    api.post('/users', async (req, reply) => {
      await admin(req);
      const b = body(req);
      const saved = await store.tx(async tx => {
        await tx.db.query('select id from teams order by id for update');
        const f = registrationFields(b);
        const role = b.role ?? 'citizen';
        if (!roles.includes(role)) fail(400, 'Choose a valid role.');
        const teamId = await teamCheck(tx, role, b.teamId);
        const user = await tx.insertUser({
          name: f.name, email: f.email, role, active: b.active !== false, teamId,
          address: role === 'citizen' && b.address ? f.address : null, emailVerified: false, passwordHash: await hashPassword(f.password),
        });
        if (!user) fail(409, 'Email is already registered.');
        return publicUser(user!);
      });
      return reply.code(201).send(saved);
    });

    api.patch('/users', async req => {
      const me = await admin(req);
      const b = body(req);
      return store.tx(async tx => {
        await tx.db.query('select id from teams order by id for update');
        await tx.db.query('select id from users where id = $1 for update', [String(b.id ?? '')]);
        const user = await tx.userById(String(b.id ?? ''));
        if (!user) fail(404, 'Account not found.');
        if (user!.id === me.id) fail(400, 'Manage your own profile in Settings.');
        if (typeof b.name === 'string' && b.name.trim()) {
          const name = b.name.trim();
          if (name.length > 100) fail(400, 'Enter your name (up to 100 characters).');
          user!.name = name;
        }
        if (typeof b.email === 'string' && b.email.trim()) {
          const email = b.email.trim().toLowerCase();
          if (email.length > 254 || !EMAIL.test(email)) fail(400, 'Enter a valid email address.');
          if (await tx.emailTaken(email, user!.id)) fail(409, 'Email is already registered.');
          user!.email = email;
        }
        if (typeof b.password === 'string' && b.password.length > 0) {
          const pw = validatePassword(b.password);
          user!.passwordHash = await hashPassword(pw);
        }
        const role = b.role ?? user!.role;
        if (!roles.includes(role)) fail(400, 'Choose a valid role.');
        user!.teamId = await teamCheck(tx, role, b.teamId ?? user!.teamId, user!.role === 'maintenance' && !user!.teamId);
        user!.role = role;
        if (typeof b.active === 'boolean') user!.active = b.active;
        await tx.updateUser(user!);
        return publicUser(user!);
      });
    });

    async function removeUser(req: FastifyRequest, targetId: string) {
      const me = await admin(req);
      const user = await store.userById(targetId);
      if (!user) fail(404, 'Account not found.');
      if (user!.id === me.id) fail(400, 'You cannot delete your own account.');
      await store.deleteUser(user!.id, me.id);
      return { ok: true, id: user!.id };
    }

    api.delete('/users', async req => removeUser(req, String(body(req).id ?? '')));
    api.delete('/users/:id', async (req: FastifyRequest<{ Params: { id: string } }>) => removeUser(req, req.params.id));
  }, { prefix: '/api' });

  return app;
}
