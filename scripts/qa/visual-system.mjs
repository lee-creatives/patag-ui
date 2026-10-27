import {gotoDemo} from './demo-session.mjs';
import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'../..');
const {chromium,expect}=createRequire(path.join(root,'admin-web/package.json'))('@playwright/test');
const url=pathToFileURL(path.join(root,'preview/Open-PATAG.html')).href;
const out=path.join(root,'docs/visual-system');
await fs.mkdir(out,{recursive:true});
const results={dashboards:[],routes:[],navigation:[],errors:[]};
const browser=await chromium.launch({channel:'chrome',headless:true});
try {
 for(const theme of ['light','dark']) {
  const context=await browser.newContext({viewport:{width:1440,height:1000},colorScheme:theme});
  for(const role of ['admin','maintenance','citizen']) {
   const page=await context.newPage();page.on('pageerror',e=>results.errors.push(e.message));
   for(const width of [320,375,390,430,768,1024,1280,1440,1920]) {
    await page.setViewportSize({width,height:1000});
    await gotoDemo(page,url+'#/'+role+'/'+(role==='citizen'?'home':'dashboard'));
    await page.locator('h1').waitFor();await page.evaluate(()=>document.fonts.ready);
    await expect.poll(()=>page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),{timeout:3000}).toBe(true);
    const state=await page.evaluate(()=>({theme:document.documentElement.dataset.theme,font:getComputedStyle(document.querySelector('h1')).fontFamily,fontLoaded:document.fonts.check('14px Montserrat'),overflow:document.documentElement.scrollWidth>innerWidth}));
    if(state.theme!==theme||!state.font.includes('Montserrat')||!state.fontLoaded)throw Error(JSON.stringify({role,width,...state}));
    results.dashboards.push({role,width,...state});
    if([390,768,1440].includes(width))await page.screenshot({path:path.join(out,`${role}-${theme}-${width}.png`),fullPage:true});
   }
   if(role!=='citizen') {
    await page.setViewportSize({width:1280,height:900});
    if(!await page.locator('.sidebar.open').count())await page.getByRole('button',{name:'Open navigation',exact:true}).click();
    const nav=page.getByRole('navigation',{name:'Main navigation',exact:true});
    await nav.getByRole('link',{name:role==='admin'?'Pothole map':'Task map',exact:true}).click();
    await expect(page.locator('.sidebar.open')).toBeVisible();
    await expect(nav.getByRole('link',{name:'Notifications',exact:true})).toHaveCount(0);
    await expect(page.getByRole('link',{name:/^Notifications/})).toHaveCount(1);
    await page.reload();await page.locator('h1').waitFor();await expect(page.locator('.sidebar.open')).toBeVisible();
    const current=await page.locator('html').getAttribute('data-theme');
    await page.getByRole('button',{name:'Switch to '+(current==='dark'?'light':'dark')+' mode'}).click();
    await page.reload();await page.locator('h1').waitFor();await expect(page.locator('html')).toHaveAttribute('data-theme',current==='dark'?'light':'dark');
    await page.getByRole('button',{name:'Switch to '+theme+' mode'}).click();
    await page.setViewportSize({width:390,height:900});
    const hit=await page.locator('.sidebar').evaluate(el=>{const r=el.getBoundingClientRect();return el.contains(document.elementFromPoint(r.left+30,r.top+280));});
    if(!hit)throw Error('Map covers drawer');
    await page.screenshot({path:path.join(out,`${role}-${theme}-drawer.png`),fullPage:true});
    await nav.getByRole('link',{name:'Overview',exact:true}).click();await expect(page.locator('.sidebar.open')).toHaveCount(0);
    await page.getByRole('button',{name:'Open navigation',exact:true}).click();await page.keyboard.press('Escape');await expect(page.locator('.sidebar.open')).toHaveCount(0);
    results.navigation.push({role,theme,desktopPersistence:true,refreshPersistence:true,themePersistence:true,mobileCloses:true,drawerAboveMap:true,escape:true});
   }
   await page.close();
  }
  // Smoke every existing signed-in route in both themes, desktop and smallest phone.
  const inventory=await fs.readFile(path.join(root,'docs/screen-inventory.md'),'utf8');
  const routes=[...inventory.matchAll(/\| ([CAM]\d+) \| ([^|]+) \| `([^`]+)`/g)].filter(m=>m[1][0]!=='C'||Number(m[1].slice(1))>=7);
  for(const width of [320,1440])for(const item of routes) {
   let route=(item[1][0]==='C'?'/citizen':'')+item[3];
   route=route.replace(':reportId','PTG-2026-0103');
   if(route.includes('/teams/'))route=route.replace(':id','team-1');else if(route.includes('/users/'))route=route.replace(':id','citizen-1');else route=route.replace(':id',route.includes('feedback')?'PTG-2026-0108':route.includes('completions/')?'PTG-2026-0107':route.includes('repairs/')||route.includes('progress/')?'PTG-2026-0106':route.includes('assignments/')?'PTG-2026-0104':'PTG-2026-0101');
   const page=await context.newPage();page.on('pageerror',e=>results.errors.push(e.message));await page.setViewportSize({width,height:1000});await gotoDemo(page,url+'#'+route,{waitUntil:'domcontentloaded'});await page.locator('h1,h2').first().waitFor();await page.evaluate(()=>document.fonts.ready);
   const overflow=await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth);
   const heading=await page.locator('h1').allTextContents();results.routes.push({id:item[1],route,width,theme,overflow,heading});
   if(overflow||heading.some(h=>/page not found|access denied/i.test(h))) {await page.screenshot({path:path.join(out,`failure-${item[1]}-${theme}-${width}.png`),fullPage:true});console.error(JSON.stringify(results.routes.at(-1)));}
   await page.close();
  }
  await context.close();
 }
 if(results.routes.some(r=>r.overflow||r.heading.some(h=>/page not found|access denied/i.test(h))))throw Error('Route overflow detected; see results.json');
 if(results.errors.length)throw Error(results.errors.join(';'));
 console.log(`Passed ${results.dashboards.length} dashboard/theme/width checks, ${results.routes.length} route checks and ${results.navigation.length} navigation suites.`);
}catch(e){results.failure=e.message;throw e;}finally{await fs.writeFile(path.join(out,'results.json'),JSON.stringify(results,null,2));await browser.close();}
