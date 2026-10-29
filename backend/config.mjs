export class HttpError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}
export const fail = (status, message) => { throw new HttpError(status, message); };
export function fields(value, allowed) {
  if (!value || Array.isArray(value) || typeof value !== 'object' || Object.keys(value).some(key => !allowed.includes(key))) fail(400, 'Invalid request fields.');
  return value;
}
export function text(value, label, max = 2000, required = true) {
  if (typeof value !== 'string' || value.trim().length > max || (required && !value.trim())) fail(400, `Invalid ${label}.`);
  return value.trim();
}

export function email(value) {
  const result = text(value, 'email', 254).toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(result)) fail(400, 'Enter a valid email.');
  return result;
}
export function uuid(value) {
  if (typeof value !== 'string' || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)) fail(400, 'Invalid record identifier.');
  return value;
}
export function accountId(value) {
  if(typeof value!=='string'||!value.length||value.length>200||!value.trim()||/[\x00-\x20\x7f/?#]/.test(value)) fail(400,'Invalid account identifier.');
  return value;
}
export const statuses = ['Submitted', 'Under Review', 'Verified', 'Assigned', 'In Progress', 'Resolved', 'Rejected', 'Duplicate'];
export function configuration(env = process.env) {
  for (const key of ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY', 'SUPABASE_DB_URL', 'ADMIN_ORIGIN']) {
    if (!env[key] || env[key].includes('<')) throw Error(`Setup required: ${key} is missing.`);
  }
  const url = new URL(env.SUPABASE_URL), origin = new URL(env.ADMIN_ORIGIN), db = new URL(env.SUPABASE_DB_URL);
  if (url.protocol !== 'https:' || !url.hostname.endsWith('.supabase.co') || url.pathname !== '/') throw Error('SUPABASE_URL must be an HTTPS Supabase project URL.');
  if (!['postgres:', 'postgresql:'].includes(db.protocol)) throw Error('SUPABASE_DB_URL must be a PostgreSQL URI.');
  if (origin.origin !== env.ADMIN_ORIGIN || !['http:', 'https:'].includes(origin.protocol)) throw Error('ADMIN_ORIGIN must be one browser origin.');
  if (origin.protocol !== 'https:' && (env.NODE_ENV === 'production' || !['127.0.0.1', 'localhost'].includes(origin.hostname))) throw Error('ADMIN_ORIGIN requires HTTPS outside local development.');
  const ref = url.hostname.split('.')[0];
  if (!(db.hostname === `db.${ref}.supabase.co` || (db.hostname.endsWith('.pooler.supabase.com') && decodeURIComponent(db.username) === `postgres.${ref}`))) throw Error('SUPABASE_DB_URL must identify the configured Supabase project.');
  for (const key of ['sslmode', 'sslcert', 'sslkey', 'sslrootcert']) db.searchParams.delete(key);
  return { url: url.origin, serviceKey: env.SUPABASE_SERVICE_ROLE_KEY, dbUrl: db.toString(), origin: origin.origin, secure: origin.protocol === 'https:', port: Number(env.PORT || 4101), trustProxy: env.TRUST_PROXY_CLIENT_IP === 'true', production: env.NODE_ENV === 'production' };
}
