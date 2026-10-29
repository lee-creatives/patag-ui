import test from 'node:test';
import assert from 'node:assert/strict';
import { database, fixtures, ids } from './database.mjs';
import { transaction } from '../db.mjs';
import { provisionUser, listUsers, getUser, updateUser, accountTeams } from '../accounts.mjs';
import { manageTeam } from '../service.mjs';
const actor={sub:ids.admin};
test('shared PostgreSQL accounts are readable without any Auth identity and preserve text IDs',async()=>{
 const pool=await database();
 try {
  await fixtures(pool.db);
  await pool.db.query("INSERT INTO public.users(id,name,email,role,active,address,password_hash) VALUES('mobile:existing-1','Mobile Account','mobile@example.test','citizen',true,'{\"city\":\"Malolos\",\"province\":\"Bulacan\"}','private-existing-hash')");
  const result=await transaction(pool,db=>listUsers(db,{q:'mobile',role:'citizen',active:'true',limit:'1',offset:'0'}),actor);
  assert.equal(result.users.length,1);assert.equal(result.users[0].id,'mobile:existing-1');
  const detail=await transaction(pool,db=>getUser(db,'mobile:existing-1'),actor);
  assert.equal(detail.email,'mobile@example.test');assert.equal(detail.password_hash,undefined);
  await transaction(pool,db=>updateUser(db,{id:detail.id,role:'citizen',active:false}),actor);
  assert.equal((await pool.db.query("SELECT active,password_hash FROM public.users WHERE id=$1",[detail.id])).rows[0].active,false);
  assert.equal((await pool.db.query("SELECT password_hash FROM public.users WHERE id=$1",[detail.id])).rows[0].password_hash,'private-existing-hash');
  await pool.db.query("UPDATE public.users SET address='null'::jsonb WHERE id=$1",[detail.id]);
  await transaction(pool,db=>updateUser(db,{id:detail.id,role:'citizen',active:true}),actor);
  assert.equal((await pool.db.query('SELECT address FROM public.users WHERE id=$1',[detail.id])).rows[0].address,null);
  await pool.db.exec('DROP SCHEMA auth CASCADE');
  assert.equal((await transaction(pool,db=>getUser(db,detail.id),actor)).id,detail.id);
 }finally{await pool.end();}
});
test('admin creates one shared row; duplicates and untrusted fields fail safely',async()=>{
 const pool=await database();
 try {
  await fixtures(pool.db);
  const input={name:'Shared New',email:'NEW@example.test',role:'citizen',active:true};
  const created=await provisionUser(pool,actor,input);
  assert.equal((await pool.db.query('SELECT id FROM public.users WHERE id=$1',[created.id])).rows.length,1);
  assert.equal((await pool.db.query('SELECT password_hash FROM public.users WHERE id=$1',[created.id])).rows[0].password_hash,null);
  await assert.rejects(provisionUser(pool,actor,{...input,email:'new@example.test'}),e=>e.status===409||e.code==='23505');
  await assert.rejects(provisionUser(pool,actor,{...input,password:'unrequested secret'}),e=>e.status===400);
  for(const query of [{role:'owner'},{active:'maybe'},{limit:'NaN'},{offset:'-1'},{q:'x'.repeat(101)}]) await assert.rejects(transaction(pool,db=>listUsers(db,query),actor),e=>e.status===400);
  const first=await transaction(pool,db=>listUsers(db,{limit:2}),actor);
  const next=await transaction(pool,db=>listUsers(db,{limit:2,offset:first.nextOffset}),actor);
  assert.equal(new Set([...first.users,...next.users].map(u=>u.id)).size,4);
 }finally{await pool.end();}
});

test('team creation and edits stay compatible with shared account membership and municipality scope',async()=>{
 const pool=await database();
 try {
  await fixtures(pool.db);
  const team=await transaction(pool,db=>manageTeam(db,{name:'Shared Created Crew',municipality:'Baliwag',active:true},'POST'),actor);
  const user=await provisionUser(pool,actor,{name:'Shared Crew',email:'shared-crew@example.test',role:'maintenance',teamId:team.id,municipality:'Baliwag',active:true});
  assert.equal(user.teamId,team.id);
  assert.equal((await transaction(pool,accountTeams,{sub:ids.local})).some(t=>t.id===team.id),false);
  await assert.rejects(provisionUser(pool,{sub:ids.local},{name:'Wrong Crew',email:'wrong-crew@example.test',role:'maintenance',teamId:team.id,active:true}),e=>e.status===403);
  await pool.db.query("INSERT INTO public.teams(id,name) VALUES('shared:no-jurisdiction','Unmapped Team')");
  await assert.rejects(provisionUser(pool,{sub:ids.local},{name:'Unknown Crew',email:'unknown-crew@example.test',role:'maintenance',teamId:'shared:no-jurisdiction',active:true}),e=>e.status===403);
  await transaction(pool,db=>manageTeam(db,{id:team.id,name:'Renamed Shared Crew',active:true},'PATCH'),actor);
  assert.equal((await pool.db.query('SELECT name FROM public.teams WHERE id=$1',[team.id])).rows[0].name,'Renamed Shared Crew');
  await transaction(pool,db=>updateUser(db,{id:user.id,role:'maintenance',teamId:team.id,active:false}),actor);
  await transaction(pool,db=>manageTeam(db,{id:team.id,name:'Renamed Shared Crew',active:false},'PATCH'),actor);
  assert.equal((await pool.db.query('SELECT active FROM public.teams WHERE id=$1',[team.id])).rows[0].active,false);
  await pool.db.query('UPDATE public.users SET active=true WHERE id=$1',[user.id]);
  const disabled=await transaction(pool,db=>updateUser(db,{id:user.id,role:'maintenance',active:false}),actor);
  assert.equal(disabled.active,false);assert.equal(disabled.teamId,team.id);
  await assert.rejects(transaction(pool,db=>updateUser(db,{id:user.id,role:'maintenance',teamId:team.id,active:true}),actor),e=>e.status===400);
 }finally{await pool.end();}
});
