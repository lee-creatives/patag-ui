import { createHash } from 'node:crypto';
import { fail, fields, text, uuid } from './config.mjs';
import { audit } from './db.mjs';
import { eventInput, applyEvent, authorizeAction } from './workflow.mjs';
import { getReport, requireAdmin } from './queries.mjs';
export { bootstrap, getReport } from './queries.mjs';
export async function attachEvidence(db,reportId,photos,kind) {
  const ids=photos.map(p=>uuid(p.id));
  if(!ids.length) return;
  const {rows}=await db.query('SELECT id,report_id,kind FROM public.patag_evidence WHERE id=ANY($1::uuid[]) AND uploaded_by=$2 FOR UPDATE',[ids,db.actor.id]);
  if(rows.length!==ids.length||rows.some(p=>p.kind!==kind || (p.report_id && p.report_id!==reportId))) fail(400,'Upload your own matching evidence before attaching it.');
  await db.query('UPDATE public.patag_evidence SET report_id=$1 WHERE id=ANY($2::uuid[])',[reportId,ids]);
}
export async function reportEvent(db,id,input,key) {
  id=uuid(id);
  const value=eventInput(input),hash=createHash('sha256').update(JSON.stringify({id,...value})).digest('hex');
  authorizeAction(db.actor,value.action);
  await getReport(db,id);
  if(['duplicate','reject'].includes(value.action)) await db.query('SELECT pg_advisory_xact_lock(728194622)');
  if(key) {
    uuid(key);
    await db.query('SELECT pg_advisory_xact_lock(hashtext($1))',[`${db.actor.id}:${key}`]);
    const old=(await db.query('SELECT request_hash,response FROM public.patag_audit_events WHERE actor_id=$1 AND idempotency_key=$2',[db.actor.id,key])).rows[0];
    if(old) {if(old.request_hash!==hash) fail(409,'Idempotency key already used for another request.');return old.response;}
  }
  const locked=await db.query('SELECT id FROM public.patag_reports WHERE id=$1 FOR UPDATE',[id]);
  if(!locked.rows.length) fail(404,'Report not found in your authorized scope.');
  const report=await getReport(db,id),from=report.status;
  if(['duplicate','reject'].includes(value.action) && (await db.query('SELECT id FROM public.patag_reports WHERE duplicate_of=$1 LIMIT 1',[id])).rows.length) fail(409,'A referenced original report cannot be rejected or marked duplicate.');
  applyEvent(report,db.actor,value);
  if(value.action==='assign') {
    const {rows}=await db.query('SELECT id,municipality FROM public.patag_teams WHERE id=$1 AND active FOR SHARE',[value.teamId]);
    if(!rows[0]||rows[0].municipality.toLowerCase()!==report.location.city.toLowerCase()) fail(409,'Choose an active team in the report municipality.');
    await db.query('INSERT INTO public.patag_assignments(report_id,team_id,assigned_by,priority,note,target_date) VALUES($1,$2,$3,$4,$5,$6)',[id,value.teamId,db.actor.id,value.priority,value.note,value.targetDate||null]);
  }
  if(value.action==='duplicate') {
    if(value.duplicateOf===id) fail(400,'Choose another original report.');
    await db.query('SELECT id FROM public.patag_reports WHERE id=$1 FOR SHARE',[value.duplicateOf]);
    const original=await getReport(db,value.duplicateOf);
    if(original.location.city.toLowerCase()!==report.location.city.toLowerCase()) fail(409,'Original report must be in the same municipality.');
    if(['Rejected','Duplicate'].includes(original.status)) fail(409,'Choose an original report that is neither rejected nor duplicate.');
  }
  if(value.photos) await attachEvidence(db,id,value.photos,value.action==='before-photos'?'before':'after');
  if(value.action==='progress') await db.query('INSERT INTO public.patag_repair_updates(report_id,actor_id,phase,note,photo_ids) VALUES($1,$2,$3,$4,$5)',[id,db.actor.id,value.phase,value.note,value.photos.map(p=>p.id)]);
  if(value.action==='complete') await db.query(`INSERT INTO public.patag_completions(report_id,submitted_by,state,note,photo_ids) VALUES($1,$2,'Awaiting Verification',$3,$4)
    ON CONFLICT(report_id) DO UPDATE SET submitted_by=EXCLUDED.submitted_by,state=EXCLUDED.state,note=EXCLUDED.note,photo_ids=EXCLUDED.photo_ids,created_at=now(),updated_at=now()`,[id,db.actor.id,value.note,value.photos.map(p=>p.id)]);
  if(['return','resolve'].includes(value.action)) await db.query('UPDATE public.patag_completions SET state=$1,updated_at=now() WHERE report_id=$2',[report.completion.state,id]);
  await db.query(`UPDATE public.patag_reports SET status=$2,team_id=$3,duplicate_of=$4,flagged=$5,jurisdiction=$6,public_photos_approved=$7,updated_at=now(),version=version+1 WHERE id=$1`,[id,report.status,report.teamId,report.duplicateOf||null,report.flagged,report.jurisdiction,report.publicPhotosApproved]);
  await db.query('INSERT INTO public.patag_report_history(report_id,actor_id,actor,action,from_status,to_status,note) VALUES($1,$2,$3,$4,$5,$6,$7)',[id,db.actor.id,db.actor.name,value.action,from,report.status,value.note]);
  await db.query('SELECT patag_private.notify_report($1,$2)',[id,`${value.action==='complete'?'Repair awaiting verification':report.status}: ${report.location.road}`.slice(0,300)]);
  const result=await getReport(db,id);
  await db.query('INSERT INTO public.patag_audit_events(actor_id,action,resource_id,municipality,details,idempotency_key,request_hash,response) VALUES($1,$2,$3,$4,$5,$6,$7,$8)',[db.actor.id,value.action,id,report.location.city,JSON.stringify({from,to:report.status}),key||null,key?hash:null,key?JSON.stringify(result):null]);
  return result;
}
export async function markNotifications(db,input) {
  fields(input,['id']);
  if(input.id==='all') await db.query('UPDATE public.patag_notifications SET read=true WHERE user_id=$1',[db.actor.id]);
  else {
    const result=await db.query('UPDATE public.patag_notifications SET read=true WHERE id=$1 AND user_id=$2 RETURNING id',[uuid(input.id),db.actor.id]);
    if(!result.rows.length) fail(404,'Notification not found.');
  }
  return {ok:true};
}
export async function manageTeam(db,input,method) {
  requireAdmin(db);fields(input,['id','name','active','municipality']);
  const name=text(input.name,'team name',100);
  if(input.active!==undefined && typeof input.active!=='boolean') fail(400,'Invalid active state.');
  let result;
  if(method==='POST') {
    const municipality=db.actor.municipality || text(input.municipality || 'Bulacan','municipality',100);
    result=await db.query('INSERT INTO public.patag_teams(name,municipality,active) VALUES($1,$2,$3) RETURNING *',[name,municipality,input.active??true]);
  } else {
    const id=uuid(input.id),team=(await db.query('SELECT * FROM public.patag_teams WHERE id=$1 FOR UPDATE',[id])).rows[0];
    if(!team) fail(404,'Team not found.');
    if(input.active===false) {
      const open=await db.query("SELECT id FROM public.patag_reports WHERE team_id=$1 AND status IN ('Assigned','In Progress') LIMIT 1",[id]);
      const members=await db.query('SELECT id FROM public.patag_profiles WHERE team_id=$1 AND active LIMIT 1',[id]);
      if(open.rows.length||members.rows.length) fail(409,'Team has active members or open work.');
    }
    result=await db.query('UPDATE public.patag_teams SET name=$1,active=$2,updated_at=now() WHERE id=$3 RETURNING *',[name,input.active??team.active,id]);
  }
  const team=result.rows[0];
  if(method==='POST') await db.query('INSERT INTO public.teams(id,name,active) VALUES($1,$2,$3)',[team.id,team.name,team.active]);
  else {
    const shared=await db.query('UPDATE public.teams SET name=$1,active=$2 WHERE id=$3 RETURNING id',[team.name,team.active,team.id]);
    if(!shared.rows.length) fail(409,'Shared maintenance team is missing; reconcile before updating.');
  }
  await audit(db,'team.'+method.toLowerCase(),team.id,team.municipality);
  return {id:team.id,name:team.name,active:team.active,members:[]};
}
export async function settings(db,input) {
  requireAdmin(db);fields(input,['agency','city','province']);
  if(db.actor.municipality) fail(403,'Province-wide administrator access required.');
  if(input.province!=='Bulacan') fail(400,'The workspace province must remain Bulacan.');
  const {rows}=await db.query('UPDATE public.patag_settings SET agency=$1,city=$2,updated_at=now() WHERE id RETURNING agency,city,province',[text(input.agency,'agency',200),text(input.city,'city',100)]);
  await audit(db,'settings.update','workspace',null);return rows[0];
}
export async function exportReports(db,input) {
  requireAdmin(db);fields(input,['ids','fields','format']);
  const allowed=['Reference','Road','Barangay','Severity','Status','Submitted'];
  if(!Array.isArray(input.ids)||input.ids.length>1000||new Set(input.ids).size!==input.ids.length) fail(400,'Export at most 1,000 unique reports.');
  input.ids.forEach(uuid);
  if(!Array.isArray(input.fields)||!input.fields.length||input.fields.some(f=>!allowed.includes(f))||!['CSV','PDF'].includes(input.format)) fail(400,'Invalid export fields or format.');
  const {rows}=await db.query('SELECT id,road,barangay,severity,status,created_at FROM public.patag_reports WHERE id=ANY($1::uuid[]) ORDER BY created_at DESC,id',[input.ids]);
  if(rows.length!==input.ids.length) fail(403,'Export includes a report outside your authorized scope.');
  await audit(db,'export.'+input.format.toLowerCase(),'reports',db.actor.municipality,{count:rows.length,fields:input.fields});
  return {reports:rows.map(r=>({id:r.id,location:{road:r.road,barangay:r.barangay},severity:r.severity,status:r.status,createdAt:r.created_at instanceof Date?r.created_at.toISOString():r.created_at}))};
}
