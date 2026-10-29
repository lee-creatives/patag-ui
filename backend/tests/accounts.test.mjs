import test from 'node:test';
import assert from 'node:assert/strict';
import { database,fixtures,ids } from './database.mjs';
import { transaction } from '../db.mjs';
import { bootstrap } from '../service.mjs';
import { provisionUser,updateUser,updateMe } from '../accounts.mjs';
const claims=id=>({sub:id});
test('account management uses protected roles, team scope and safe response fields',async()=>{
 const pool=await database();
 try {
  await fixtures(pool.db);
  await assert.rejects(provisionUser(pool,claims(ids.local),{name:'Test Admin',email:'new@example.test',role:'admin',active:true}),e=>e.status===403);
  const user=await provisionUser(pool,claims(ids.admin),{name:'Test Crew Member',email:'new@example.test',role:'maintenance',teamId:ids.team,active:true});
  assert.equal(user.role,'maintenance');assert.equal(user.teamId,ids.team);assert.equal(user.password,undefined);assert.equal(user.hash,undefined);
  await assert.rejects(transaction(pool,c=>updateUser(c,{id:ids.admin,role:'citizen',active:false}),claims(ids.admin)),e=>e.status===409);
  await assert.rejects(transaction(pool,c=>updateUser(c,{id:ids.other,role:'citizen',active:false}),claims(ids.local)),e=>e.status===404);
  await assert.rejects(transaction(pool,c=>updateMe(c,{name:'Test',email:'changed@example.test'}),claims(ids.admin)),e=>e.status===400);
  const disabled=await transaction(pool,c=>updateUser(c,{id:user.id,role:'maintenance',teamId:ids.team,active:false}),claims(ids.admin));assert.equal(disabled.active,false);
 }finally{await pool.end();}
});
test('bootstrap pagination bounds every collection and supports empty trailing pages',async()=>{
 const pool=await database();
 try {
  await fixtures(pool.db);
  await pool.db.query("INSERT INTO public.patag_reports(title,description,road,barangay,municipality,latitude,longitude,reporter_id) SELECT 'Report '||n,'Test description','Test Road','Test Barangay','Malolos',14.855,120.815,$1 FROM generate_series(1,103) n",[ids.citizen]);
  const first=await transaction(pool,c=>bootstrap(c,{limit:100}),claims(ids.admin));assert.equal(first.reports.length,100);assert.equal(first.nextOffset,100);
  const second=await transaction(pool,c=>bootstrap(c,{offset:100}),claims(ids.admin));assert.equal(second.reports.length,5);assert.equal(second.nextOffset,null);
  assert.equal(new Set([...first.reports,...second.reports].map(r=>r.id)).size,105);
 }finally{await pool.end();}
});
