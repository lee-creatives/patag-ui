-- Upgrade the existing admin foundation to the verified mobile public.users table.
-- The runner wraps this in one transaction. Never rewrite mobile IDs or credentials.
DO $$ BEGIN
 IF to_regclass('public.users') IS NULL OR to_regclass('public.teams') IS NULL THEN
  RAISE EXCEPTION 'Shared mobile public.users/public.teams schema is required; no account store is created';
 END IF;
 IF EXISTS(SELECT 1 FROM public.patag_profiles p JOIN public.users u ON u.id=p.id::text OR lower(u.email)=lower(p.email)
  WHERE u.id<>p.id::text OR lower(u.email)<>lower(p.email) OR u.role<>CASE p.role WHEN 'administrator' THEN 'admin' ELSE p.role END) THEN
  RAISE EXCEPTION 'Legacy account identity conflict: reconcile IDs/emails/roles explicitly before migration';
 END IF;
 IF EXISTS(SELECT 1 FROM public.patag_teams p JOIN public.teams t ON t.id=p.id::text WHERE t.name<>p.name) THEN
  RAISE EXCEPTION 'Legacy team identity conflict: reconcile teams before migration';
 END IF;
END $$;
INSERT INTO public.teams(id,name,active,created_at)
 SELECT id::text,name,active,created_at FROM public.patag_teams ON CONFLICT(id) DO NOTHING;
INSERT INTO public.users(id,name,email,role,active,team_id,address,created_at,updated_at)
 SELECT id::text,name,email,CASE role WHEN 'administrator' THEN 'admin' ELSE role END,active,team_id::text,
  jsonb_strip_nulls(jsonb_build_object('city',municipality,'province',province)),created_at,updated_at
 FROM public.patag_profiles ON CONFLICT(id) DO NOTHING;
-- Remove only admin policies before converting their account foreign keys to text.
DO $$ DECLARE p record; BEGIN
 FOR p IN SELECT schemaname,tablename,policyname FROM pg_policies WHERE schemaname='public' AND tablename LIKE 'patag_%' LOOP
  EXECUTE format('DROP POLICY %I ON %I.%I',p.policyname,p.schemaname,p.tablename);
 END LOOP;
END $$;
DO $$ DECLARE f record; BEGIN
 FOR f IN SELECT conrelid::regclass AS tbl,conname,a.attname FROM pg_constraint c
  JOIN pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=c.conkey[1]
  WHERE c.contype='f' AND c.confrelid='public.patag_profiles'::regclass LOOP
  EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I',f.tbl,f.conname);
  EXECUTE format('ALTER TABLE %s ALTER COLUMN %I TYPE text USING %I::text',f.tbl,f.attname,f.attname);
  EXECUTE format('ALTER TABLE %s ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES public.users(id)',f.tbl,f.conname,f.attname);
 END LOOP;
END $$;
DROP FUNCTION patag_private.actor();
DROP TABLE public.patag_profiles;
-- Compatibility projection only: there is no second account/profile store.
CREATE VIEW public.patag_profiles WITH (security_invoker=true) AS
 SELECT id,name,email,CASE role WHEN 'admin' THEN 'administrator' ELSE role END AS role,active,
  coalesce(address->>'province','Bulacan') AS province,nullif(address->>'city','') AS municipality,
  team_id,created_at,updated_at FROM public.users;
REVOKE ALL ON public.patag_profiles FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.patag_profiles TO patag_api;
CREATE OR REPLACE FUNCTION patag_private.actor_id() RETURNS text
LANGUAGE sql STABLE SET search_path='' AS $$ SELECT nullif(current_setting('patag.actor_id',true),'') $$;
CREATE OR REPLACE FUNCTION patag_private.actor() RETURNS public.patag_profiles
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT p FROM public.patag_profiles p WHERE p.id=patag_private.actor_id() AND p.active
$$;
CREATE OR REPLACE FUNCTION patag_private.is_admin() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$ SELECT coalesce((patag_private.actor()).role='administrator',false) $$;
CREATE OR REPLACE FUNCTION patag_private.in_scope(city text) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
  SELECT coalesce((patag_private.actor()).id IS NOT NULL AND ((patag_private.actor()).municipality IS NULL OR lower((patag_private.actor()).municipality)=lower(city)),false)
