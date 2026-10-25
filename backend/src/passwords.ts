// scrypt (memory-hard, built into Node; no native build step) in a self-describing format.
import { randomBytes, scrypt as scryptCb, timingSafeEqual, createHash } from 'node:crypto';
import { promisify } from 'node:util';

const scrypt = promisify(scryptCb) as (pw: string, salt: Buffer, len: number, opts: object) => Promise<Buffer>;
const N = 2 ** 15, r = 8, p = 1, LEN = 64;
const opts = (n: number) => ({ N: n, r, p, maxmem: 128 * n * r * 2 });

export async function hashPassword(password: string) {
  const salt = randomBytes(16);
  const key = await scrypt(password.normalize('NFKC'), salt, LEN, opts(N));
  return `scrypt$${N}$${r}$${p}$${salt.toString('base64')}$${key.toString('base64')}`;
}

// Used when the account does not exist, so response time does not reveal registered emails.
const DUMMY = `scrypt$${N}$${r}$${p}$${Buffer.alloc(16).toString('base64')}$${Buffer.alloc(LEN).toString('base64')}`;

export async function verifyPassword(password: string, stored: string | null) {
  const [scheme, n, , , salt, key] = (stored || DUMMY).split('$');
  if (scheme !== 'scrypt') return false;
  const expected = Buffer.from(key, 'base64');
  const actual = await scrypt(password.normalize('NFKC'), Buffer.from(salt, 'base64'), expected.length, opts(Number(n)));
  return timingSafeEqual(actual, expected) && !!stored;
}

export const sha256 = (s: string) => createHash('sha256').update(s).digest('hex');
export const newToken = () => randomBytes(32).toString('base64url');
