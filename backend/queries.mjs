import { fail, text, uuid, statuses } from './config.mjs';
import { publicUser } from './db.mjs';
export const requireAdmin = db => { if(db.actor.role!=='administrator') fail(403,'Administrator access required.'); };
export function page(input={}) {
  const limit=Number(input.limit ?? 100),offset=Number(input.offset ?? 0);
  if (!Number.isInteger(limit)||limit<1||limit>100||!Number.isInteger(offset)||offset<0||offset>100000) fail(400,'Invalid pagination.');
  return {limit,offset};
}
export const reportSelect = `SELECT r.*, a.team_id AS assigned_team, a.priority, a.note AS assignment_note, a.target_date, a.created_at AS assigned_at,
  (SELECT h.created_at FROM public.patag_report_history h WHERE h.report_id=r.id AND h.action='resolve' AND h.to_status='Resolved' ORDER BY h.created_at LIMIT 1) AS resolved_at,
  c.state AS completion_state,c.note AS completion_note,c.photo_ids AS completion_photos,c.created_at AS completed_at,
  coalesce((SELECT jsonb_agg(x) FROM (SELECT e.id,'/evidence/'||e.id AS url,e.name,e.kind FROM public.patag_evidence e WHERE e.report_id=r.id AND e.id=ANY(c.photo_ids) ORDER BY e.created_at LIMIT 10) x),'[]') AS completion_photo_objects,
  coalesce((SELECT jsonb_agg(x) FROM (SELECT e.id, '/evidence/'||e.id AS url, e.name,e.kind FROM public.patag_evidence e WHERE e.report_id=r.id AND e.kind='before' ORDER BY e.created_at LIMIT 100) x),'[]') AS photos,
  coalesce((SELECT jsonb_agg(x) FROM (SELECT h.id,h.created_at AS at,h.actor,h.action,h.from_status AS from,h.to_status AS to,h.note FROM public.patag_report_history h WHERE h.report_id=r.id ORDER BY h.created_at DESC,h.id LIMIT 200) x),'[]') AS history,
  coalesce((SELECT jsonb_agg(x) FROM (SELECT u.created_at AS at,u.phase,u.note,coalesce((SELECT jsonb_agg(x) FROM (SELECT e.id,'/evidence/'||e.id AS url,e.name,e.kind FROM public.patag_evidence e WHERE e.report_id=r.id AND e.id=ANY(u.photo_ids) ORDER BY e.created_at LIMIT 10) x),'[]') AS photos FROM public.patag_repair_updates u WHERE u.report_id=r.id ORDER BY u.created_at DESC,u.id LIMIT 100) x),'[]') AS updates
  FROM public.patag_reports r LEFT JOIN public.patag_assignments a ON a.report_id=r.id LEFT JOIN public.patag_completions c ON c.report_id=r.id`;
