import http from 'node:http';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {randomUUID,scryptSync,timingSafeEqual} from 'node:crypto';
import {seed,teams,statuses,candidates,transition,publicReport,workspace,manageWorkspace,registrationFields,addressFields,validatePassword} from './domain.mjs';
export async function createServer({persist=true,allowDemo=true}={}){
 const dir=path.dirname(fileURLToPath(import.meta.url)),dataDir=path.join(dir,'data');let db=seed();const sessions=new Map();const attempts=new Map();
 const issue=u=>{const token=randomUUID();sessions.set(token,{userId:u.id,expires:Date.now()+8*60*60*1000});return {token,user:publicUser(u)};};
 if(persist){await mkdir(dataDir,{recursive:true});try{db=JSON.parse(await readFile(path.join(dataDir,'db.json'),'utf8'));}catch{}}
 workspace(db);
 const save=async()=>{if(persist)await writeFile(path.join(dataDir,'db.json'),JSON.stringify(db,null,2));};
 const server=http.createServer(async(req,res)=>{
  res.setHeader('Access-Control-Allow-Origin',req.headers.origin&&/^http:\/\/(127\.0\.0\.1|localhost):(5173|5174|8080|8081|8082|8085)$/.test(req.headers.origin)?req.headers.origin:'*');res.setHeader('Access-Control-Allow-Headers','Content-Type,Authorization');res.setHeader('Access-Control-Allow-Methods','GET,POST,PATCH,DELETE,OPTIONS');res.setHeader('Vary','Origin');
  const send=(status,data)=>{res.writeHead(status,{'Content-Type':'application/json'});res.end(JSON.stringify(data));};
  try{
   if(req.method==='OPTIONS'){res.writeHead(204);res.end();return;}
   const url=new URL(req.url,'http://localhost');const p=url.pathname.replace(/^\/api/,'');
   if(p==='/health'){send(200,{ok:true,mode:'local-development-demo'});return;}
   if(p==='/demo-evidence.svg'||p==='/demo-after.svg'){res.writeHead(200,{'Content-Type':'image/svg+xml'});res.end(`<svg xmlns="http://www.w3.org/2000/svg" width="800" height="450" viewBox="0 0 800 450"><rect width="800" height="450" fill="#dde2e4"/><path d="M0 100L800 25V450H0" fill="#636b72"/><path d="M0 270L800 190" stroke="#f7f1eb" stroke-width="9" stroke-dasharray="90 60"/>${p.includes('after')?'<path d="M280 260l190-45 90 90-220 40z" fill="#414951"/>':'<path d="M250 255l100-54 144 25 80 65-92 70-175-20z" fill="#26313b"/><path d="M270 262l90-37 120 22 48 40-62 39-143-10z" fill="#182b49"/>'}<rect x="25" y="24" width="240" height="34" rx="6" fill="#f7f1eb"/><text x="40" y="47" font-family="Arial" font-size="17" fill="#182b49">Illustrated demo ${p.includes('after')?'repair':'evidence'}</text></svg>`);return;}
   if(p.startsWith('/uploads/')){const n=path.basename(p);if(!/^[a-f0-9-]+\.(png|jpg|webp)$/.test(n))throw Error('Invalid file.');const ext=path.extname(n);res.writeHead(200,{'Content-Type':ext==='.jpg'?'image/jpeg':`image/${ext.slice(1)}`,'X-Content-Type-Options':'nosniff'});res.end(await readFile(path.join(dataDir,n)));return;}
   let body={};if(['POST','PATCH','DELETE'].includes(req.method)){let raw='';for await(const chunk of req){raw+=chunk;if(raw.length>12*1024*1024){send(413,{error:'Photo must be under 8 MB.'});return;}}try{body=JSON.parse(raw||'{}');}catch{send(400,{error:'Invalid JSON.'});return;}}
   if(p.startsWith('/auth/demo')&&!allowDemo){send(404,{error:'Endpoint not found.'});return;}
   if(p==='/auth/demo/accounts'){send(200,db.users.filter(u=>u.active&&!u.hash).map(publicUser));return;}
   if(p==='/auth/demo'&&req.method==='POST'){const u=db.users.find(u=>u.role===body.role&&u.active&&!u.hash&&(!body.userId||u.id===body.userId));if(!u){send(403,{error:'Demo role unavailable.'});return;}send(200,issue(u));return;}
   if(['/auth/register','/auth/login'].includes(p)&&req.method==='POST'){
    const key=req.socket.remoteAddress+':'+p, now=Date.now();let attempt=attempts.get(key);if(!attempt||attempt.until<now){attempt={count:0,until:now+60000};attempts.set(key,attempt);}if(++attempt.count>20){send(429,{error:'Too many attempts. Wait a minute and try again.'});return;}
   }
   if(p==='/auth/register'&&req.method==='POST'){
    const fields=registrationFields(body,{addressRequired:true});
    if(db.users.some(u=>u.email.toLowerCase()===fields.email)){send(409,{error:'Unable to create an account with these details. Try signing in or recovering access.'});return;}
    const salt=randomUUID(),u={id:randomUUID(),role:'citizen',name:fields.name,email:fields.email,address:fields.address,active:true,emailVerified:false,salt,hash:scryptSync(fields.password,salt,64).toString('hex')};db.users.push(u);await save();send(201,issue(u));return;
   }
   if(p==='/auth/login'&&req.method==='POST'){
    const email=typeof body.email==='string'?body.email.trim().toLowerCase():'';const u=db.users.find(u=>u.email.toLowerCase()===email&&u.active);
    const password=typeof body.password==='string'&&body.password.length<=256?body.password:'';
    const candidate=scryptSync(password,u?.salt||'invalid-account',64);const valid=u?.hash&&timingSafeEqual(Buffer.from(u.hash,'hex'),candidate);
    if(!valid||(body.role&&u.role!==body.role)){send(401,{error:'Email or password is incorrect for this portal.'});return;}send(200,issue(u));return;
   }
   if(p==='/auth/recovery'&&req.method==='POST'){if(!/^\S+@\S+\.\S+$/.test(body.email)){send(400,{error:'Enter a valid email.'});return;}send(200,{message:'Demo recovery request recorded. No email service is configured.'});return;}
   const session=sessions.get((req.headers.authorization||'').replace('Bearer ',''));const user=db.users.find(u=>u.id===session?.userId&&session.expires>Date.now()&&u.active);
   if(p==='/public/reports'&&req.method==='GET'){send(200,db.reports.filter(r=>!['Rejected','Duplicate'].includes(r.status)).map(publicReport));return;}
   if(!user){send(401,{error:'Session expired. Sign in again.'});return;}
   if(p==='/auth/logout'){sessions.delete((req.headers.authorization||'').replace('Bearer ',''));send(200,{ok:true});return;}
   if(p==='/me'&&req.method==='PATCH'){if(!body.name?.trim()||!/^\S+@\S+\.\S+$/.test(body.email)){send(400,{error:'Name and valid email are required.'});return;}if(body.email.trim().toLowerCase()!==user.email.toLowerCase()){send(400,{error:'Email changes require verified account recovery.'});return;}const address=body.address?addressFields(body.address):null;user.name=body.name.trim();if(address&&user.role==='citizen')user.address=address;await save();send(200,publicUser(user));return;}
   if(p==='/bootstrap'){send(200,{reports:db.reports.filter(r=>user.role==='admin'||(user.role==='citizen'?r.reporterId===user.id:(!!user.teamId&&r.teamId===user.teamId))),teams:db.teams,settings:db.settings,demo:true,users:user.role==='admin'?db.users.map(publicUser):[],notifications:db.notifications.filter(n=>n.role===user.role&&(n.role!=='citizen'||n.userId===user.id)&&(n.role!=='maintenance'||(!!user.teamId&&n.teamId===user.teamId))),user:publicUser(user),statuses});return;}
   if(['/settings','/teams','/users'].includes(p)&&['POST','PATCH','DELETE'].includes(req.method)){
    if(p==='/users'&&req.method==='POST'&&user.role==='admin')registrationFields(body);
    if(p==='/users'&&req.method==='PATCH'&&user.role==='admin'&&typeof body.password==='string'&&body.password.length>0)validatePassword(body.password);
    const result=manageWorkspace(db,user,p,body,req.method);
    if(p==='/users'&&(req.method==='POST'||(req.method==='PATCH'&&typeof body.password==='string'&&body.password.length>0))){result.salt=randomUUID();result.hash=scryptSync(body.password,result.salt,64).toString('hex');}
    await save();send(req.method==='POST'?201:200,p==='/users'&&req.method!=='DELETE'?publicUser(result):result);return;
   }
   if(p==='/notifications/read'&&req.method==='POST'){db.notifications.filter(n=>n.role===user.role&&(n.role!=='citizen'||n.userId===user.id)&&(n.role!=='maintenance'||(!!user.teamId&&n.teamId===user.teamId))&&(body.id==='all'||body.id===n.id)).forEach(n=>n.read=true);await save();send(200,{ok:true});return;}
   if(p==='/uploads'&&req.method==='POST'){const m=/^data:image\/(png|jpeg|webp);base64,([A-Za-z0-9+/=]+)$/.exec(body.data||'');if(!m){send(400,{error:'Choose a PNG, JPEG or WebP image.'});return;}const bytes=Buffer.from(m[2],'base64');if(bytes.length>8*1024*1024||bytes.length<8){send(400,{error:'Invalid image or file exceeds 8 MB.'});return;}const magic=m[1]==='png'?bytes.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])):m[1]==='jpeg'?bytes[0]===255&&bytes[1]===216:bytes.toString('ascii',0,4)==='RIFF'&&bytes.toString('ascii',8,12)==='WEBP';if(!magic){send(400,{error:'Image content does not match its type.'});return;}await mkdir(dataDir,{recursive:true});const name=randomUUID()+'.'+(m[1]==='jpeg'?'jpg':m[1]);await writeFile(path.join(dataDir,name),bytes);send(201,{id:randomUUID(),url:'/uploads/'+name,name:body.name||name,kind:body.kind||'before'});return;}
   if(p==='/reports'&&req.method==='POST'&&user.role==='citizen'){const c=body.location?.coordinates;if(!body.photos?.length||!body.photos.every(x=>/^\/uploads\/[a-f0-9-]+\.(png|jpg|webp)$/.test(x.url))||!body.description?.trim()||!body.location?.road?.trim()||!body.location?.barangay?.trim()||!body.location?.city?.trim()||!body.location?.province?.trim()||!statuses||!['Low','Medium','High'].includes(body.severity)||!validCoordinates(c)){send(400,{error:'Evidence photo, description, road, barangay, city, province, valid coordinates and severity are required.'});return;}const at=new Date().toISOString(),r={id:'PTG-'+new Date().getFullYear()+'-'+randomUUID().slice(0,8).toUpperCase(),title:body.title?.trim()||'Pothole report',description:body.description.trim(),hazards:body.hazards||'',severity:body.severity,status:'Submitted',location:body.location,photos:body.photos,reporterId:user.id,jurisdiction:db.settings.agency,createdAt:at,updatedAt:at,teamId:null,assignment:null,history:[{id:randomUUID(),at,actor:'citizen',action:'Submitted',from:null,to:'Submitted',note:'Citizen report received; administrative review required.'}],updates:[],completion:null,feedback:null,flagged:false};db.reports.unshift(r);notify(r,'Report submitted for review');await save();send(201,r);return;}
   if(p==='/duplicates'&&req.method==='POST'){if(!validCoordinates(body.location?.coordinates)){send(400,{error:'Valid coordinates are required.'});return;}send(200,candidates(db.reports,body).map(x=>({...x,report:publicReport(x.report)})));return;}
   const match=/^\/reports\/([^/]+)(?:\/(events|feedback))?$/.exec(p);
   if(match){const r=db.reports.find(r=>r.id===match[1]);if(!r){send(404,{error:'Report not found.'});return;}if(user.role==='maintenance'&&(!user.teamId||r.teamId!==user.teamId)||user.role==='citizen'&&r.reporterId!==user.id){send(403,{error:'This report belongs to another account or team.'});return;}
    if(req.method==='GET'){send(200,r);return;}
    if(match[2]==='events'&&req.method==='POST'){if(body.action==='duplicate'&&!db.reports.some(x=>x.id===body.duplicateOf&&x.id!==r.id)){send(400,{error:'Original report not found.'});return;}if(['complete','before-photos'].includes(body.action)&&(!body.photos?.every(x=>/^\/uploads\/[a-f0-9-]+\.(png|jpg|webp)$/.test(x.url)))){send(400,{error:'Upload real repair photos first.'});return;}transition(r,user.role,body.action,body,db.teams);notify(r,body.action==='complete'?'Repair ready for LGU verification':`${r.id}: ${r.status}`);await save();send(200,r);return;}
    if(match[2]==='feedback'&&req.method==='POST'&&user.role==='citizen'){if(r.status!=='Resolved'||r.feedback){send(409,{error:'Feedback is available once for resolved reports.'});return;}if(!Number.isInteger(body.rating)||body.rating<1||body.rating>5||!body.text?.trim()){send(400,{error:'Choose a rating and add feedback.'});return;}r.feedback={rating:body.rating,text:body.text,at:new Date().toISOString()};await save();send(201,r.feedback);return;}
   }
   send(404,{error:'Endpoint not found.'});
  }catch(e){send(e.status||500,{error:e.status?e.message:'The local demo service could not complete this request.'});}
 });
 function notify(r,title){for(const role of ['citizen','admin','maintenance']){if(role==='maintenance'&&!r.teamId)continue;db.notifications.unshift({id:randomUUID(),role,teamId:role==='maintenance'?r.teamId:null,userId:role==='citizen'?r.reporterId:null,reportId:r.id,title,at:new Date().toISOString(),read:false});}db.notifications=db.notifications.slice(0,500);}
 return server;
}
function publicUser({hash,salt,...u}){return u;}
const validCoordinates=c=>c&&Number.isFinite(c.lat)&&Number.isFinite(c.lng)&&Math.abs(c.lat)<=90&&Math.abs(c.lng)<=180;
if(process.argv[1]===fileURLToPath(import.meta.url)){const server=await createServer();server.listen(4100,'127.0.0.1',()=>console.log('PATAG development API http://127.0.0.1:4100/api (fictional demo data)'));}
