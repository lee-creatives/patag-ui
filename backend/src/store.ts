// All SQL lives here. Rows are mapped to the JSON shapes in docs/api-contract.md.
import type { Db } from './db.ts';
import type { Notification, Report, Role, Settings, Team, User } from './domain.ts';
import { hiddenFromPublic, closedStatuses } from './domain.ts';

const iso = (v: unknown) => (v instanceof Date ? v.toISOString() : String(v));
const json = (v: unknown) => (v === undefined || v === null ? null : JSON.stringify(v));

const USER_COLS = 'id, name, email, role, active, team_id, address, email_verified, password_hash';
const toUser = (r: any): User => ({
  id: r.id, name: r.name, email: r.email, role: r.role, active: r.active, teamId: r.team_id,
  address: r.address, emailVerified: r.email_verified, passwordHash: r.password_hash,
});

const REPORT_COLS = 'id, title, description, hazards, severity, status, location, photos, reporter_id, jurisdiction, team_id, assignment, history, updates, completion, feedback, flagged, duplicate_of, public_photos_approved, created_at, updated_at';
const toReport = (r: any): Report => ({
  id: r.id, title: r.title, description: r.description, hazards: r.hazards, severity: r.severity, status: r.status,
  location: r.location, photos: r.photos, reporterId: r.reporter_id, jurisdiction: r.jurisdiction,
  createdAt: iso(r.created_at), updatedAt: iso(r.updated_at), teamId: r.team_id, assignment: r.assignment,
  history: r.history, updates: r.updates, completion: r.completion, feedback: r.feedback, flagged: r.flagged,
  ...(r.duplicate_of ? { duplicateOf: r.duplicate_of } : {}),
  ...(r.public_photos_approved !== null ? { publicPhotosApproved: r.public_photos_approved } : {}),
});
const reportParams = (r: Report) => [
  r.id, r.title, r.description, r.hazards, r.severity, r.status, json(r.location), json(r.photos), r.reporterId,
  r.jurisdiction, r.teamId, json(r.assignment), json(r.history), json(r.updates), json(r.completion), json(r.feedback),
  r.flagged, r.duplicateOf ?? null, r.publicPhotosApproved ?? null, r.createdAt, r.updatedAt,
];

const TEAM_SELECT = `select t.id, t.name, t.active,
  coalesce((select array_agg(u.name order by u.name) from users u
            where u.team_id = t.id and u.role = 'maintenance' and u.active), '{}') as members
  from teams t`;
const toTeam = (r: any): Team => ({ id: r.id, name: r.name, active: r.active, members: r.members ?? [] });

export class Store {
  db: Db;
  constructor(db: Db) { this.db = db; }

  tx<T>(fn: (store: Store) => Promise<T>) { return this.db.tx(inner => fn(new Store(inner))); }

  // ---- users
  async userByEmail(email: string) {
    const { rows } = await this.db.query(`select ${USER_COLS} from users where lower(email) = lower($1)`, [email]);
    return rows[0] ? toUser(rows[0]) : null;
  }
  async userById(id: string) {
    const { rows } = await this.db.query(`select ${USER_COLS} from users where id = $1`, [id]);
    return rows[0] ? toUser(rows[0]) : null;
  }
  async listUsers() {
    return (await this.db.query(`select ${USER_COLS} from users order by created_at, id`)).rows.map(toUser);
  }
  async demoUser(role: string, userId?: string) {
    const { rows } = await this.db.query(
      `select ${USER_COLS} from users where role = $1 and active and password_hash is null and ($2::text is null or id = $2) order by id limit 1`,
      [role, userId ?? null]);
    return rows[0] ? toUser(rows[0]) : null;
  }
  async listDemoUsers() {
    return (await this.db.query(`select ${USER_COLS} from users where active and password_hash is null order by role, id`)).rows.map(toUser);
  }
  async insertUser(u: Omit<User, 'id'> & { id?: string }) {
    const { rows } = await this.db.query(
      `insert into users (id, name, email, role, active, team_id, address, email_verified, password_hash)
       values (coalesce($1, gen_random_uuid()::text), $2, $3, $4, $5, $6, $7::jsonb, $8, $9)
       on conflict do nothing returning ${USER_COLS}`,
      [u.id ?? null, u.name, u.email, u.role, u.active, u.teamId, json(u.address), u.emailVerified, u.passwordHash]);
    return rows[0] ? toUser(rows[0]) : null;
  }
  async emailTaken(email: string, exceptId: string | null) {
    const { rows } = await this.db.query('select 1 from users where lower(email) = lower($1) and id is distinct from $2', [email, exceptId]);
    return rows.length > 0;
  }
  async updateUser(u: User) {
    await this.db.query(
      `update users set name = $2, email = $3, role = $4, active = $5, team_id = $6, address = $7::jsonb, password_hash = $8, updated_at = now() where id = $1`,
      [u.id, u.name, u.email, u.role, u.active, u.teamId, json(u.address), u.passwordHash]);
    // A disabled account loses its sessions immediately (role changes apply on the next request).
    if (!u.active) await this.db.query('delete from sessions where user_id = $1', [u.id]);
  }
  async deleteUser(id: string, fallbackReporterId: string) {
    await this.db.query('update reports set reporter_id = $2 where reporter_id = $1', [id, fallbackReporterId]);
    await this.db.query('delete from sessions where user_id = $1', [id]);
    await this.db.query('delete from notifications where user_id = $1', [id]);
    await this.db.query('delete from users where id = $1', [id]);
  }

