import test from 'node:test';
import assert from 'node:assert/strict';
import {createServer} from './server.mjs';
import {seed,publicReport,transition,candidates} from './domain.mjs';
import {publicReport as previewPublicReport} from '../browser-preview/domain.mjs';

test('PDF constraint 6: public projections omit private notes and future private fields',()=>{
 const r=seed().reports.find(r=>r.completion);
 r.description='Private contact 09123456789';r.title='Reporter name';r.feedback={text:'Call me privately'};r.internalSecret='hidden';r.updates=[{note:'Staff contact'}];
 r.history.push({id:'private',at:r.updatedAt,action:'flag',from:r.status,to:r.status,note:'Private contact',actor:'Staff name'});
 r.completion.note='Private repair contact';r.location.landmark='Reporter house';r.photos[0].name='reporter-name.png';
 for(const project of [publicReport,previewPublicReport]){
  const p=project(r);const text=JSON.stringify(p);
  for(const key of ['reporterId','assignment','teamId','feedback','updates','internalSecret','flagged','jurisdiction'])assert.equal(p[key],undefined,key);
  for(const value of ['09123456789','Staff name','Private repair contact','Reporter house','reporter-name.png'])assert.ok(!text.includes(value),value);
  assert.ok(p.photos.length);assert.equal(p.status,r.status);assert.ok(p.history.every(h=>!('actor' in h)));assert.ok(p.completion.photos.length);
 }
});

test('PDF workflow: invalid transitions, forwarding and duplicate confirmation stay explicit',()=>{
 const db=seed(),r=db.reports[0];
 assert.throws(()=>transition(r,'citizen','verify'));
 assert.throws(()=>transition(r,'admin','resolve'));
 assert.throws(()=>transition(r,'admin','reject',{note:''}));
 transition(r,'admin','forward',{jurisdiction:'Provincial road office',note:'Jurisdiction check'});
 assert.equal(r.jurisdiction,'Provincial road office');assert.equal(r.status,'Submitted');
 transition(r,'admin','flag',{note:'Inspect evidence'});assert.equal(r.flagged,true);
 assert.throws(()=>transition(r,'admin','duplicate',{duplicateOf:r.id}));
 transition(r,'admin','duplicate',{duplicateOf:db.reports[1].id});assert.equal(r.status,'Duplicate');
 assert.equal(candidates(db.reports,{...db.reports[1],id:'new',location:{...db.reports[1].location,coordinates:{lat:0,lng:0}}}).length,0);
});

test('PDF FR-01 and role ownership: real registration/login, rejection and notification isolation',async()=>{
 const server=await createServer({persist:false});await new Promise(r=>server.listen(0,'127.0.0.1',r));
 const base=`http://127.0.0.1:${server.address().port}/api`;
 async function call(path,body,token,method){const r=await fetch(base+path,{method:method||(body?'POST':'GET'),headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},body:body?JSON.stringify(body):undefined});return {status:r.status,data:await r.json()};}
 try{
  const input={name:'Audit Citizen',email:'audit@example.test',password:'Audit-Test-12345',address:{line:'',barangay:'Guinhawa',city:'Malolos',province:'Bulacan'}};
  assert.equal((await call('/auth/register',{...input,password:'short'})).status,400);
  const registered=await call('/auth/register',input);assert.equal(registered.status,201);const token=registered.data.token;
  assert.equal(registered.data.user.hash,undefined);assert.equal(registered.data.user.salt,undefined);
  assert.equal((await call('/auth/register',input)).status,409);
  assert.equal((await call('/auth/login',{email:input.email,password:'wrong'})).status,401);
  assert.equal((await call('/auth/login',input)).status,200);
  assert.equal((await call('/reports/PTG-2026-0101',undefined,token)).status,403);
  assert.equal((await call('/reports/PTG-2026-0101/feedback',{rating:5,text:'not mine'},token)).status,403);
  const bootstrap=await call('/bootstrap',undefined,token);assert.equal(bootstrap.data.reports.length,0);assert.equal(bootstrap.data.notifications.length,0);assert.equal(bootstrap.data.users.length,0);
  const updated=await call('/me',{name:input.name,email:input.email,address:{line:'12 Mabini',barangay:'Guinhawa',city:'Malolos',province:'Bulacan'}},token,'PATCH');assert.equal(updated.status,200);assert.equal(updated.data.address.line,'12 Mabini');assert.equal((await call('/me',{name:input.name,email:input.email,address:{barangay:'',city:'Malolos',province:'Bulacan'}},token,'PATCH')).status,400);assert.ok(!(JSON.stringify((await call('/public/reports')).data)).includes('12 Mabini'));
  assert.equal((await call('/users',{id:'admin-1',active:false},token,'PATCH')).status,403);
  await call('/auth/logout',{},token);assert.equal((await call('/bootstrap',undefined,token)).status,401);
 }finally{await new Promise(r=>server.close(r));}
});

