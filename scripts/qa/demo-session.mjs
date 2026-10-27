// Explicit test-only demo authentication for screen inventories. Never used by the app.
export async function gotoDemo(page,url){
 await page.goto(url);await page.waitForFunction(()=>document.querySelector('h1,h2'));
 const route=new URL(url).hash.slice(2),role=route.split('/')[0];
 if(!['citizen','admin','maintenance'].includes(role)||/\/(login|register|forgot-password)$/.test(route))return;
 await page.evaluate(async role=>{const bootstrap=await fetch('/api/bootstrap');const state=await bootstrap.json();if(!bootstrap.ok||state.user.role!==role){const response=await fetch('/api/auth/demo',{method:'POST',body:JSON.stringify({role})});const data=await response.json();if(!response.ok)throw Error(data.error);sessionStorage.setItem('patag-token',data.token);}},role);
 await page.goto('about:blank');await page.goto(url);
}
