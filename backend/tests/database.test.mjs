import test from 'node:test';
import assert from 'node:assert/strict';
import { database, fixtures, ids, asUser } from './database.mjs';
import { migrate } from '../migrate.mjs';
import { transaction } from '../db.mjs';
import { reportEvent } from '../service.mjs';

test('RLS scopes server contexts, rejects browser roles and works after Auth removal',async()=>{
 const pool=await database(),{db}=pool;
 try {
  await fixtures(db);await db.exec('DROP SCHEMA auth CASCADE');
  assert.deepEqual(await migrate(pool),[]);
  const read=()=>db.query('SELECT id FROM public.patag_reports ORDER BY id');
  assert.equal((await asUser(db,ids.admin,read)).rows.length,2);
  assert.deepEqual((await asUser(db,ids.local,read)).rows.map(r=>r.id),[ids.report]);
  assert.deepEqual((await asUser(db,ids.citizen,read)).rows.map(r=>r.id),[ids.report]);
  assert.equal((await asUser(db,ids.inactive,read)).rows.length,0);
  assert.equal((await asUser(db,ids.citizen,()=>db.query("UPDATE public.users SET role='admin' WHERE id=$1 RETURNING id",[ids.citizen]))).rows.length,0);
  for(const role of ['anon','authenticated']) await assert.rejects(asUser(db,ids.admin,()=>db.query('SELECT * FROM public.users'),role),/permission denied/);
  await assert.rejects(db.query('DELETE FROM public.users WHERE id=$1',[ids.citizen]),/foreign key/);
  await assert.rejects(db.query('UPDATE public.patag_reports SET status=$1 WHERE id=$2',['Completed',ids.report]),/check constraint/);
  assert.equal((await transaction(pool,c=>reportEvent(c,ids.report,{action:'verify'}),{sub:ids.admin})).status,'Verified');
 }finally{await pool.end();}
});

test('upgrade preserves mobile and legacy records, IDs, credentials and report relationships',async()=>{
 const pool=await database({legacy:true}),{db}=pool;
 try {
  await db.query("INSERT INTO public.users(id,name,email,role,password_hash) VALUES('mobile:before','Mobile Before','mobile-before@example.test','citizen','unchanged-private-hash')");
  await db.query('INSERT INTO auth.users VALUES($1,$2)',[ids.admin,'legacy@example.test']);
  await db.query("INSERT INTO public.patag_profiles(id,name,email,role) VALUES($1,'Legacy Admin','legacy@example.test','administrator')",[ids.admin]);
  await db.query("INSERT INTO public.patag_reports(id,title,description,road,barangay,municipality,latitude,longitude,reporter_id) VALUES($1,'Legacy report','Legacy description','Road','Barangay','Malolos',14.8,120.8,$2)",[ids.report,ids.admin]);
  assert.deepEqual(await migrate(pool),['202610270001_admin.sql','202610290001_shared_accounts.sql']);
  assert.deepEqual(await migrate(pool),[]);
  assert.equal((await db.query("SELECT password_hash FROM public.users WHERE id='mobile:before'")).rows[0].password_hash,'unchanged-private-hash');
  assert.equal((await db.query('SELECT reporter_id FROM public.patag_reports WHERE id=$1',[ids.report])).rows[0].reporter_id,ids.admin);
  assert.equal((await db.query('SELECT role FROM public.users WHERE id=$1',[ids.admin])).rows[0].role,'admin');
  assert.equal((await db.query("SELECT relkind FROM pg_class WHERE oid='public.patag_profiles'::regclass")).rows[0].relkind,'v');
  await db.exec('DROP SCHEMA auth CASCADE');
  assert.equal((await transaction(pool,c=>reportEvent(c,ids.report,{action:'verify'}),{sub:ids.admin})).status,'Verified');
 }finally{await pool.end();}
});

test('upgrade refuses identity collisions atomically without rewriting mobile accounts',async()=>{
 const pool=await database({legacy:true}),{db}=pool;
 try {
  await db.query("INSERT INTO public.users(id,name,email,role,password_hash) VALUES('mobile:keep','Mobile Keep','collision@example.test','citizen','private-keep')");
  await db.query('INSERT INTO auth.users VALUES($1,$2)',[ids.admin,'collision@example.test']);
  await db.query("INSERT INTO public.patag_profiles(id,name,email,role) VALUES($1,'Legacy','collision@example.test','citizen')",[ids.admin]);
  await assert.rejects(migrate(pool),/identity conflict/);
  assert.equal((await db.query("SELECT password_hash FROM public.users WHERE id='mobile:keep'")).rows[0].password_hash,'private-keep');
  assert.equal((await db.query('SELECT id FROM public.patag_profiles WHERE id=$1',[ids.admin])).rows[0].id,ids.admin);
 }finally{await pool.end();}
});

test('an explicitly distinct legacy administrator email preserves both identities and report references',async()=>{
 const pool=await database({legacy:true}),{db}=pool;
 try {
  await db.query("INSERT INTO public.users(id,name,email,role,password_hash) VALUES('mobile:admin','Mobile Admin','same@example.test','admin','unchanged-private-hash')");
  await db.query('INSERT INTO auth.users VALUES($1,$2)',[ids.admin,'same@example.test']);
  await db.query("INSERT INTO public.patag_profiles(id,name,email,role) VALUES($1,'Separate Legacy Admin','same@example.test','administrator')",[ids.admin]);
  await db.query("INSERT INTO public.patag_reports(id,title,description,road,barangay,municipality,latitude,longitude,reporter_id) VALUES($1,'Existing report','Existing description','Road','Barangay','Malolos',14.8,120.8,$2)",[ids.report,ids.admin]);
  await assert.rejects(migrate(pool,{legacyAdminEmail:'same@example.test'}),/already in use/);
  assert.equal((await db.query('SELECT email FROM public.patag_profiles WHERE id=$1',[ids.admin])).rows[0].email,'same@example.test');
  await migrate(pool,{legacyAdminEmail:'separate@example.test'});
  const mobile=(await db.query("SELECT id,email,password_hash FROM public.users WHERE id='mobile:admin'")).rows[0];
  assert.deepEqual(mobile,{id:'mobile:admin',email:'same@example.test',password_hash:'unchanged-private-hash'});
  assert.equal((await db.query('SELECT email FROM public.users WHERE id=$1',[ids.admin])).rows[0].email,'separate@example.test');
  assert.equal((await db.query('SELECT reporter_id FROM public.patag_reports WHERE id=$1',[ids.report])).rows[0].reporter_id,ids.admin);
  assert.equal((await db.query('SELECT id FROM public.users')).rows.length,2);
 }finally{await pool.end();}
});
