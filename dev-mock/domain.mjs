export const statuses=['Submitted','Under Review','Verified','Assigned','In Progress','Resolved','Rejected','Duplicate'];
export const teams=[{id:'team-1',name:'Road Crew Alpha',members:['Mika Santos','Paolo Cruz'],active:true},{id:'team-2',name:'Road Crew Bravo',members:['Alma Reyes','Rico Garcia'],active:true}];
const roads=[['MacArthur Highway','Guinhawa',14.8587,120.8166],['Paseo del Congreso','San Agustin',14.8435,120.8108],['Santisima Trinidad Road','Santisima Trinidad',14.8671,120.8235],['Mabini Street','Mojon',14.8562,120.8047],['Paseo del Congreso','San Agustin',14.8437,120.8109],['Cabanas Road','Longos',14.8402,120.8217],['Sampaguita Street','Bulihan',14.871,120.812],['A. Mabini Street','Mojon',14.859,120.801],['Fausta Road','Mabolo',14.846,120.799],['Camia Street','Bulihan',14.875,120.816],['Riverside Road','Longos',14.838,120.825],['Paseo Street','Guinhawa',14.86,120.819]];
const order=['Submitted','Under Review','Verified','Assigned','Submitted','In Progress','In Progress','Resolved','Verified','Rejected','Duplicate','In Progress'];
export function seed(){return {reports:roads.map(([road,barangay,lat,lng],i)=>{let status=order[i];let h=[{id:`h-${i}`,at:`2026-10-${String(9+i).padStart(2,'0')}T02:30:00Z`,actor:'Citizen demo',action:'Submitted',from:null,to:'Submitted',note:'Photo and location received.'}];if(status!=='Submitted')h.push({id:`h-${i}-2`,at:`2026-10-${String(10+i).padStart(2,'0')}T03:30:00Z`,actor:'LGU demo',action:status,from:'Submitted',to:status,note:'Fictional demonstration history.'});return {id:`PTG-2026-${String(101+i).padStart(4,'0')}`,title:['Pothole near pedestrian crossing','Deep road damage beside intersection','Uneven road surface near tricycle stop'][i%3],description:'Road surface has broken beside the outer lane. Please inspect the damaged section, especially after rain.',hazards:i%2?'Water collects after rain.':'Near a pedestrian crossing.',severity:['High','Medium','Low'][i%3],status,location:{road,barangay,city:'Malolos',province:'Bulacan',landmark:'Near the barangay waiting shed',coordinates:{lat,lng}},reporterId:'citizen-1',jurisdiction:'Malolos demo jurisdiction',createdAt:h[0].at,updatedAt:h.at(-1).at,photos:[{id:`p-${i}`,url:'/demo-evidence.svg',kind:'before',name:'Illustrated demo evidence',demo:true}],teamId:['Assigned','In Progress','Resolved'].includes(status)?'team-1':null,assignment:['Assigned','In Progress','Resolved'].includes(status)?{teamId:'team-1',priority:'High',note:'Inspect the outer lane and use temporary traffic controls.',targetDate:'2026-10-26',at:h.at(-1).at}:null,history:h,updates:[],completion:i===6||status==='Resolved'?{state:status==='Resolved'?'Verified':'Awaiting Verification',note:'Damaged material removed, base compacted, surface patched and lane cleared.',photos:[{id:`after-${i}`,url:'/demo-after.svg',name:'Illustrated demo repair',kind:'after',demo:true}],at:'2026-10-21T01:00:00Z'}:null,feedback:null,flagged:false};}),users:[{id:'citizen-1',name:'Alex Dela Cruz',email:'citizen@example.test',role:'citizen',active:true},{id:'admin-1',name:'Andrea Reyes',email:'lgu@example.test',role:'admin',active:true},{id:'maintenance-1',name:'Mika Santos',email:'crew@example.test',role:'maintenance',teamId:'team-1',active:true}],notifications:[]};}
export const distance=(a,b)=>{const r=Math.PI/180,dlat=(b.lat-a.lat)*r,dlng=(b.lng-a.lng)*r;return 6371000*2*Math.asin(Math.sqrt(Math.sin(dlat/2)**2+Math.cos(a.lat*r)*Math.cos(b.lat*r)*Math.sin(dlng/2)**2));};
export function candidates(reports,report){return reports.filter(r=>r.id!==report.id&&!['Rejected','Duplicate'].includes(r.status)).map(r=>({report:r,distance:Math.round(distance(r.location.coordinates,report.location.coordinates))})).filter(x=>x.distance<=150 && x.report.location.road.toLowerCase()===report.location.road.toLowerCase());}
export function transition(report,role,action,payload={},availableTeams=teams){
 const current=report.status;let next=current;
 const fail=m=>{throw Object.assign(new Error(m),{status:409});};
 if(role==='admin'){
  if(action==='publication'){if(typeof payload.approved!=='boolean')fail('Choose a photo publication state.');report.publicPhotosApproved=payload.approved;}
  else if(action==='review'&&current==='Submitted')next='Under Review';
  else if(action==='verify'&&['Submitted','Under Review'].includes(current))next='Verified';
  else if(action==='reject'&&['Submitted','Under Review'].includes(current)){if(!payload.note?.trim())fail('Give a reason for rejection.');next='Rejected';}
  else if(action==='duplicate'&&['Submitted','Under Review'].includes(current)){if(!payload.duplicateOf||payload.duplicateOf===report.id)fail('Select an existing original report.');next='Duplicate';report.duplicateOf=payload.duplicateOf;}
  else if(action==='flag'){if(!payload.note?.trim())fail('Add follow-up instructions.');report.flagged=true;}
  else if(action==='forward'){if(!payload.jurisdiction?.trim())fail('Enter the responsible agency.');report.jurisdiction=payload.jurisdiction;}
  else if(action==='assign'&&current==='Verified'){if(!availableTeams.some(t=>t.id===payload.teamId&&t.active))fail('Choose an active team.');next='Assigned';report.teamId=payload.teamId;report.assignment={teamId:payload.teamId,note:payload.note||'',priority:payload.priority||report.severity,targetDate:payload.targetDate||null,at:new Date().toISOString()};}
  else if(action==='resolve'&&current==='In Progress'&&report.completion?.state==='Awaiting Verification'){next='Resolved';report.completion.state='Verified';}
  else if(action==='return'&&report.completion?.state==='Awaiting Verification'){if(!payload.note?.trim())fail('Explain the additional work.');next='In Progress';report.completion.state='Additional Work Requested';}
  else fail('This action is not allowed from the current report status.');
 }else if(role==='maintenance'){
  if(action==='before-photos'&&['Assigned','In Progress'].includes(current)&&report.completion?.state!=='Awaiting Verification'){if(!payload.photos?.length)fail('Upload before-repair photos.');report.publicPhotosApproved=false;report.photos.push(...payload.photos.map(p=>({...p,kind:'before'})));}
  else if(action==='start'&&current==='Assigned')next='In Progress';
  else if(action==='progress'&&current==='In Progress'){if(!payload.note?.trim())fail('Add a progress note.');report.updates.push({at:new Date().toISOString(),note:payload.note,phase:payload.phase||'Repair',photos:payload.photos||[]});}
  else if(action==='complete'&&current==='In Progress'&&report.completion?.state!=='Awaiting Verification'){if(!payload.note?.trim()||!payload.photos?.length)fail('Repair notes and after photos are required.');report.publicPhotosApproved=false;report.completion={state:'Awaiting Verification',note:payload.note,photos:payload.photos,at:new Date().toISOString()};}
  else fail('Maintenance can start work, update progress or submit evidence; LGU verification is required for resolution.');
 }else fail('Only operational roles can change report status.');
 report.status=next;report.updatedAt=new Date().toISOString();report.history.push({id:crypto.randomUUID(),at:report.updatedAt,actor:role,action,from:current,to:next,note:payload.note||''});return report;
}

