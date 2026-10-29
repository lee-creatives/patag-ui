import { fileURLToPath } from 'node:url';
import { configuration,fail,email } from './config.mjs';
import { poolFor,transaction,requireSharedSchema } from './db.mjs';
import { hashPassword } from './passwords.mjs';
export async function setInitialAdminPassword(pool,input) {
  const mail=email(input.email),secret=input.password;
  if(typeof secret!=='string'||secret.length<15||secret.length>128||!secret.trim()) fail(400,'Use a password containing 15–128 characters.');
  await requireSharedSchema(pool);
  return transaction(pool,async db=>{
    const user=(await db.query("SELECT id,password_hash FROM public.users WHERE lower(email)=$1 AND role='admin' AND active FOR UPDATE",[mail])).rows[0];
    if(!user) fail(404,'An existing active shared administrator account is required.');
    if(user.password_hash!==null) fail(409,'This account already has a password; no credential was changed.');
    await db.query('UPDATE public.users SET password_hash=$1,updated_at=now() WHERE id=$2',[await hashPassword(secret),user.id]);
    await db.query('DELETE FROM public.sessions WHERE user_id=$1',[user.id]);
    return {ok:true};
  });
}
if(process.argv[1]===fileURLToPath(import.meta.url)) {
  let pool;
  try {
    if(process.env.PATAG_ALLOW_HOSTED_MUTATIONS!=='true') throw Error('Hosted credential initialization requires explicit authorization: PATAG_ALLOW_HOSTED_MUTATIONS=true.');
    const config=configuration();pool=poolFor(config);
    await setInitialAdminPassword(pool,{email:process.env.ADMIN_EMAIL,password:process.env.ADMIN_PASSWORD});
    console.log('Initial shared administrator password configured. Existing sessions were revoked.');
  }catch(error){console.error(error.status?error.message:error.code?'Credential setup could not complete. Check schema and private server configuration.':error.message);process.exitCode=1;}
  finally{delete process.env.ADMIN_PASSWORD;if(pool) await pool.end();}
}