$$;
CREATE OR REPLACE FUNCTION patag_private.can_report(ref uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
  SELECT EXISTS (SELECT 1 FROM public.patag_reports r WHERE r.id=ref AND patag_private.in_scope(r.municipality) AND (
    patag_private.is_admin() OR ((patag_private.actor()).role='citizen' AND r.reporter_id=(SELECT patag_private.actor_id())) OR ((patag_private.actor()).role='maintenance' AND r.team_id::text=(patag_private.actor()).team_id)))
$$;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA patag_private FROM PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA patag_private TO patag_api;

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.users FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE ON public.users TO patag_api;
REVOKE ALL ON public.teams FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE ON public.teams TO patag_api;
CREATE POLICY patag_accounts_read ON public.users FOR SELECT TO patag_api USING (
 (patag_private.actor()).id IS NOT NULL AND (id=patag_private.actor_id() OR
  (patag_private.is_admin() AND patag_private.in_scope(nullif(address->>'city','')))));
CREATE POLICY patag_accounts_write ON public.users FOR ALL TO patag_api USING (
 patag_private.is_admin() AND patag_private.in_scope(nullif(address->>'city','')))
 WITH CHECK(patag_private.is_admin() AND patag_private.in_scope(nullif(address->>'city','')));
DROP POLICY IF EXISTS teams_read ON public.patag_teams;
CREATE POLICY teams_read ON public.patag_teams FOR SELECT TO patag_api USING ((patag_private.actor()).id IS NOT NULL AND patag_private.in_scope(municipality));
DROP POLICY IF EXISTS reports_read ON public.patag_reports;
CREATE POLICY reports_read ON public.patag_reports FOR SELECT TO patag_api USING (patag_private.can_report(id));
DROP POLICY IF EXISTS evidence_read ON public.patag_evidence;
CREATE POLICY evidence_read ON public.patag_evidence FOR SELECT TO patag_api USING (patag_private.can_report(report_id) OR ((patag_private.actor()).id IS NOT NULL AND uploaded_by=patag_private.actor_id() AND report_id IS NULL));
DROP POLICY IF EXISTS notifications_read ON public.patag_notifications;
CREATE POLICY notifications_read ON public.patag_notifications FOR SELECT TO patag_api USING ((patag_private.actor()).id IS NOT NULL AND user_id=patag_private.actor_id() AND patag_private.can_report(report_id));
DROP POLICY IF EXISTS audit_read ON public.patag_audit_events;
CREATE POLICY audit_read ON public.patag_audit_events FOR SELECT TO patag_api USING (patag_private.is_admin() AND patag_private.in_scope(municipality));
DROP POLICY IF EXISTS settings_read ON public.patag_settings;
CREATE POLICY settings_read ON public.patag_settings FOR SELECT TO patag_api USING ((patag_private.actor()).id IS NOT NULL);
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['assignments','report_history','repair_updates','completions'] LOOP
    EXECUTE format('DROP POLICY IF EXISTS report_read ON public.patag_%I',t);
    EXECUTE format('CREATE POLICY report_read ON public.patag_%I FOR SELECT TO patag_api USING(patag_private.can_report(report_id))',t);
  END LOOP;
END $$;

-- patag_api is NOLOGIN and never granted to browser roles. Only the BFF assumes it.
GRANT INSERT,UPDATE ON public.patag_teams,public.patag_reports,public.patag_assignments,public.patag_evidence,public.patag_completions,public.patag_notifications TO patag_api;
GRANT INSERT ON public.patag_report_history,public.patag_repair_updates,public.patag_audit_events TO patag_api;
GRANT UPDATE ON public.patag_settings TO patag_api;
DROP POLICY IF EXISTS teams_write ON public.patag_teams;
CREATE POLICY teams_write ON public.patag_teams FOR ALL TO patag_api USING(patag_private.is_admin() AND patag_private.in_scope(municipality)) WITH CHECK(patag_private.is_admin() AND patag_private.in_scope(municipality));
DROP POLICY IF EXISTS reports_write ON public.patag_reports;
CREATE POLICY reports_write ON public.patag_reports FOR UPDATE TO patag_api USING(patag_private.can_report(id)) WITH CHECK(patag_private.can_report(id));
DROP POLICY IF EXISTS reports_insert ON public.patag_reports;
CREATE POLICY reports_insert ON public.patag_reports FOR INSERT TO patag_api WITH CHECK((patag_private.actor()).role='citizen' AND reporter_id=patag_private.actor_id() AND patag_private.in_scope(municipality));
DROP POLICY IF EXISTS evidence_insert ON public.patag_evidence;
CREATE POLICY evidence_insert ON public.patag_evidence FOR INSERT TO patag_api WITH CHECK(uploaded_by=patag_private.actor_id() AND (patag_private.actor()).id IS NOT NULL AND (report_id IS NULL OR patag_private.can_report(report_id)));
DROP POLICY IF EXISTS evidence_attach ON public.patag_evidence;
CREATE POLICY evidence_attach ON public.patag_evidence FOR UPDATE TO patag_api USING(uploaded_by=patag_private.actor_id()) WITH CHECK(uploaded_by=patag_private.actor_id() AND patag_private.can_report(report_id));
DROP POLICY IF EXISTS notifications_update ON public.patag_notifications;
CREATE POLICY notifications_update ON public.patag_notifications FOR UPDATE TO patag_api USING(user_id=patag_private.actor_id() AND patag_private.can_report(report_id)) WITH CHECK(user_id=patag_private.actor_id() AND patag_private.can_report(report_id));
DROP POLICY IF EXISTS notifications_insert ON public.patag_notifications;
CREATE POLICY notifications_insert ON public.patag_notifications FOR INSERT TO patag_api WITH CHECK(patag_private.can_report(report_id));
DROP POLICY IF EXISTS audit_insert ON public.patag_audit_events;
CREATE POLICY audit_insert ON public.patag_audit_events FOR INSERT TO patag_api WITH CHECK(actor_id=patag_private.actor_id() AND (patag_private.actor()).id IS NOT NULL AND patag_private.in_scope(municipality));
DROP POLICY IF EXISTS settings_update ON public.patag_settings;
CREATE POLICY settings_update ON public.patag_settings FOR UPDATE TO patag_api USING(patag_private.is_admin() AND (patag_private.actor()).municipality IS NULL) WITH CHECK(patag_private.is_admin() AND (patag_private.actor()).municipality IS NULL);
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['assignments','report_history','repair_updates','completions'] LOOP
    EXECUTE format('DROP POLICY IF EXISTS report_write ON public.patag_%I',t);
    EXECUTE format('CREATE POLICY report_write ON public.patag_%I FOR ALL TO patag_api USING(patag_private.can_report(report_id)) WITH CHECK(patag_private.can_report(report_id))',t);
  END LOOP;
END $$;

CREATE OR REPLACE FUNCTION patag_private.notify_report(ref uuid, message text) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
  IF NOT patag_private.can_report(ref) OR length(message)>300 THEN RAISE EXCEPTION 'not authorized' USING ERRCODE='42501'; END IF;
  INSERT INTO public.patag_notifications(user_id,report_id,title)
  SELECT p.id,r.id,message FROM public.patag_profiles p JOIN public.patag_reports r ON r.id=ref
  WHERE p.active AND p.province=r.province AND (p.municipality IS NULL OR lower(p.municipality)=lower(r.municipality))
    AND (p.role='administrator' OR p.id=r.reporter_id OR (p.role='maintenance' AND p.team_id=r.team_id::text));
END $$;
REVOKE ALL ON FUNCTION patag_private.notify_report(uuid,text) FROM PUBLIC,authenticated;
GRANT EXECUTE ON FUNCTION patag_private.notify_report(uuid,text) TO patag_api;
DROP POLICY IF EXISTS audit_api_read ON public.patag_audit_events;
CREATE POLICY audit_api_read ON public.patag_audit_events FOR SELECT TO patag_api USING(actor_id=patag_private.actor_id() AND (patag_private.actor()).id IS NOT NULL);
CREATE INDEX IF NOT EXISTS patag_reports_road_location ON public.patag_reports(lower(road),latitude,longitude);
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname='patag_api' AND (rolcanlogin OR rolbypassrls OR rolsuper)) THEN RAISE EXCEPTION 'Existing patag_api must be NOLOGIN NOBYPASSRLS NOSUPERUSER'; END IF;
END $$;

