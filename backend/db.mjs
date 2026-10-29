import { Pool } from 'pg';
import { fail, accountId } from './config.mjs';
export function poolFor(config) {
  return new Pool({connectionString:config.dbUrl,ssl:{rejectUnauthorized:true},max:5,connectionTimeoutMillis:10000,idleTimeoutMillis:30000,statement_timeout:15000});
}
export async function requireSharedSchema(db) {
  const result=await db.query("SELECT EXISTS(SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace JOIN pg_attribute a ON a.attrelid=c.oid WHERE n.nspname='public' AND c.relname='patag_profiles' AND c.relkind='v' AND a.attname='id' AND a.atttypid='text'::regtype) AND to_regclass('public.sessions') IS NOT NULL AS ready");
  if(!result.rows[0]?.ready) fail(503,'Shared-account database upgrade is required. Apply 202610290001_shared_accounts.sql after reviewing and authorizing the migration.');
}
export async function transaction(pool, operation, claims) {
  const client=await pool.connect();
  try {
    await client.query('BEGIN');
    if (claims) {
      await requireSharedSchema(client);
      accountId(claims.sub);
      const locked=(await client.query('SELECT id,role,active FROM public.users WHERE id=$1 FOR SHARE',[claims.sub])).rows[0];
      if(claims.sessionHash!==undefined) {
        if(typeof claims.sessionHash!=='string'||!/^[a-f0-9]{64}$/.test(claims.sessionHash)||!locked?.active||locked.role!=='admin') fail(401,'Session expired. Sign in again.');
        const session=(await client.query('SELECT user_id FROM public.sessions WHERE token_hash=$1 AND user_id=$2 AND expires_at>now() FOR SHARE',[claims.sessionHash,claims.sub])).rows[0];
        if(!session) fail(401,'Session expired. Sign in again.');
      }
      await client.query("SELECT set_config('patag.actor_id',$1,true)",[claims.sub]);
      await client.query('SET LOCAL ROLE patag_api');
      const {rows}=await client.query('SELECT * FROM public.patag_profiles WHERE id=$1 AND active',[claims.sub]);
      if (!rows[0]) fail(403,'Account inactive or not authorized.');
      const actor=await client.query('SELECT (patag_private.actor()).id AS id');
      if (!actor.rows[0]?.id) fail(403,'Account context is unavailable.');
      client.actor=rows[0];
    }
    const result=await operation(client);
    await client.query('COMMIT');
    return result;
  } catch(error) { await client.query('ROLLBACK'); throw error; }
  finally { client.release(); }
}
export function publicUser(row) {
  return {id:row.id,name:row.name,email:row.email,role:row.role==='administrator'?'admin':row.role,active:row.active,teamId:row.team_id ?? undefined};
}
export async function audit(db,action,id,municipality,details={}) {
  await db.query('INSERT INTO public.patag_audit_events(actor_id,action,resource_id,municipality,details) VALUES($1,$2,$3,$4,$5)',[db.actor.id,action,id,municipality,JSON.stringify(details)]);
}
