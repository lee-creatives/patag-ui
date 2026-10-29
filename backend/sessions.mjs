import { fail, fields, email } from './config.mjs';
import { transaction,publicUser } from './db.mjs';
import { verifyPassword,newToken,sha256 } from './passwords.mjs';
export const sessionSeconds=8*60*60;
export function sessionCookie(config,token='',seconds=token?sessionSeconds:0) {
  return 'patag-session='+token+'; Path=/api; HttpOnly; SameSite=Strict; Max-Age='+seconds+(config.secure?'; Secure':'');
}
function readSession(req) {
  const value=(req.headers.cookie??'').split(';').map(item=>item.trim()).find(item=>item.startsWith('patag-session='))?.slice(14);
  return typeof value==='string'&&/^[A-Za-z0-9_-]{43}$/.test(value)?value:null;
}
export async function loginAccount(pool,input) {
  fields(input,['email','password']);
  const mail=email(input.email);
  if(typeof input.password!=='string'||!input.password.length||input.password.length>256) fail(401,'Email or password is incorrect for this portal.');
  return transaction(pool,async db=>{
    const user=(await db.query('SELECT * FROM public.users WHERE lower(email)=$1 FOR SHARE',[mail])).rows[0];
    const valid=await verifyPassword(input.password,user?.password_hash??null);
    if(!valid||!user.active||user.role!=='admin') fail(401,'Email or password is incorrect for this portal.');
    const token=newToken();
    await db.query('INSERT INTO public.sessions(token_hash,user_id,expires_at) VALUES($1,$2,$3)',[sha256(token),user.id,new Date(Date.now()+sessionSeconds*1000).toISOString()]);
    return {token,user:publicUser(user)};
  });
}
export async function authenticateAccount(pool,req) {
  const token=readSession(req);
  if(!token) fail(401,'Session expired. Sign in again.');
  const user=(await pool.query("SELECT u.id FROM public.sessions s JOIN public.users u ON u.id=s.user_id WHERE s.token_hash=$1 AND s.expires_at>now() AND u.active AND u.role='admin'",[sha256(token)])).rows[0];
  if(!user) fail(401,'Session expired. Sign in again.');
  return {sub:user.id,sessionHash:sha256(token)};
}
export async function logoutAccount(pool,req) {
  const token=readSession(req);
  if(token) await pool.query('DELETE FROM public.sessions WHERE token_hash=$1',[sha256(token)]);
}
