import test from 'node:test';
import assert from 'node:assert/strict';
import { database,fixtures,ids } from './database.mjs';
import { transaction } from '../db.mjs';
import { uploadEvidence,evidenceRecord,imageInput,storageClient } from '../evidence.mjs';
import { reportEvent,getReport } from '../service.mjs';
const claims=id=>({sub:id});
const image={data:'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',name:'test.png',kind:'after'};
test('private evidence ownership, canonical lifecycle, and upload rollback cleanup',async()=>{
 const pool=await database();const objects=new Map();let removes=0;
 const storage={upload:async(path,bytes)=>objects.set(path,bytes),remove:async path=>{removes++;objects.delete(path);}};
 try {
  await fixtures(pool.db);
  await transaction(pool,c=>reportEvent(c,ids.report,{action:'verify'}),claims(ids.admin));
  await transaction(pool,c=>reportEvent(c,ids.report,{action:'assign',teamId:ids.team}),claims(ids.admin));
  await transaction(pool,c=>reportEvent(c,ids.report,{action:'start'}),claims(ids.crew));
  const foreign=await uploadEvidence(pool,claims(ids.admin),image,storage);
  const beforeCount=(await pool.db.query('SELECT count(*)::integer AS n FROM public.patag_report_history')).rows[0].n;
  await assert.rejects(transaction(pool,c=>reportEvent(c,ids.report,{action:'complete',note:'Foreign evidence',photos:[foreign]}),claims(ids.crew)),e=>e.status===400);
  assert.equal((await pool.db.query('SELECT count(*)::integer AS n FROM public.patag_report_history')).rows[0].n,beforeCount);
  assert.equal((await transaction(pool,c=>getReport(c,ids.report),claims(ids.admin))).status,'In Progress');
  const photo=await uploadEvidence(pool,claims(ids.crew),image,storage);
  await assert.rejects(transaction(pool,c=>evidenceRecord(c,photo.id),claims(ids.other)),e=>e.status===404);
  await transaction(pool,c=>reportEvent(c,ids.report,{action:'complete',note:'Patch compacted',photos:[photo]}),claims(ids.crew));
  const pending=await transaction(pool,c=>getReport(c,ids.report),claims(ids.admin));assert.equal(pending.status,'In Progress');assert.equal(pending.completion.photos.length,1);assert.equal(pending.photos.length,0);
  await assert.rejects(transaction(pool,c=>reportEvent(c,ids.report,{action:'progress',phase:'Repair',note:'Too soon'}),claims(ids.crew)),e=>e.status===409);
  await transaction(pool,c=>reportEvent(c,ids.report,{action:'return',note:'Inspect edge'}),claims(ids.admin));
  await transaction(pool,c=>reportEvent(c,ids.report,{action:'complete',note:'Edge corrected',photos:[photo]}),claims(ids.crew));
  const resolved=await transaction(pool,c=>reportEvent(c,ids.report,{action:'resolve'}),claims(ids.admin));assert.equal(resolved.status,'Resolved');
  await pool.db.query('UPDATE public.users SET active=false WHERE id=$1',[ids.crew]);
  await assert.rejects(uploadEvidence(pool,claims(ids.crew),image,storage),e=>e.status===403);assert.equal(removes,1);assert.equal(objects.size,2);
  assert.throws(()=>imageInput({...image,data:'data:image/png;base64,ZmFrZSBpbWFnZSBkYXRh'}),e=>e.status===400);
 }finally{await pool.end();}
});
test('Storage cleanup uses the documented prefixes API and private download endpoint',async()=>{
 const requests=[];
 const storage=storageClient({url:'https://test.supabase.co',serviceKey:'server-test-key'},async(url,options)=>{requests.push({url,...options});return new Response('{}');});
 await storage.remove('owner/file');await storage.download('owner/file');
 assert.ok(requests[0].url.endsWith('/storage/v1/object/patag-evidence'));assert.deepEqual(JSON.parse(requests[0].body),{prefixes:['owner/file']});
 assert.ok(requests[1].url.endsWith('/storage/v1/object/authenticated/patag-evidence/owner/file'));
});
