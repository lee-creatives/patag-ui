import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile,readdir } from 'node:fs/promises';
async function files(directory,pattern) {
 const entries=await readdir(new URL(directory,import.meta.url),{withFileTypes:true});
 const result=[];for(const entry of entries) {if(entry.isDirectory()) continue;if(pattern.test(entry.name)) result.push(new URL(directory+entry.name,import.meta.url));}return result;
}
test('active admin/backend have no Auth imports, privileged browser credentials or account-store fallback',async()=>{
 const backend=await files('../',/\.mjs$/),frontend=await files('../../admin-web/src/',/\.tsx?$/);
 for(const file of [...backend,...frontend]) {
  const source=await readFile(file,'utf8');
  assert.doesNotMatch(source,/auth\.users|auth\.sessions|request\.jwt\.claims|createAuth|claimsFor|registerSession|from ['"]\.\/auth\.mjs|\/auth\/v1|signInWithPassword|onAuthStateChange/,file.pathname);
  assert.doesNotMatch(source,/createMockApi|dev-mock|db\.json|node:sqlite|better-sqlite/,file.pathname);
  assert.doesNotMatch(source,/(?:localStorage|sessionStorage)\.(?:getItem|setItem)\(['"](?:patag-token|patag-user|accounts|users)/,file.pathname);
  if(frontend.includes(file)) assert.doesNotMatch(source,/SUPABASE_SERVICE_ROLE_KEY|SUPABASE_DB_URL|password_hash|VITE_\w*(SERVICE_ROLE|PASSWORD|SECRET|DATABASE)/,file.pathname);
 }
 const native=await readFile(new URL('../../citizen-mobile/lib/core/api.dart',import.meta.url),'utf8');
 assert.match(native,/String.fromEnvironment\('API_URL'\)/);assert.doesNotMatch(native,/defaultValue:.*4100/);
 const config=JSON.parse(await readFile(new URL('../../package.json',import.meta.url),'utf8'));
 assert.equal(config.scripts['seed:admin'],undefined);
});
