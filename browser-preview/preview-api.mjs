const publicUser=({hash,salt,...u})=>u;
async function passwordHash(password,salt,iterations=600000){const key=await crypto.subtle.importKey('raw',new TextEncoder().encode(password),'PBKDF2',false,['deriveBits']);const bytes=await crypto.subtle.deriveBits({name:'PBKDF2',salt:new TextEncoder().encode(salt),iterations,hash:'SHA-256'},key,256);return Array.from(new Uint8Array(bytes),b=>b.toString(16).padStart(2,'0')).join('');}
import {seed,teams,statuses,candidates,transition,publicReport,workspace,manageWorkspace,registrationFields,addressFields,validatePassword} from './domain.mjs';
const KEY='patag-hosted-preview-v1';
let memory;const attempts=new Map();
function read(){try{return workspace(JSON.parse(localStorage.getItem(KEY))||seed())}catch{return workspace(memory||seed())}}
function save(db){memory=db;try{localStorage.setItem(KEY,JSON.stringify(db))}catch{throw Object.assign(Error('Browser storage is full. Remove large preview photos or reset this demo.'),{status:400})}}
const response=(data,status=200)=>new Response(JSON.stringify(data),{status,headers:{'Content-Type':'application/json'}});
export async function enterRole(role){const token=sessionStorage.getItem('patag-token');if(!token)return;const db=read(),session=db.sessions?.[token];const user=db.users.find(u=>u.id===session?.userId&&u.active);if(!user||session.expires<=Date.now()||user.role!==role)sessionStorage.removeItem('patag-token');}
export function installPreviewApi(){
 const original=window.fetch.bind(window);
 window.fetch=async(input,options={})=>{
  const url=new URL(typeof input==='string'?input:input.url,location.origin);
  if(!url.pathname.startsWith('/api/'))return original(input,options);
  let db=read(),body={};try{body=typeof options.body==='string'?JSON.parse(options.body):{};}catch{return response({error:'Invalid request'},400)}
  const p=url.pathname.slice(4),method=options.method||'GET';
  const token=new Headers(options.headers).get('Authorization')?.replace('Bearer ','')||sessionStorage.getItem('patag-token')||'';
  db.sessions??={};const session=db.sessions[token];const user=db.users.find(u=>u.id===session?.userId&&session.expires>Date.now()&&u.active);
  const issue=u=>{const token=crypto.randomUUID();db.sessions[token]={userId:u.id,expires:Date.now()+8*60*60*1000};save(db);return {token,user:publicUser(u)}};
  const notify=(r,title)=>{for(const role of ['admin','citizen','maintenance']){if(role==='maintenance'&&!r.teamId)continue;db.notifications.unshift({id:crypto.randomUUID(),role,userId:role==='citizen'?r.reporterId:null,teamId:r.teamId,reportId:r.id,title,at:new Date().toISOString(),read:false});}};
  try{
   if(['/auth/login','/auth/register'].includes(p)){const now=Date.now();let a=attempts.get(p);if(!a||a.until<now){a={count:0,until:now+60000};attempts.set(p,a);}if(++a.count>20)return response({error:'Too many attempts. Wait a minute and try again.'},429);}
   if(p==='/auth/demo/accounts')return response(db.users.filter(u=>u.active&&!u.hash).map(publicUser));
   if(p==='/auth/demo'){const u=db.users.find(u=>u.role===body.role&&u.active&&!u.hash&&(!body.userId||u.id===body.userId));if(!u)return response({error:'Preview account inactive. Reset the demo to continue.'},403);return response(issue(u));}
   if(p==='/auth/login'){
    const u=db.users.find(u=>u.email.toLowerCase()===String(body.email).trim().toLowerCase()&&u.active);
    const valid=u?.hash&&typeof body.password==='string'&&body.password.length<=256&&await passwordHash(body.password,u.salt,u.iterations||100000)===u.hash;
    db=read();db.sessions??={};const current=db.users.find(x=>x.id===u?.id&&x.active);
    if(!valid||!current||current.email!==u.email||current.hash!==u.hash||current.salt!==u.salt||(current.iterations||100000)!==(u.iterations||100000)||(body.role&&current.role!==body.role))return response({error:'Email or password is incorrect. Seeded accounts use demo access.'},401);
    return response(issue(current));
   }
   if(p==='/auth/register'){
    const fields=registrationFields(body,{addressRequired:true});
    const salt=crypto.randomUUID(),hash=await passwordHash(fields.password,salt);db=read();db.sessions??={};
    if(db.users.some(u=>u.email.toLowerCase()===fields.email))return response({error:'Unable to create an account with these details. Try signing in or recovering access.'},409);
    const u=manageWorkspace(db,{role:'admin',id:'registration'},'/users',{name:fields.name,email:fields.email,role:'citizen'},'POST');u.salt=salt;u.hash=hash;u.iterations=600000;u.emailVerified=false;u.address=fields.address;
    return response(issue(u),201);
   }
   if(p==='/auth/recovery')return response({message:'This is a browser preview. No recovery email was sent.'});
   if(p==='/public/reports')return response(db.reports.filter(r=>!['Rejected','Duplicate'].includes(r.status)).map(publicReport));
   if(p==='/demo-evidence.svg'||p==='/demo-after.svg')return original(input,options);
   if(!user)return response({error:'Session expired. Sign in again.'},401);
   if(p==='/bootstrap')return response({user:publicUser(user),reports:db.reports.filter(r=>user.role==='admin'||(user.role==='maintenance'?(!!user.teamId&&r.teamId===user.teamId):r.reporterId===user.id)),teams:db.teams,settings:db.settings,demo:true,users:user.role==='admin'?db.users.map(publicUser):[],notifications:db.notifications.filter(n=>n.role===user.role&&(n.role!=='citizen'||n.userId===user.id)&&(n.role!=='maintenance'||(!!user.teamId&&n.teamId===user.teamId))),statuses});
   if(p==='/auth/logout'){delete db.sessions[token];save(db);sessionStorage.removeItem('patag-token');return response({ok:true})}
   if(p==='/me'){if(!body.name?.trim()||!/^\S+@\S+\.\S+$/.test(body.email))return response({error:'Enter a name and valid email.'},400);if(body.email.trim().toLowerCase()!==user.email.toLowerCase())return response({error:'Email changes require verified account recovery and are unavailable in this preview.'},400);const address=body.address?addressFields(body.address):null;user.name=body.name.trim();if(address&&user.role==='citizen')user.address=address;save(db);return response(publicUser(user))}
   if(['/settings','/teams','/users'].includes(p)&&['POST','PATCH','DELETE'].includes(method)){
    if(p==='/users'&&method==='POST'&&user.role==='admin')registrationFields(body);
    if(p==='/users'&&method==='PATCH'&&user.role==='admin'&&typeof body.password==='string'&&body.password.length>0)validatePassword(body.password);
    let actor=user,passwordFields;
    if(p==='/users'&&(method==='POST'||(method==='PATCH'&&typeof body.password==='string'&&body.password.length>0))){
     const salt=crypto.randomUUID(),hash=await passwordHash(body.password,salt);db=read();
     const currentSession=db.sessions?.[token];actor=db.users.find(u=>u.id===currentSession?.userId&&currentSession.expires>Date.now()&&u.active);
     if(!actor)return response({error:'Session expired. Sign in again.'},401);
     passwordFields={iterations:600000,salt,hash};
    }
    const result=manageWorkspace(db,actor,p,body,method);
    if(passwordFields)Object.assign(result,passwordFields);
    save(db);return response(p==='/users'&&method!=='DELETE'?publicUser(result):result,method==='POST'?201:200);
   }
   if(p==='/notifications/read'){db.notifications.filter(n=>n.role===user.role&&(user.role!=='citizen'||n.userId===user.id)&&(user.role!=='maintenance'||(!!user.teamId&&n.teamId===user.teamId))&&(body.id==='all'||body.id===n.id)).forEach(n=>n.read=true);save(db);return response({ok:true})}
   if(p==='/uploads'){if(!/^data:image\/(png|jpeg|webp);base64,/.test(body.data||'')||body.data.length>11*1024*1024)return response({error:'Choose a JPEG, PNG or WebP under 8 MB.'},400);return response({id:crypto.randomUUID(),url:body.data,name:body.name||'Preview photo',kind:body.kind||'before'},201)}
   if(p==='/duplicates')return response(candidates(db.reports,body).map(x=>({...x,report:publicReport(x.report)})));
   if(p==='/reports'&&method==='POST'&&user.role==='citizen'){
    const c=body.location?.coordinates;if(!body.photos?.length||!body.description?.trim()||!body.location?.road?.trim()||!body.location?.barangay?.trim()||!Number.isFinite(c?.lat)||!Number.isFinite(c?.lng)||Math.abs(c.lat)>90||Math.abs(c.lng)>180)return response({error:'Add a photo, valid location and description.'},400);
    const at=new Date().toISOString(),r={...body,id:'PTG-'+new Date().getFullYear()+'-'+crypto.randomUUID().slice(0,8).toUpperCase(),title:body.title||'Community pothole report',reporterId:user.id,status:'Submitted',jurisdiction:db.settings.agency,createdAt:at,updatedAt:at,teamId:null,assignment:null,history:[{id:crypto.randomUUID(),at,actor:'citizen',action:'Submitted',from:null,to:'Submitted',note:'Report received. LGU review required.'}],updates:[],completion:null,feedback:null,flagged:false};db.reports.unshift(r);notify(r,'New road report submitted');save(db);return response(r,201);
   }
   const match=/^\/reports\/([^/]+)(?:\/(events|feedback))?$/.exec(p);
   if(match){const r=db.reports.find(r=>r.id===match[1]);if(!r)return response({error:'Report not found.'},404);if(user.role==='maintenance'&&(!user.teamId||r.teamId!==user.teamId)||user.role==='citizen'&&r.reporterId!==user.id)return response({error:'This report belongs to another account or crew.'},403);
    if(method==='GET')return response(r);
    if(match[2]==='events'){transition(r,user.role,body.action,body,db.teams);notify(r,body.action==='complete'?'Repair ready for LGU verification':r.id+': '+r.status);save(db);return response(r)}
    if(match[2]==='feedback'&&user.role==='citizen'){if(r.status!=='Resolved'||r.feedback)return response({error:'Feedback is available once after the LGU verifies repair.'},409);if(!Number.isInteger(body.rating)||body.rating<1||body.rating>5||!body.text?.trim())return response({error:'Choose a rating and add feedback.'},400);r.feedback={rating:body.rating,text:body.text,at:new Date().toISOString()};save(db);return response(r.feedback,201)}
   }
   return response({error:'This operation is unavailable in this preview.'},404);
  }catch(e){return response({error:e.message},e.status||400)}
 };
}