  /** Self-service profile edit: touches only name/address, never role, team, active or password. */
  async updateProfile(id: string, name: string, address: User['address'] | undefined) {
    const { rows } = await this.db.query(
      `update users set name = $2, address = coalesce($3::jsonb, address), updated_at = now() where id = $1 returning ${USER_COLS}`,
      [id, name, address ? JSON.stringify(address) : null]);
    return rows[0] ? toUser(rows[0]) : null;
  }

  // ---- sessions (only SHA-256 hashes of tokens are stored)
  async createSession(tokenHash: string, userId: string, expiresAt: Date) {
    await this.db.query('insert into sessions (token_hash, user_id, expires_at) values ($1, $2, $3)', [tokenHash, userId, expiresAt.toISOString()]);
  }
  async sessionUser(tokenHash: string) {
    const { rows } = await this.db.query(
      `select ${USER_COLS.split(', ').map(c => 'u.' + c).join(', ')} from sessions s join users u on u.id = s.user_id
       where s.token_hash = $1 and s.expires_at > now() and u.active`, [tokenHash]);
    return rows[0] ? toUser(rows[0]) : null;
  }
  async deleteSession(tokenHash: string) { await this.db.query('delete from sessions where token_hash = $1', [tokenHash]); }
  async purgeExpiredSessions() { await this.db.query('delete from sessions where expires_at <= now()'); }

  // ---- teams
  async listTeams() { return (await this.db.query(`${TEAM_SELECT} order by t.created_at, t.id`)).rows.map(toTeam); }
  async teamById(id: string) {
    const { rows } = await this.db.query(`${TEAM_SELECT} where t.id = $1`, [id]);
    return rows[0] ? toTeam(rows[0]) : null;
  }
  async teamNameTaken(name: string, exceptId: string | null) {
    const { rows } = await this.db.query('select 1 from teams where lower(name) = lower($1) and id is distinct from $2', [name, exceptId]);
    return rows.length > 0;
  }
  async insertTeam(t: { id?: string; name: string; active: boolean }) {
    const { rows } = await this.db.query(
      'insert into teams (id, name, active) values (coalesce($1, gen_random_uuid()::text), $2, $3) on conflict do nothing returning id',
      [t.id ?? null, t.name, t.active]);
    return rows[0] ? this.teamById(rows[0].id) : null;
  }
  async updateTeam(t: { id: string; name: string; active: boolean }) {
    await this.db.query('update teams set name = $2, active = $3 where id = $1', [t.id, t.name, t.active]);
    return this.teamById(t.id);
  }
  async replaceTeamMembers(teamId: string, memberIds: string[]) {
    await this.db.query(`update users set team_id = null, updated_at = now()
      where team_id = $1 and role = 'maintenance' and active and not (id = any($2::text[]))`, [teamId, memberIds]);
    await this.db.query('update users set team_id = $1, updated_at = now() where id = any($2::text[])', [teamId, memberIds]);
  }
  async teamHasOpenWorkOrMembers(teamId: string) {
    const { rows } = await this.db.query(
      `select exists (select 1 from reports where team_id = $1 and status <> all($2::text[]))
           or exists (select 1 from users where team_id = $1 and active) as busy`, [teamId, closedStatuses]);
    return !!rows[0].busy;
  }

