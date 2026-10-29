import { fail, fields, text, email, accountId } from './config.mjs';
import { transaction, audit, publicUser } from './db.mjs';
import { requireAdmin, page } from './queries.mjs';
export function roleValue(value) {
  if(!['admin','maintenance','citizen'].includes(value)) fail(400,'Invalid account role.');
  return value;
}
async function accountFields(db,input,current) {
  const role=roleValue(input.role);
  if(typeof input.active!=='boolean') fail(400,'Invalid active state.');
  if(db.actor.municipality && (role==='admin'||current?.role==='admin')) fail(403,'Only a province-wide administrator may manage administrator accounts.');
  let teamId=null;
  if(role==='maintenance') {
    teamId=accountId(input.teamId===undefined?current?.team_id:input.teamId);
    const preservingDisabledMembership=current?.role==='maintenance'&&current.team_id===teamId&&!input.active;
    if(!preservingDisabledMembership && db.actor.municipality && !(await db.query('SELECT id FROM public.patag_teams WHERE id::text=$1 AND active',[teamId])).rows[0]) fail(403,'Team jurisdiction is not verified for this administrator.');
    if(!preservingDisabledMembership && !(await db.query('SELECT id FROM public.teams WHERE id=$1 AND active FOR SHARE',[teamId])).rows[0]) fail(400,'Choose an active shared maintenance team.');
  } else if(input.teamId) fail(400,'Only maintenance accounts may have a team.');
  const municipality=input.municipality===undefined?current?.address?.city??db.actor.municipality:input.municipality===null?null:text(input.municipality,'municipality',100);
  if(db.actor.municipality && municipality?.toLowerCase()!==db.actor.municipality.toLowerCase()) fail(403,'Account municipality is outside your scope.');
  return {role,teamId,municipality,active:input.active};
}
export async function provisionUser(pool,context,input) {
  fields(input,['name','email','role','teamId','active','municipality']);
  const name=text(input.name,'name',100),mail=email(input.email);
  return transaction(pool,async db=>{
    requireAdmin(db);const value=await accountFields(db,input);
    await db.query('SELECT pg_advisory_xact_lock(hashtext($1))',[mail]);
    if((await db.query('SELECT id FROM public.users WHERE lower(email)=$1',[mail])).rows.length) fail(409,'An account with these details already exists.');
    const {rows}=await db.query('INSERT INTO public.users(name,email,role,active,team_id,address) VALUES($1,$2,$3,$4,$5,$6) RETURNING *',[name,mail,value.role,value.active,value.teamId,JSON.stringify({city:value.municipality,province:'Bulacan'})]);
    await audit(db,'user.create',rows[0].id,value.municipality,{role:value.role,active:value.active});
    return publicUser(rows[0]);
  },context);
}
export async function listUsers(db,input={}) {
  requireAdmin(db);fields(input,['q','role','active','limit','offset']);
  const {limit,offset}=page(input),values=[],where=[];
  const add=(sql,value)=>{values.push(value);where.push(sql.replace('?', '$'+values.length));};
  if(input.q!==undefined) add("strpos(lower(concat_ws(' ',name,email,id)),lower(?))>0",text(input.q,'search',100,false));
  if(input.role!==undefined) add('role=?',roleValue(input.role));
  if(input.active!==undefined) {if(!['true','false'].includes(input.active)) fail(400,'Invalid account status.');add('active=?',input.active==='true');}
  values.push(limit+1,offset);
  const {rows}=await db.query('SELECT id,name,email,role,active,team_id FROM public.users'+(where.length?' WHERE '+where.join(' AND '):'')+' ORDER BY id LIMIT $'+(values.length-1)+' OFFSET $'+values.length,values);
  return {users:rows.slice(0,limit).map(publicUser),nextOffset:rows.length>limit?offset+limit:null};
}
export async function getUser(db,id) {
  requireAdmin(db);const row=(await db.query('SELECT id,name,email,role,active,team_id FROM public.users WHERE id=$1',[accountId(id)])).rows[0];
  if(!row) fail(404,'Account not found.');return publicUser(row);
}
export async function updateUser(db,input) {
  requireAdmin(db);fields(input,['id','role','active','teamId','municipality']);
  const id=accountId(input.id);
  if(id===db.actor.id) fail(409,'You cannot change your own access.');
  const current=(await db.query('SELECT * FROM public.users WHERE id=$1 FOR UPDATE',[id])).rows[0];
  if(!current) fail(404,'Account not found.');
  if(input.municipality!==undefined && current.address!==null && (typeof current.address!=='object'||Array.isArray(current.address))) fail(400,'Existing address requires explicit reconciliation before a municipality change.');
  const value=await accountFields(db,input,current);
  const {rows}=await db.query("UPDATE public.users SET role=$1,active=$2,team_id=$3,address=CASE WHEN $6 THEN jsonb_set(coalesce(address,'{}'),'{city}',$4::jsonb) ELSE address END,updated_at=now() WHERE id=$5 RETURNING *",[value.role,value.active,value.teamId,JSON.stringify(value.municipality??null),id,input.municipality!==undefined]);
  if(!value.active||value.role!==current.role) await db.query('SELECT patag_private.revoke_account_sessions($1)',[id]);
  await audit(db,'user.update',id,current.address?.city??null,{role:value.role,active:value.active});return publicUser(rows[0]);
}
export async function updateMe(db,input) {
  fields(input,['name','email']);
  if(email(input.email)!==db.actor.email.toLowerCase()) fail(400,'Email changes require a separately verified recovery workflow.');
  const {rows}=await db.query('UPDATE public.users SET name=$1,updated_at=now() WHERE id=$2 RETURNING *',[text(input.name,'name',100),db.actor.id]);
  if(!rows[0]) fail(403,'Profile update is not authorized.');
  await audit(db,'profile.update',db.actor.id,db.actor.municipality);return publicUser(rows[0]);
}

export async function accountTeams(db) {
  requireAdmin(db);
  return (await db.query('SELECT t.id,t.name,t.active FROM public.teams t WHERE t.active'+(db.actor.municipality?' AND EXISTS(SELECT 1 FROM public.patag_teams p WHERE p.id::text=t.id AND p.active)':'')+' ORDER BY t.id LIMIT 100')).rows;
}