// Public maps expose road progress, not account, assignment or private note data.
export function publicReport(r){
 const photo=p=>({id:p.id,url:p.url,kind:p.kind,name:'Road evidence',...(p.demo?{demo:true}:{})});
 return {id:r.id,title:`Pothole on ${r.location.road}`,description:`Reported road damage. Current status: ${r.status}.`,severity:r.severity,status:r.status,
  location:{road:r.location.road,barangay:r.location.barangay,city:r.location.city,province:r.location.province,coordinates:r.location.coordinates},
  createdAt:r.createdAt,updatedAt:r.updatedAt,photos:r.photos.filter(p=>p.demo||r.publicPhotosApproved===true).map(photo),
  history:r.history.filter(h=>h.from!==h.to||h.action==='complete').map(h=>({id:h.id,at:h.at,action:h.action,from:h.from,to:h.to,note:h.action==='complete'?'Repair submitted for LGU verification.':`Status updated to ${h.to}.`})),
  completion:r.completion?{state:r.completion.state,at:r.completion.at,photos:r.completion.photos.filter(p=>p.demo||r.publicPhotosApproved===true).map(photo),note:'Repair evidence submitted for administrative review.'}:null};
}

export function workspace(db){
 db.teams ??= structuredClone(teams);
 db.settings ??= {agency:'Malolos demo jurisdiction',city:'Malolos',province:'Bulacan'};
 return db;
}
export function manageWorkspace(db,user,p,body,method){
 workspace(db);
 const fail=(message,status=400)=>{throw Object.assign(Error(message),{status});};
 if(user.role!=='admin')fail('Administrator access required.',403);
 if(p==='/settings'){
  if(!body.agency?.trim()||!body.city?.trim()||!body.province?.trim())fail('Agency, city and province are required.');
  db.settings={agency:body.agency.trim(),city:body.city.trim(),province:body.province.trim()};return db.settings;
 }
 if(p==='/teams'){
  const name=typeof body.name==='string'?body.name.trim():'';
  if(!name||name.length>100)fail('Team name is required.');
  if(db.teams.some(t=>t.id!==body.id&&t.name.toLowerCase()===name.toLowerCase()))fail('A team with that name already exists.',409);
  const t=method==='POST'?{id:crypto.randomUUID(),members:[],active:true}:db.teams.find(t=>t.id===body.id);
  if(!t)fail('Team not found.',404);
  const ids=body.memberIds,active=body.active!==false;
  if(ids!==undefined){
   if(!Array.isArray(ids)||ids.length>1000||ids.some(id=>typeof id!=='string'||!id||id.length>100)||new Set(ids).size!==ids.length)fail('Choose unique member account IDs.');
   if(ids.some(id=>!db.users.some(u=>u.id===id&&u.active&&u.role==='maintenance')))fail('Choose active road crew accounts only.');
   if(!active&&ids.length)fail('Members require an active maintenance team.');
  }
  const remainingMembers=ids===undefined?db.users.some(u=>u.teamId===t.id&&u.active):ids.length>0;
  if(!active&&(remainingMembers||db.reports.some(r=>r.teamId===t.id&&!['Resolved','Rejected','Duplicate'].includes(r.status))))fail('Move active members and finish assigned tasks before deactivating this team.',409);
  t.name=name;t.active=active;
  if(method==='POST')db.teams.push(t);
  if(ids!==undefined){
   const selected=new Set(ids);
   for(const u of db.users)if(u.active&&u.role==='maintenance'){
    if(selected.has(u.id))u.teamId=t.id;
    else if(u.teamId===t.id)u.teamId=null;
   }
   for(const team of db.teams)team.members=db.users.filter(u=>u.active&&u.role==='maintenance'&&u.teamId===team.id).map(u=>u.name);
  }
  return t;
 }
 if(p==='/users'){
  const u=method==='POST'?{id:crypto.randomUUID(),active:true}:db.users.find(u=>u.id===body.id);
  if(!u)fail('Account not found.',404);
  if(u.id===user.id)fail(method==='DELETE'?'You cannot delete your own account.':'Manage your own profile in Settings.');
  if(method==='DELETE'){
   db.users=db.users.filter(x=>x.id!==u.id);
   for(const r of db.reports)if(r.reporterId===u.id)r.reporterId=user.id;
   for(const t of db.teams)t.members=db.users.filter(x=>x.active&&x.role==='maintenance'&&x.teamId===t.id).map(x=>x.name);
   return {ok:true,id:u.id};
  }
  const role=body.role||u.role;
  if(!['admin','citizen','maintenance'].includes(role))fail('Choose a valid role.');
  const teamId=body.teamId||u.teamId;
  if(role==='maintenance'&&!(method==='PATCH'&&u.role==='maintenance'&&!u.teamId&&!teamId)&&!db.teams.some(t=>t.id===teamId&&t.active))fail('Choose an active maintenance team.');
  if(method==='POST'){
   if(!body.name?.trim()||!/^\S+@\S+\.\S+$/.test(body.email||''))fail('Name and valid email are required.');
   const email=body.email.trim().toLowerCase();if(db.users.some(x=>x.email.toLowerCase()===email))fail('Email is already registered.',409);
   u.name=body.name.trim();u.email=email;
  }else{
   if(typeof body.name==='string'&&body.name.trim()){
    if(body.name.trim().length>100)fail('Enter your name (up to 100 characters).');
    u.name=body.name.trim();
   }
   if(typeof body.email==='string'&&body.email.trim()){
    const email=body.email.trim().toLowerCase();
    if(email.length>254||!/^\S+@\S+\.\S+$/.test(email))fail('Enter a valid email address.');
    if(db.users.some(x=>x.id!==u.id&&x.email.toLowerCase()===email))fail('Email is already registered.',409);
    u.email=email;
   }
  }
  u.role=role;u.teamId=role==='maintenance'?teamId:undefined;if(typeof body.active==='boolean')u.active=body.active;
  if(method==='POST')db.users.push(u);
  for(const t of db.teams)t.members=db.users.filter(x=>x.active&&x.role==='maintenance'&&x.teamId===t.id).map(x=>x.name);
  return u;
 }
 fail('Unknown workspace operation.',404);
}

