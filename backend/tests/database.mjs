import { PGlite } from '@electric-sql/pglite';
import { migrate } from '../migrate.mjs';
import { readFile } from 'node:fs/promises';
export const ids = { admin: '00000000-0000-4000-8000-000000000001', local: '00000000-0000-4000-8000-000000000002', citizen: '00000000-0000-4000-8000-000000000003', crew: '00000000-0000-4000-8000-000000000004', other: '00000000-0000-4000-8000-000000000005', inactive: '00000000-0000-4000-8000-000000000006', team: '00000000-0000-4000-8000-000000000010', report: '00000000-0000-4000-8000-000000000020', outside: '00000000-0000-4000-8000-000000000021' };
export async function database({legacy=false}={}) {
  const db = new PGlite();
  await db.exec(`CREATE ROLE anon; CREATE ROLE authenticated; CREATE ROLE service_role BYPASSRLS;
    CREATE SCHEMA auth; CREATE TABLE auth.users(id uuid PRIMARY KEY, email text);
    CREATE TABLE auth.sessions(id uuid PRIMARY KEY,user_id uuid REFERENCES auth.users);
    CREATE TABLE auth.mfa_factors(id uuid PRIMARY KEY, user_id uuid REFERENCES auth.users, status text);
    CREATE FUNCTION auth.jwt() RETURNS jsonb LANGUAGE sql STABLE AS $$ SELECT coalesce(nullif(current_setting('request.jwt.claims',true),''),'{}')::jsonb $$;
    CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$ SELECT (auth.jwt()->>'sub')::uuid $$;
    GRANT USAGE ON SCHEMA auth TO authenticated; GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA auth TO authenticated;
    CREATE SCHEMA storage; CREATE TABLE storage.buckets(id text PRIMARY KEY, name text, public boolean, file_size_limit bigint, allowed_mime_types text[]);`);
  const sql = await readFile(new URL('../../supabase/migrations/202610270001_admin.sql', import.meta.url), 'utf8');
  await db.exec(`CREATE TABLE public.teams(id text PRIMARY KEY DEFAULT gen_random_uuid()::text,name text NOT NULL CHECK(length(name) BETWEEN 1 AND 100),active boolean NOT NULL DEFAULT true,created_at timestamptz NOT NULL DEFAULT now());
  CREATE TABLE public.users(id text PRIMARY KEY DEFAULT gen_random_uuid()::text,name text NOT NULL CHECK(length(name) BETWEEN 1 AND 100),email text NOT NULL CHECK(length(email)<=254),role text NOT NULL CHECK(role IN ('citizen','admin','maintenance')),active boolean NOT NULL DEFAULT true,team_id text REFERENCES public.teams(id),address jsonb,email_verified boolean NOT NULL DEFAULT false,password_hash text,created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now(),CONSTRAINT maintenance_has_team CHECK(role<>'maintenance' OR team_id IS NOT NULL));
  CREATE UNIQUE INDEX users_email_lower ON public.users(lower(email));
  ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
  CREATE TABLE public.sessions(token_hash text PRIMARY KEY,user_id text NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,created_at timestamptz NOT NULL DEFAULT now(),expires_at timestamptz NOT NULL);
  ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;`);
  const query=(sql,params)=>params?db.query(sql,params):db.exec(sql).then(results=>results.at(-1));
  const pool={ db, sql, query, connect: async () => ({ query, release() {} }), end: () => db.close() };
  if(legacy) await db.exec(sql); else await migrate(pool);
  return pool;
}
export async function fixtures(db) {
  await db.query('INSERT INTO public.patag_teams(id,name,municipality) VALUES($1,$2,$3)', [ids.team,'Test Crew','Malolos']);
  await db.query('INSERT INTO public.teams(id,name) VALUES($1,$2)',[ids.team,'Test Crew']);
  for (const [key, role, municipality, active] of [['admin','administrator',null,true],['local','administrator','Malolos',true],['citizen','citizen','Malolos',true],['crew','maintenance','Malolos',true],['other','citizen','Baliwag',true],['inactive','administrator',null,false]]) {
    await db.query('INSERT INTO public.users(id,name,email,role,address,active,team_id) VALUES($1,$2,$3,$4,$5,$6,$7)', [ids[key],key,`${key}@example.test`,role==='administrator'?'admin':role,JSON.stringify({city:municipality,province:'Bulacan'}),active,key==='crew'?ids.team:null]);
  }
  for (const [id, city, owner] of [[ids.report,'Malolos',ids.citizen],[ids.outside,'Baliwag',ids.other]]) {
    await db.query('INSERT INTO public.patag_reports(id,title,description,road,barangay,municipality,latitude,longitude,reporter_id) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)', [id,'Test damage','Test description','Test Road','Test Barangay',city,14.855,120.815,owner]);
  }
}
export async function asUser(db, user, operation, role = 'patag_api') {
  await db.exec('BEGIN');
  try {
    await db.query("SELECT set_config('patag.actor_id',$1,true)", [user]);
    await db.exec(`SET LOCAL ROLE ${role}`);
    const result = await operation();
    await db.exec('COMMIT');
    return result;
  } catch (e) { await db.exec('ROLLBACK'); throw e; }
}