  // ---- reports
  async listReports(scope: { reporterId?: string; teamId?: string | null }) {
    if ('reporterId' in scope) return (await this.db.query(`select ${REPORT_COLS} from reports where reporter_id = $1 order by created_at desc`, [scope.reporterId])).rows.map(toReport);
    if ('teamId' in scope) return (await this.db.query(`select ${REPORT_COLS} from reports where team_id = $1 order by created_at desc`, [scope.teamId])).rows.map(toReport);
    return (await this.db.query(`select ${REPORT_COLS} from reports order by created_at desc`)).rows.map(toReport);
  }
  async listPublicReports() {
    return (await this.db.query(`select ${REPORT_COLS} from reports where status <> all($1::text[]) order by created_at desc`, [hiddenFromPublic])).rows.map(toReport);
  }
  async reportsOnRoad(road: string) {
    return (await this.db.query(`select ${REPORT_COLS} from reports where lower(location ->> 'road') = lower($1) and status <> all($2::text[])`, [road.trim(), hiddenFromPublic])).rows.map(toReport);
  }
  async getReport(id: string, { forUpdate = false } = {}) {
    const { rows } = await this.db.query(`select ${REPORT_COLS} from reports where id = $1${forUpdate ? ' for update' : ''}`, [id]);
    return rows[0] ? toReport(rows[0]) : null;
  }
  async nextReportId() {
    const { rows } = await this.db.query("select nextval('report_code_seq')::int as n");
    return `PTG-${new Date().getUTCFullYear()}-${String(rows[0].n).padStart(4, '0')}`;
  }
  async insertReport(r: Report) {
    await this.db.query(
      `insert into reports (${REPORT_COLS}) values ($1, $2, $3, $4, $5, $6, $7::jsonb, $8::jsonb, $9, $10, $11, $12::jsonb, $13::jsonb, $14::jsonb, $15::jsonb, $16::jsonb, $17, $18, $19, $20::timestamptz, $21::timestamptz)
       on conflict do nothing`, reportParams(r));
  }
  async saveReport(r: Report) {
    await this.db.query(
      `update reports set title = $2, description = $3, hazards = $4, severity = $5, status = $6, location = $7::jsonb, photos = $8::jsonb,
         reporter_id = $9, jurisdiction = $10, team_id = $11, assignment = $12::jsonb, history = $13::jsonb, updates = $14::jsonb,
         completion = $15::jsonb, feedback = $16::jsonb, flagged = $17, duplicate_of = $18, public_photos_approved = $19,
         created_at = $20::timestamptz, updated_at = $21::timestamptz
       where id = $1`, reportParams(r));
  }
  async reportExists(id: string) {
    return (await this.db.query('select 1 from reports where id = $1', [id])).rows.length > 0;
  }

  // ---- uploads
  async recordUpload(name: string, userId: string, contentType: string, size: number) {
    await this.db.query('insert into uploads (name, uploaded_by, content_type, size_bytes) values ($1, $2, $3, $4)', [name, userId, contentType, size]);
  }
  /** True when every upload exists and was uploaded by this user. */
  async uploadsOwnedBy(names: string[], userId: string) {
    const unique = [...new Set(names)];
    if (!unique.length) return true;
    const { rows } = await this.db.query('select count(*)::int as n from uploads where name = any($1::text[]) and uploaded_by = $2', [unique, userId]);
    return rows[0].n === unique.length;
  }

  // ---- notifications
  async addNotifications(list: Omit<Notification, 'id' | 'at' | 'read'>[]) {
    for (const n of list) {
      await this.db.query('insert into notifications (role, user_id, team_id, report_id, title) values ($1, $2, $3, $4, $5)',
        [n.role, n.userId, n.teamId, n.reportId, n.title]);
    }
  }
  private scope(user: User) {
    if (user.role === 'citizen') return { sql: "role = 'citizen' and user_id = $1", param: user.id };
    if (user.role === 'maintenance') return { sql: "role = 'maintenance' and team_id = $1", param: user.teamId };
    return { sql: "role = 'admin' and $1::text is null", param: null };
  }
  async notificationsFor(user: User, limit = 200): Promise<Notification[]> {
    const s = this.scope(user);
    const { rows } = await this.db.query(
      `select id, role, user_id, team_id, report_id, title, at, read from notifications where ${s.sql} order by at desc limit ${Number(limit)}`, [s.param]);
    return rows.map(r => ({ id: r.id, role: r.role as Role, userId: r.user_id, teamId: r.team_id, reportId: r.report_id, title: r.title, at: iso(r.at), read: r.read }));
  }
  async markNotificationsRead(user: User, id: string) {
    const s = this.scope(user);
    await this.db.query(`update notifications set read = true where ${s.sql} and ($2 = 'all' or id = $2)`, [s.param, id]);
  }

  // ---- settings
  async getSettings(): Promise<Settings> {
    const { rows } = await this.db.query<Settings>('select agency, city, province from settings where id = 1');
    return rows[0] ?? { agency: 'Unconfigured agency', city: '', province: '' };
  }
  async setSettings(s: Settings) {
    await this.db.query(
      `insert into settings (id, agency, city, province) values (1, $1, $2, $3)
       on conflict (id) do update set agency = excluded.agency, city = excluded.city, province = excluded.province, updated_at = now()`,
      [s.agency, s.city, s.province]);
    return s;
  }
}
