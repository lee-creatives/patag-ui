import test from 'node:test';
import assert from 'node:assert/strict';
import { scryptSync } from 'node:crypto';
import { database,fixtures,ids } from './database.mjs';
import { hashPassword,verifyPassword } from '../passwords.mjs';
import { loginAccount,authenticateAccount,logoutAccount,sessionCookie } from '../sessions.mjs';
import { requireSharedSchema,transaction } from '../db.mjs';
import {updateUser} from '../accounts.mjs';
import {createServer} from '../server.mjs';
import {setInitialAdminPassword} from '../set-admin-password.mjs';
const secret='Existing mobile password 123';
test('password verification uses the existing mobile scrypt format and rejects malformed hashes safely',async()=>{
 const salt=Buffer.alloc(16,7),key=scryptSync(secret.normalize('NFKC'),salt,64,{N:32768,r:8,p:1,maxmem:67108864});
 const mobile=['scrypt','32768','8','1',salt.toString('base64'),key.toString('base64')].join('$');
 assert.equal(await verifyPassword(secret,mobile),true);
 assert.equal(await verifyPassword('wrong password',mobile),false);
 for(const invalid of [null,'scrypt$999999999$8$1$x$x','scrypt$32768$8$1$broken$broken','other']) assert.equal(await verifyPassword(secret,invalid),false);
 const normalized=await hashPassword('Ｆｕｌｌ password 123');assert.equal(await verifyPassword('Full password 123',normalized),true);
});
test('shared sessions verify current account access and expire or revoke without Auth records',async()=>{
 const pool=await database();
 try {
  await fixtures(pool.db);await pool.db.exec('DROP SCHEMA auth CASCADE');
  await pool.db.query('UPDATE public.users SET password_hash=$1 WHERE id=$2',[await hashPassword(secret),ids.admin]);
  await pool.db.query('UPDATE public.users SET password_hash=$1 WHERE id=ANY($2::text[])',[await hashPassword(secret),[ids.citizen,ids.inactive]]);
  const issued=await loginAccount(pool,{email:'ADMIN@example.test',password:secret});
  assert.equal(issued.user.id,ids.admin);assert.equal(issued.user.password_hash,undefined);
  const req={headers:{cookie:'patag-session='+issued.token}};
  assert.equal((await authenticateAccount(pool,req)).sub,ids.admin);
  assert.match(sessionCookie({secure:true},issued.token),/HttpOnly; SameSite=Strict/);assert.match(sessionCookie({secure:true},issued.token),/Secure/);
  assert.notEqual((await pool.db.query('SELECT token_hash FROM public.sessions')).rows[0].token_hash,issued.token);
  await pool.db.query('UPDATE public.users SET active=false WHERE id=$1',[ids.admin]);await assert.rejects(authenticateAccount(pool,req),e=>e.status===401);
  await pool.db.query('UPDATE public.users SET active=true WHERE id=$1',[ids.admin]);
  await pool.db.query("UPDATE public.sessions SET expires_at=now()-interval '1 second'");await assert.rejects(authenticateAccount(pool,req),e=>e.status===401);
  const next=await loginAccount(pool,{email:'admin@example.test',password:secret});await logoutAccount(pool,{headers:{cookie:'patag-session='+next.token}});
  await assert.rejects(authenticateAccount(pool,{headers:{cookie:'patag-session='+next.token}}),e=>e.status===401);
  const sessionCount=(await pool.db.query('SELECT token_hash FROM public.sessions')).rows.length;
  for(const mail of ['missing@example.test','citizen@example.test','inactive@example.test']) await assert.rejects(loginAccount(pool,{email:mail,password:secret}),e=>e.status===401&&e.message==='Email or password is incorrect for this portal.');
  assert.equal((await pool.db.query('SELECT token_hash FROM public.sessions')).rows.length,sessionCount);
 }finally{await pool.end();}
});
test('an unmigrated UUID profile schema reports required upgrade before querying text account IDs',async()=>{
 const pool=await database({legacy:true});
 try {await assert.rejects(requireSharedSchema(pool),e=>e.status===503&&e.message.includes('202610290001_shared_accounts.sql'));}finally{await pool.end();}
});