test('workspace settings, crew provisioning and public photo approval connect across roles',async()=>{
 const server=await createServer({persist:false});await new Promise(r=>server.listen(0,'127.0.0.1',r));const base=`http://127.0.0.1:${server.address().port}/api`;
 async function call(path,body,token,method){const r=await fetch(base+path,{method:method||(body?'POST':'GET'),headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},body:body?JSON.stringify(body):undefined});return {status:r.status,data:await r.json()};}
 try{
  const admin=(await call('/auth/demo',{role:'admin'})).data.token,citizen=(await call('/auth/demo',{role:'citizen'})).data.token;
  assert.equal((await call('/settings',{agency:'Office',city:'Malolos',province:'Bulacan'},citizen,'PATCH')).status,403);
  assert.equal((await call('/settings',{agency:'Office',city:'Malolos',province:'Bulacan'},admin,'PATCH')).status,200);
  assert.equal((await call('/bootstrap',undefined,citizen)).data.settings.agency,'Office');
  const team=(await call('/teams',{name:'Audit team',active:true},admin)).data;
  assert.equal((await call('/users',{name:'Crew Test',email:'crew-test@example.test',password:'Preview-Test-123',role:'maintenance'},admin)).status,400);
  const account=await call('/users',{name:'Crew Test',email:'crew-test@example.test',password:'Preview-Test-123',role:'maintenance',teamId:team.id},admin);assert.equal(account.status,201);assert.equal(account.data.hash,undefined);
  const crew=(await call('/auth/login',{email:'crew-test@example.test',password:'Preview-Test-123'})).data.token;assert.ok(crew);
  const id='PTG-2026-0103';assert.equal((await call(`/reports/${id}/events`,{action:'assign',teamId:team.id},admin)).status,200);
  assert.ok((await call('/bootstrap',undefined,crew)).data.reports.some(r=>r.id===id));
  assert.equal((await call('/teams',{id:team.id,name:team.name,active:false},admin,'PATCH')).status,409);
  const upload=(await call('/uploads',{data:'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',name:'private.png'},crew)).data;
  await call(`/reports/${id}/events`,{action:'before-photos',photos:[upload]},crew);
  const publicPhotos=async()=>((await call('/public/reports')).data.find(r=>r.id===id).photos);
  assert.ok(!(await publicPhotos()).some(p=>p.url===upload.url));
  assert.equal((await call(`/reports/${id}/events`,{action:'publication',approved:true},crew)).status,409);
  assert.equal((await call(`/reports/${id}/events`,{action:'publication',approved:true},admin)).status,200);
  assert.ok((await publicPhotos()).some(p=>p.url===upload.url));
  await call(`/reports/${id}/events`,{action:'publication',approved:false},admin);assert.ok(!(await publicPhotos()).some(p=>p.url===upload.url));
 }finally{await new Promise(r=>server.close(r));}
});

test('registration normalization, portal restriction, session revocation and throttling',async()=>{
 const server=await createServer({persist:false,allowDemo:false});await new Promise(r=>server.listen(0,'127.0.0.1',r));
 const base=`http://127.0.0.1:${server.address().port}/api`;
 const call=async(p,body,token)=>{const r=await fetch(base+p,{method:body?'POST':'GET',headers:{'Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{})},body:body?JSON.stringify(body):undefined});return {status:r.status,data:await r.json()};};
 try{
  assert.equal((await call('/auth/demo',{role:'admin'})).status,404);
  const input={name:'  Test Reporter  ',email:'  NORMALIZED@example.test ',password:'Several roads lead home!',address:{line:' 12 Mabini St ',barangay:' Guinhawa ',city:' Malolos ',province:' Bulacan '},role:'admin',active:false,teamId:'team-1'};
  assert.equal((await call('/auth/register',{...input,address:{}})).status,400);
  const created=await call('/auth/register',input);assert.equal(created.status,201);assert.deepEqual(created.data.user.address,{line:'12 Mabini St',barangay:'Guinhawa',city:'Malolos',province:'Bulacan'});assert.equal(created.data.user.role,'citizen');assert.equal(created.data.user.email,'normalized@example.test');assert.equal(created.data.user.active,true);assert.equal(created.data.user.teamId,undefined);assert.equal(created.data.user.emailVerified,false);
  assert.equal((await call('/auth/register',{...input,email:'normalized@example.test'})).status,409);
  assert.equal((await call('/auth/login',{email:'NORMALIZED@EXAMPLE.TEST',password:input.password,role:'admin'})).status,401);
  const login=await call('/auth/login',{email:'NORMALIZED@EXAMPLE.TEST',password:input.password,role:'citizen'});assert.equal(login.status,200);
  assert.equal((await call('/bootstrap',null,'preview:'+created.data.user.id+':forged')).status,401);
  await call('/auth/logout',{},login.data.token);assert.equal((await call('/bootstrap',null,login.data.token)).status,401);
  let last;for(let i=0;i<21;i++)last=await call('/auth/login',{email:'absent@example.test',password:'wrong'});assert.equal(last.status,429);
 }finally{await new Promise(r=>server.close(r));}
});