export function addressFields(raw={},required=true) {
 const address={line:typeof raw.line==='string'?raw.line.trim():'',barangay:typeof raw.barangay==='string'?raw.barangay.trim():'',city:typeof raw.city==='string'?raw.city.trim():'',province:typeof raw.province==='string'?raw.province.trim():''};
 if(required&&(!address.barangay||!address.city||!address.province))throw Object.assign(Error('Enter your barangay, city or municipality, and province.'),{status:400});
 if(Object.values(address).some(value=>value.length>120))throw Object.assign(Error('Keep each address field within 120 characters.'),{status:400});
 return address;
}
export function validatePassword(password) {
 if(typeof password!=='string'||[...password].length<8||[...password].length>128||!/[a-z]/.test(password)||!/[A-Z]/.test(password)||!/[0-9]/.test(password)||!/[^A-Za-z0-9]/.test(password)) {
  throw Object.assign(Error('Password must be at least 8 characters and include lowercase, uppercase, number, and special character.'),{status:400});
 }
 return password;
}
export function registrationFields(body,{addressRequired=false}={}) {
 const name=typeof body.name==='string'?body.name.trim():'';
 const email=typeof body.email==='string'?body.email.trim().toLowerCase():'';
 if(!name||name.length>100)throw Object.assign(Error('Enter your name (up to 100 characters).'),{status:400});
 if(email.length>254||!/^\S+@\S+\.\S+$/.test(email))throw Object.assign(Error('Enter a valid email address.'),{status:400});
 const password=validatePassword(body.password);
 const address=addressFields(body.address||{},addressRequired);
 return {name,email,password,address};
}
