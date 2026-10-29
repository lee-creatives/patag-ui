import { chromium, expect } from '@playwright/test';
import http from 'node:http';
import path from 'node:path';
import { mkdir,readFile,writeFile } from 'node:fs/promises';
import { database,fixtures,ids } from '../../backend/tests/database.mjs';
import { createServer } from '../../backend/server.mjs';
import {hashPassword} from '../../backend/passwords.mjs';
import { transaction } from '../../backend/db.mjs';
import { reportEvent } from '../../backend/service.mjs';
const root=path.resolve(import.meta.dirname,'../..'),temporary=path.join(root,'backend/.browser-temp'),output=path.join(root,'docs/backend-verification/shared-login-2026-10-29');
await mkdir(temporary,{recursive:true});await mkdir(output,{recursive:true});process.env.TEMP=temporary;process.env.TMP=temporary;
const pool=await database();await fixtures(pool.db);let api,context;
const web=http.createServer(async(req,res)=>{
 try {
  if(req.url.startsWith('/api/')) {
   const upstream=http.request({host:'127.0.0.1',port:api.address().port,path:req.url,method:req.method,headers:req.headers},response=>{res.writeHead(response.statusCode,response.headers);response.pipe(res);});
   upstream.on('error',()=>{res.writeHead(503);res.end('{"error":"API unavailable"}');});req.pipe(upstream);return;
  }
  const directory=path.join(root,'admin-web/dist'),name=path.resolve(directory,'.'+new URL(req.url,'http://localhost').pathname);
  if(!name.startsWith(directory+path.sep)){res.writeHead(404);res.end();return;}
  let content;try{content=await readFile(name);}catch{content=await readFile(path.join(directory,'index.html'));}
  res.setHeader('Content-Type',({'.js':'text/javascript','.css':'text/css','.png':'image/png','.svg':'image/svg+xml','.woff2':'font/woff2','.ttf':'font/ttf'})[path.extname(name)]||'text/html');res.end(content);
 }catch{res.writeHead(500);res.end();}
});
await new Promise(r=>web.listen(0,'127.0.0.1',r));const origin=`http://127.0.0.1:${web.address().port}`;
const config={url:'https://test.supabase.co',origin,serviceKey:'server-only-test-key-do-not-bundle',secure:false};
api=createServer({config,pool,storage:{download:async()=>new Response(Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=','base64'))}});
await new Promise(r=>api.listen(0,'127.0.0.1',r));
const errors=[],failedApi=[],demoRequests=[],checks=[];let expectedOutage=false,expectedAnonymous=true;
try {
 context=await chromium.launchPersistentContext(path.join(temporary,'profile'),{channel:'chrome',headless:true,downloadsPath:path.join(temporary,'downloads'),viewport:{width:1440,height:1000},args:['--disable-gpu']});
 const page=await context.newPage();page.on('pageerror',error=>errors.push(error.message));
 page.on('request',req=>{if(req.url().includes('/auth/demo'))demoRequests.push(req.url());});
 page.on('response',res=>{if(res.url().includes('/api/')&&res.status()>=400&&!(expectedAnonymous&&res.status()===401&&new URL(res.url()).pathname==='/api/bootstrap')&&!(expectedOutage&&res.status()===503&&res.url().includes('/api/users?')))failedApi.push({url:res.url(),status:res.status()});});
 await pool.db.exec('DROP SCHEMA auth CASCADE');
 await pool.db.query("INSERT INTO public.users(id,name,email,role,address,password_hash) VALUES('mobile:browser','Mobile Browser','mobile-browser@example.test','citizen','{\"city\":\"Malolos\"}','private-existing-hash')");
 await pool.db.query('UPDATE public.users SET password_hash=$1 WHERE id=$2',[await hashPassword('Shared browser password 123'),ids.admin]);
 await page.goto(origin+'/admin/dashboard');await expect(page).toHaveURL(/\/admin\/login$/);
 await expect(page.getByRole('heading',{name:'Sign in to PATAG',exact:true})).toBeVisible();
 await page.screenshot({path:path.join(output,'login.png'),fullPage:true});
 await page.getByLabel('Email address',{exact:true}).fill('admin@example.test');await page.getByLabel('Password',{exact:true}).fill('Shared browser password 123');
 await page.getByRole('button',{name:'Sign in',exact:true}).click();await expect(page).toHaveURL(/\/admin\/dashboard$/);expectedAnonymous=false;checks.push('shared PostgreSQL email/password login without Supabase Auth');
 await page.goto(origin+'/admin/users');
 await page.getByRole('textbox',{name:'Search users'}).fill('Mobile Browser');
 await expect(page.getByRole('link',{name:'Mobile Browser',exact:true})).toBeVisible();checks.push('mobile-created PostgreSQL account visible');
 await page.getByRole('link',{name:'Mobile Browser',exact:true}).click();
 await expect(page.getByRole('heading',{name:'User details',exact:true})).toBeVisible();checks.push('text-ID account detail');
 await page.getByRole('button',{name:'Manage',exact:true}).click();
 await page.getByRole('dialog').locator('select[name=active]').selectOption('false');
 await page.getByRole('button',{name:'Confirm account changes'}).click();
 await expect(page.getByRole('dialog')).toHaveCount(0);await expect(page.getByRole('table').getByText('Inactive',{exact:true})).toBeVisible();checks.push('account status saved to shared PostgreSQL');
 await page.goto(origin+'/admin/users');await page.getByRole('button',{name:'Add account',exact:true}).click();
 await page.getByLabel('Full name',{exact:true}).fill('Admin Created');await page.getByLabel('Email address',{exact:true}).fill('admin-created@example.test');
 await page.getByRole('button',{name:'Confirm account changes'}).click();await expect(page.getByRole('dialog')).toHaveCount(0);
 await page.getByRole('textbox',{name:'Search users'}).fill('Admin Created');await expect(page.getByRole('link',{name:'Admin Created',exact:true})).toBeVisible();checks.push('admin account creation without Auth');
 await page.getByRole('combobox',{name:'Role filter',exact:true}).selectOption('maintenance');await expect(page.getByRole('link',{name:'Admin Created',exact:true})).toHaveCount(0);checks.push('server role filtering');
 await pool.db.query("INSERT INTO public.users(name,email,role) SELECT 'Paging '||n,'paging-'||n||'@example.test','citizen' FROM generate_series(1,30) n");
 await page.goto(origin+'/admin/users');await expect(page.getByRole('button',{name:'Next accounts'})).toBeEnabled();await page.getByRole('button',{name:'Next accounts'}).click();await expect(page.getByText('Page 2',{exact:true})).toBeVisible();checks.push('server account pagination');
 await page.evaluate(()=>window.scrollTo({top:0,behavior:'instant'}));
 await page.waitForFunction(()=>window.scrollY===0);
 await page.screenshot({path:path.join(output,'shared-accounts.png'),fullPage:true});
 await page.goto(origin+'/admin/reports/'+ids.report);await page.getByRole('button',{name:'Verify report',exact:true}).click();await page.getByRole('button',{name:'Confirm verify',exact:true}).click();
 await expect(page.getByRole('dialog')).toHaveCount(0);await expect(page.getByRole('button',{name:'Assign maintenance team',exact:true})).toBeVisible();checks.push('real verification modal payload');
 await page.getByRole('button',{name:'Assign maintenance team',exact:true}).click();await expect(page.getByRole('dialog')).toBeVisible();await page.getByRole('dialog').locator('select[name=teamId]').selectOption(ids.team);await page.getByRole('button',{name:'Confirm assign',exact:true}).click();
 await expect(page.getByRole('dialog')).toHaveCount(0);checks.push('real crew assignment modal payload');
 const claims={sub:ids.crew};
 await transaction(pool,c=>reportEvent(c,ids.report,{action:'start'}),claims);
 const photo='00000000-0000-4000-8000-000000000030';await pool.db.query("INSERT INTO public.patag_evidence(id,uploaded_by,object_path,name,kind,mime_type,size) VALUES($1,$2,'test/after','after.png','after','image/png',68)",[photo,ids.crew]);
 await transaction(pool,c=>reportEvent(c,ids.report,{action:'complete',note:'Browser test repair',photos:[{id:photo}]}),claims);
 await page.reload();await page.getByRole('button',{name:'Confirm resolution',exact:true}).click();await page.getByRole('button',{name:'Confirm resolution',exact:true}).last().click();await expect(page.getByRole('dialog')).toHaveCount(0);checks.push('administrative resolution modal payload');
 await page.screenshot({path:path.join(output,'admin-report.png'),fullPage:true});
 await page.goto(origin+'/admin/duplicates');await expect(page.getByText('Showing up to 50 authorized candidate pairs.',{exact:false})).toBeVisible();checks.push('bounded duplicate screen');
 await pool.db.query('UPDATE public.patag_reports SET road=$1 WHERE id=$2',[' =1+1',ids.report]);
 await page.goto(origin+'/admin/exports');
 for(const kind of ['CSV','PDF']) {
  const pending=page.waitForEvent('download');await page.getByRole('button',{name:'Download '+kind,exact:false}).click();const download=await pending;const file=path.join(temporary,'export.'+kind.toLowerCase());await download.saveAs(file);const bytes=await readFile(file);
  if(kind==='CSV'&&(!bytes.toString().includes(ids.report)||!bytes.toString().includes("' =1+1")))throw Error('CSV omitted authorized report or failed formula protection.');if(kind==='PDF'&&!bytes.toString('ascii',0,4).includes('%PDF'))throw Error('Invalid PDF.');checks.push('authorized audited '+kind+' download');
 }
 await page.goto(origin+'/admin/notifications');await page.getByRole('button',{name:'Mark all as read'}).click();checks.push('notification read update');
 await page.goto(origin+'/admin/users');await expect(page.getByRole('table')).toBeVisible();
 expectedOutage=true;await page.route('**/api/users?**',route=>route.fulfill({status:503,contentType:'application/json',body:JSON.stringify({error:'Synthetic temporary outage'})}));
 await page.getByRole('textbox',{name:'Search users'}).fill('outage');await expect(page.getByText('Synthetic temporary outage',{exact:true})).toBeVisible();await expect(page.getByRole('table')).toBeVisible();
 await page.unroute('**/api/users?**');expectedOutage=false;await page.getByRole('textbox',{name:'Search users'}).fill('Mobile Browser');await expect(page.getByRole('link',{name:'Mobile Browser',exact:true})).toBeVisible();checks.push('polling failure keeps admin usable and recovers without Realtime');
 expectedAnonymous=true;await page.getByRole('button',{name:'Sign out',exact:true}).click();await expect(page).toHaveURL(/\/admin\/login$/);
 await page.goto(origin+'/admin/users');await expect(page).toHaveURL(/\/admin\/login$/);checks.push('logout revokes shared session and guards workspace');
 if(errors.length||failedApi.length||demoRequests.length)throw Error(JSON.stringify({errors,failedApi,demoRequests}));
 await writeFile(path.join(output,'browser-results.json'),JSON.stringify({checks,errors,failedApi,demoRequests,backend:'real Node API + isolated PostgreSQL; no Auth schema; private Storage boundary stub',hosted:false},null,2));
 console.log(`PASS: ${checks.length} browser checks; 0 page errors; 0 failed API responses; 0 demo requests.`);
}catch(error){if(context){const page=context.pages().at(-1);await page.screenshot({path:path.join(output,'browser-failure.png'),fullPage:true});console.error(await page.locator('body').innerText());}throw error;}finally{if(context)await context.close();await new Promise(r=>web.close(r));if(api)await new Promise(r=>api.close(r));await pool.end();}
