// Shared mobile contract: Citizen-mobile-Backend/backend/src/passwords.ts.
import { randomBytes, scrypt as scryptCallback, timingSafeEqual, createHash } from 'node:crypto';
import { promisify } from 'node:util';
const scrypt=promisify(scryptCallback);
const options={N:32768,r:8,p:1,maxmem:67108864};
export async function hashPassword(password) {
  const salt=randomBytes(16),key=await scrypt(password.normalize('NFKC'),salt,64,options);
  return ['scrypt','32768','8','1',salt.toString('base64'),key.toString('base64')].join('$');
}
export async function verifyPassword(password,stored) {
  const parts=typeof stored==='string'?/^scrypt\$32768\$8\$1\$([A-Za-z0-9+/]{22}==)\$([A-Za-z0-9+/]{86}==)$/.exec(stored):null;
  const salt=parts?Buffer.from(parts[1],'base64'):Buffer.alloc(16),expected=parts?Buffer.from(parts[2],'base64'):Buffer.alloc(64);
  const canonical=parts&&salt.toString('base64')===parts[1]&&expected.toString('base64')===parts[2];
  const actual=await scrypt(password.normalize('NFKC'),salt,64,options);
  return timingSafeEqual(actual,expected)&&Boolean(canonical);
}
export const sha256=value=>createHash('sha256').update(value).digest('hex');
export const newToken=()=>randomBytes(32).toString('base64url');