test('initial password setup changes only an existing admin with no credential and revokes prior sessions',async()=>{
 const pool=await database();try{
  await fixtures(pool.db);
  await pool.db.query("INSERT INTO public.sessions(token_hash,user_id,expires_at) VALUES('old-demo-session',$1,now()+interval '1 hour')",[ids.admin]);
  await setInitialAdminPassword(pool,{email:'admin@example.test',password:secret});
  const user=(await pool.db.query('SELECT password_hash FROM public.users WHERE id=$1',[ids.admin])).rows[0];assert.equal(await verifyPassword(secret,user.password_hash),true);
  assert.equal((await pool.db.query('SELECT * FROM public.sessions')).rows.length,0);
  await assert.rejects(setInitialAdminPassword(pool,{email:'admin@example.test',password:'another secret password'}),e=>e.status===409);
  await assert.rejects(setInitialAdminPassword(pool,{email:'citizen@example.test',password:secret}),e=>e.status===404);
  await assert.rejects(setInitialAdminPassword(pool,{email:'missing@example.test',password:secret}),e=>e.status===404);
 }finally{await pool.end();}
});

test('protected operation transactions reject sessions revoked or accounts demoted after initial authentication',async()=>{
 const pool=await database();try {
  await fixtures(pool.db);await pool.db.query('UPDATE public.users SET password_hash=$1 WHERE id=$2',[await hashPassword(secret),ids.admin]);
  const first=await loginAccount(pool,{email:'admin@example.test',password:secret}),req={headers:{cookie:'patag-session='+first.token}};
  const context=await authenticateAccount(pool,req);await logoutAccount(pool,req);
  await assert.rejects(transaction(pool,()=>{throw Error('Operation must not run');},context),e=>e.status===401);
  const next=await loginAccount(pool,{email:'admin@example.test',password:secret});
  const nextContext=await authenticateAccount(pool,{headers:{cookie:'patag-session='+next.token}});
  await pool.db.query("UPDATE public.users SET role='citizen' WHERE id=$1",[ids.admin]);
  await assert.rejects(transaction(pool,()=>{throw Error('Operation must not run');},nextContext),e=>e.status===401);
 }finally{await pool.end();}
});

test('the HTTP readiness boundary reports the required migration instead of a misleading constraint error',async()=>{
 const pool=await database({legacy:true}),config={origin:'http://127.0.0.1:5173',secure:false};
 const server=createServer({config,pool,storage:{}});await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 try {
  const base='http://127.0.0.1:'+server.address().port+'/api';
  for(const path of ['/health','/auth/login']) {
   const response=await fetch(base+path,path==='/health'?{}:{method:'POST',headers:{Origin:config.origin,'Content-Type':'application/json','X-Patag-Request':'1'},body:JSON.stringify({email:'admin@example.test',password:secret})});
   assert.equal(response.status,503);assert.match((await response.json()).error,/202610290001_shared_accounts.sql/);
  }
 }finally{await new Promise(resolve=>server.close(resolve));await pool.end();}
});
test('deactivation and role changes permanently revoke shared sessions, including after reactivation',async()=>{
 const pool=await database();try {
  await fixtures(pool.db);await pool.db.query("INSERT INTO public.users(id,name,email,role,password_hash) VALUES('shared:second-admin','Second Admin','second@example.test','admin',$1)",[await hashPassword(secret)]);
  let login=await loginAccount(pool,{email:'second@example.test',password:secret});
  await transaction(pool,db=>updateUser(db,{id:login.user.id,role:'admin',active:false}),{sub:ids.admin});
  await transaction(pool,db=>updateUser(db,{id:login.user.id,role:'admin',active:true}),{sub:ids.admin});
  await assert.rejects(authenticateAccount(pool,{headers:{cookie:'patag-session='+login.token}}),e=>e.status===401);
  login=await loginAccount(pool,{email:'second@example.test',password:secret});
  await transaction(pool,db=>updateUser(db,{id:login.user.id,role:'citizen',active:true}),{sub:ids.admin});
  await transaction(pool,db=>updateUser(db,{id:login.user.id,role:'admin',active:true}),{sub:ids.admin});
  await assert.rejects(authenticateAccount(pool,{headers:{cookie:'patag-session='+login.token}}),e=>e.status===401);
 }finally{await pool.end();}
});
