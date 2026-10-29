import { readdir, readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { configuration,email } from './config.mjs';
import { poolFor, transaction } from './db.mjs';
export async function migrate(pool,{legacyAdminEmail}={}) {
  const distinctEmail=legacyAdminEmail===undefined?undefined:email(legacyAdminEmail);
  const directory=new URL('../supabase/migrations/',import.meta.url);
  return transaction(pool,async db=>{
    await db.query('SELECT pg_advisory_xact_lock(728194620)');
    await db.query('CREATE SCHEMA IF NOT EXISTS patag_private');
    await db.query('REVOKE ALL ON SCHEMA patag_private FROM PUBLIC');
    await db.query('CREATE TABLE IF NOT EXISTS patag_private.migrations(name text PRIMARY KEY, checksum text NOT NULL, applied_at timestamptz NOT NULL DEFAULT now())');
    const files=(await readdir(directory)).filter(n=>/^\d+_[a-z0-9_]+\.sql$/.test(n)).sort();
    const applied=[];let renamed=false;
    for(const name of files) {
      const sql=await readFile(new URL(name,directory),'utf8'),checksum=createHash('sha256').update(sql).digest('hex');
      const old=(await db.query('SELECT checksum FROM patag_private.migrations WHERE name=$1',[name])).rows[0];
      if(old) {if(old.checksum!==checksum) throw Error('Applied migration differs from source: '+name);continue;}
      if(distinctEmail&&name==='202610290001_shared_accounts.sql') {
        const legacy=await db.query("SELECT p.id FROM public.patag_profiles p JOIN public.users u ON lower(u.email)=lower(p.email) WHERE p.role='administrator' AND u.role='admin' AND p.id::text<>u.id FOR UPDATE OF p");
        if(legacy.rows.length!==1) throw Error('Expected exactly one conflicting legacy administrator; no accounts changed.');
        const used=await db.query('SELECT id FROM public.users WHERE lower(email)=$1 UNION ALL SELECT id::text FROM public.patag_profiles WHERE lower(email)=$1',[distinctEmail]);
        if(used.rows.length) throw Error('The distinct legacy email is already in use; no accounts changed.');
        await db.query('UPDATE public.patag_profiles SET email=$1,updated_at=now() WHERE id=$2',[distinctEmail,legacy.rows[0].id]);
        renamed=true;
      }
      await db.query(sql);
      await db.query('INSERT INTO patag_private.migrations(name,checksum) VALUES($1,$2)',[name,checksum]);applied.push(name);
    }
    if(distinctEmail&&!renamed) throw Error('Legacy administrator email changes are supported only with the pending shared-account upgrade.');
    return applied;
  });
}
if(process.argv[1]===fileURLToPath(import.meta.url)) {
  let pool;
  try {
    const config=configuration();
    if(process.env.PATAG_ALLOW_HOSTED_MUTATIONS!=='true') throw Error('Hosted migration not authorized: set PATAG_ALLOW_HOSTED_MUTATIONS=true only after approving the target project and SQL.');
    pool=poolFor(config);const applied=await migrate(pool,{legacyAdminEmail:process.env.PATAG_LEGACY_ADMIN_EMAIL});console.log('Migrations applied: '+(applied.join(', ')||'none (already current)'));
  } catch(error) {console.error(error.code?'Supabase migration failed; inspect credentials, TLS and migration compatibility.':error.message);process.exitCode=1;}
  finally {if(pool) await pool.end();}
}