DROP TABLE patag_private.sessions;
REVOKE ALL ON SCHEMA patag_private FROM authenticated;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA patag_private FROM PUBLIC,anon,authenticated;
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['teams','reports','assignments','evidence','report_history','repair_updates','completions','notifications','audit_events','settings'] LOOP
  EXECUTE format('REVOKE ALL ON public.patag_%I FROM PUBLIC,anon,authenticated',t);
 END LOOP;
END $$;

-- Shared sessions are written only by the trusted mobile/admin servers.
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.sessions FROM PUBLIC,anon,authenticated,patag_api;
-- The mobile schema already enables team RLS; grant only mapped server access.
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
CREATE POLICY patag_shared_teams_read ON public.teams FOR SELECT TO patag_api USING (
 (patag_private.actor()).id IS NOT NULL AND ((patag_private.actor()).municipality IS NULL OR
 EXISTS(SELECT 1 FROM public.patag_teams p WHERE p.id::text=teams.id)));
CREATE POLICY patag_shared_teams_insert ON public.teams FOR INSERT TO patag_api WITH CHECK (
 patag_private.is_admin() AND EXISTS(SELECT 1 FROM public.patag_teams p WHERE p.id::text=teams.id));
CREATE POLICY patag_shared_teams_update ON public.teams FOR UPDATE TO patag_api USING (
 patag_private.is_admin() AND EXISTS(SELECT 1 FROM public.patag_teams p WHERE p.id::text=teams.id))
 WITH CHECK(patag_private.is_admin() AND EXISTS(SELECT 1 FROM public.patag_teams p WHERE p.id::text=teams.id));

CREATE OR REPLACE FUNCTION patag_private.revoke_account_sessions(target text) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT patag_private.is_admin() OR NOT EXISTS(SELECT 1 FROM public.users u WHERE u.id=target AND patag_private.in_scope(nullif(u.address->>'city','')) AND ((patag_private.actor()).municipality IS NULL OR u.role<>'admin')) THEN
  RAISE EXCEPTION 'not authorized' USING ERRCODE='42501';
 END IF;
 DELETE FROM public.sessions WHERE user_id=target;
END $$;
REVOKE ALL ON FUNCTION patag_private.revoke_account_sessions(text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION patag_private.revoke_account_sessions(text) TO patag_api;