const iso=value=>value instanceof Date?value.toISOString():value;
export function reportModel(r) {
  return {id:r.id,title:r.title,description:r.description,hazards:r.hazards,severity:r.severity,status:r.status,
    createdAt:iso(r.created_at),updatedAt:iso(r.updated_at),resolvedAt:iso(r.resolved_at),location:{road:r.road,barangay:r.barangay,city:r.municipality,province:r.province,landmark:r.landmark,coordinates:{lat:r.latitude,lng:r.longitude}},
    reporterId:r.reporter_id,jurisdiction:r.jurisdiction,teamId:r.team_id,flagged:r.flagged,publicPhotosApproved:r.public_photos_approved,duplicateOf:r.duplicate_of ?? undefined,
    photos:r.photos,history:r.history.reverse(),updates:r.updates.reverse().map(u=>({at:u.at,phase:u.phase,note:u.note,photos:u.photos})),feedback:null,
    assignment:r.assigned_team?{teamId:r.assigned_team,priority:r.priority,note:r.assignment_note,targetDate:r.target_date?iso(r.target_date).slice(0,10):null,at:iso(r.assigned_at)}:null,
    completion:r.completion_state?{state:r.completion_state,note:r.completion_note,photos:r.completion_photo_objects,at:iso(r.completed_at)}:null};
}
export async function getReport(db,id) {
  const {rows}=await db.query(reportSelect+' WHERE r.id=$1',[uuid(id)]);
  if(!rows[0]) fail(404,'Report not found in your authorized scope.');
  return reportModel(rows[0]);
}
export async function listReports(db,input={}) {
  const {limit,offset}=page(input),values=[],where=[];
  const add=(sql,value)=>{values.push(value);where.push(sql.replace('?',`$${values.length}`));};
  for(const [key,column,allowed] of [['status','status',statuses],['severity','severity',['Low','Medium','High']]]) {
    if(input[key] && input[key]!=='All') {if(!allowed.includes(input[key])) fail(400,`Invalid ${key}.`);add(`r.${column}=?`,input[key]);}
  }
  for(const [key,column] of [['municipality','municipality'],['barangay','barangay'],['teamId','team_id']]) if(input[key]) add(`r.${column}=?`,key==='teamId'?uuid(input[key]):text(input[key],key,100));
  if(input.q) add("strpos(lower(concat_ws(' ',r.title,r.road,r.barangay,r.municipality,r.id)),lower(?))>0",text(input.q,'search',100));
  for(const [key,operator] of [['from','>='],['to','<=']]) if(input[key]) {
    if(!/^\d{4}-\d{2}-\d{2}$/.test(input[key])||!Number.isFinite(Date.parse(input[key]))) fail(400,'Invalid date filter.');
    add(`r.created_at::date ${operator} ?::date`,input[key]);
  }
  const sorts={newest:'r.created_at DESC,r.id',oldest:'r.created_at,r.id',severity:"CASE r.severity WHEN 'High' THEN 0 WHEN 'Medium' THEN 1 ELSE 2 END,r.created_at DESC,r.id"};
  const sort=Object.hasOwn(sorts,input.sort??'newest')?sorts[input.sort??'newest']:null;
  if(!sort) fail(400,'Invalid sort field.');
  values.push(limit+1,offset);
  const {rows}=await db.query(reportSelect+(where.length?' WHERE '+where.join(' AND '):'')+` ORDER BY ${sort} LIMIT $${values.length-1} OFFSET $${values.length}`,values);
  return {reports:rows.slice(0,limit).map(reportModel),more:rows.length>limit};
}
export async function bootstrap(db,input) {
  const {limit,offset}=page(input),reports=await listReports(db,input);
  const teams=await db.query(`SELECT t.*,coalesce((SELECT array_agg(p.name ORDER BY p.name) FROM public.patag_profiles p WHERE p.team_id=t.id::text AND p.active),'{}') AS members FROM public.patag_teams t ORDER BY t.id LIMIT $1 OFFSET $2`,[limit+1,offset]);
  const users=db.actor.role==='administrator'?await db.query('SELECT * FROM public.patag_profiles ORDER BY id LIMIT $1 OFFSET $2',[limit+1,offset]):{rows:[]};
  const notifications=await db.query('SELECT id,report_id AS "reportId",title,read,created_at AS at FROM public.patag_notifications ORDER BY created_at DESC,id LIMIT $1 OFFSET $2',[limit+1,offset]);
  const settings=(await db.query('SELECT agency,city,province FROM public.patag_settings WHERE id')).rows[0];
  return {reports:reports.reports,teams:teams.rows.slice(0,limit).map(t=>({id:t.id,name:t.name,active:t.active,members:t.members})),users:users.rows.slice(0,limit).map(publicUser),notifications:notifications.rows.slice(0,limit),settings,user:publicUser(db.actor),demo:false,statuses,
    nextOffset:reports.more||[teams,users,notifications].some(r=>r.rows.length>limit)?offset+limit:null};
}
export async function statistics(db) {
  requireAdmin(db);
  const status=(await db.query('SELECT status,count(*)::integer AS count FROM public.patag_reports GROUP BY status')).rows;
  const severity=(await db.query('SELECT severity,count(*)::integer AS count FROM public.patag_reports GROUP BY severity')).rows;
  const municipality=(await db.query('SELECT municipality,count(*)::integer AS count FROM public.patag_reports GROUP BY municipality ORDER BY count(*) DESC LIMIT 100')).rows;
  return {total:status.reduce((n,r)=>n+r.count,0),status,severity,municipality};
}
