import test from 'node:test';
import assert from 'node:assert/strict';
import {createServer} from './server.mjs';
import {transition,seed,candidates} from './domain.mjs';
test('role transitions and duplicate suggestions preserve workflow',()=>{
 const db=seed(),r=db.reports[0];assert.ok(candidates(db.reports,db.reports[4]).length);
 assert.throws(()=>transition(r,'maintenance','resolve'),/LGU verification/);
 assert.throws(()=>transition(r,'admin','assign',{teamId:'team-1'}),/not allowed/);
 transition(r,'admin','review');transition(r,'admin','verify');transition(r,'admin','assign',{teamId:'team-1'});
 assert.equal(r.status,'Assigned');transition(r,'maintenance','start');
 assert.throws(()=>transition(r,'maintenance','complete',{note:'done'}),/after photos/);
 transition(r,'maintenance','complete',{note:'Surface repaired',photos:[{id:'test',url:'/uploads/test.png'}]});
 assert.equal(r.status,'In Progress');transition(r,'admin','return',{note:'Please inspect the edge'});
 assert.equal(r.completion.state,'Additional Work Requested');transition(r,'maintenance','complete',{note:'Edge repaired',photos:[{id:'test',url:'/uploads/test.png'}]});transition(r,'admin','resolve');assert.equal(r.status,'Resolved');
 assert.equal(r.history.at(-1).action,'resolve');
});
test('HTTP cross-role flow, evidence validation, privacy, ownership, feedback and notification handoffs',async()=>{
 const server=await createServer({persist:false});await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));const base=`http://127.0.0.1:${server.address().port}/api`;
 async function call(path,body,token,method){const res=await fetch(base+path,{method:method||(body?'POST':'GET'),headers:{'Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{})},body:body?JSON.stringify(body):undefined});return {status:res.status,data:await res.json()};}
 try{
  assert.equal((await call('/bootstrap')).status,401);
  const citizen=(await call('/auth/demo',{role:'citizen'})).data.token,admin=(await call('/auth/demo',{role:'admin'})).data.token,crew=(await call('/auth/demo',{role:'maintenance'})).data.token;
  assert.equal((await call('/uploads',{data:'data:image/png;base64,dGhpcyBpcyBub3QgYSBwbmc=',name:'invalid.png'},citizen)).status,400);
  const photo=(await call('/uploads',{name:'test-evidence.png',data:'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII='},citizen)).data;
  const input={title:'Workflow test pothole',description:'Damaged outer lane',severity:'High',photos:[photo],location:{road:'Test Road',barangay:'Guinhawa',city:'Malolos',province:'Bulacan',landmark:'Test waiting shed',coordinates:{lat:14.85,lng:120.81}}};
  assert.equal((await call('/reports',{...input,photos:[]},citizen)).status,400);
  const created=await call('/reports',input,citizen);assert.equal(created.status,201);assert.equal(created.data.status,'Submitted');const id=created.data.id;
  assert.equal((await call('/reports/'+id,undefined,crew)).status,403);
  const event=(action,payload={},token=admin)=>call(`/reports/${id}/events`,{action,...payload},token);
  assert.equal((await event('assign',{teamId:'team-1'})).status,409);
  assert.equal((await event('verify')).data.status,'Verified');await event('assign',{teamId:'team-1',note:'Inspect the outer lane'});
  assert.ok((await call('/bootstrap',undefined,crew)).data.reports.some(r=>r.id===id));
  const beforeCount=created.data.photos.length;
  const before=await event('before-photos',{photos:[photo]},crew);assert.equal(before.status,200);assert.equal(before.data.photos.length,beforeCount+1);assert.equal(before.data.status,'Assigned');
  await event('start',{},crew);await event('progress',{note:'Site prepared'},crew);
  assert.equal((await event('resolve',{},crew)).status,409);
  assert.equal((await event('complete',{note:'Repaired'},crew)).status,400);
  const completion=await event('complete',{note:'Repaired with compacted base and asphalt patch',photos:[photo]},crew);assert.equal(completion.data.status,'In Progress');assert.equal(completion.data.completion.state,'Awaiting Verification');
  assert.equal((await event('resolve')).data.status,'Resolved');
  assert.equal((await call(`/reports/${id}/feedback`,{rating:5,text:'Road is smooth again.'},citizen)).status,201);
  assert.equal((await call(`/reports/${id}/feedback`,{rating:5,text:'repeat'},citizen)).status,409);
  const pub=(await call('/public/reports')).data.find(r=>r.id===id);assert.equal(pub.reporterId,undefined);assert.equal(pub.assignment,undefined);
  assert.ok((await call('/bootstrap',undefined,citizen)).data.notifications.some(n=>n.reportId===id));
 }finally{await new Promise(resolve=>server.close(resolve));}
});
