-- PATAG schema v1. Shapes follow docs/api-contract.md.
-- Report sub-records (photos, history, updates, completion, feedback, assignment)
-- are jsonb on the report row: they are always read and written with their report,
-- which keeps the contract shape exact and each workflow event a single-row update.

create table settings (
  id smallint primary key default 1 check (id = 1),
  agency text not null,
  city text not null,
  province text not null,
  updated_at timestamptz not null default now()
);

create table teams (
  id text primary key default gen_random_uuid()::text,
  name text not null check (char_length(name) between 1 and 100),
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create unique index teams_name_lower on teams (lower(name));

create table users (
  id text primary key default gen_random_uuid()::text,
  name text not null check (char_length(name) between 1 and 100),
  email text not null check (char_length(email) <= 254),
  role text not null check (role in ('citizen', 'admin', 'maintenance')),
  active boolean not null default true,
  team_id text references teams (id),
  address jsonb,
  email_verified boolean not null default false,
  -- null hash = seeded demo account, usable only through /auth/demo when ALLOW_DEMO=true
  password_hash text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint maintenance_has_team check (role <> 'maintenance' or team_id is not null)
);
create unique index users_email_lower on users (lower(email));
create index users_team on users (team_id) where role = 'maintenance';

create table sessions (
  token_hash text primary key,
  user_id text not null references users (id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);
create index sessions_user on sessions (user_id);
create index sessions_expires on sessions (expires_at);

create table uploads (
  name text primary key,
  uploaded_by text references users (id) on delete set null,
  content_type text not null,
  size_bytes integer not null check (size_bytes > 0),
  created_at timestamptz not null default now()
);

create sequence report_code_seq start 1001;

create table reports (
  id text primary key,
  title text not null,
  description text not null,
  hazards text not null default '',
  severity text not null check (severity in ('Low', 'Medium', 'High')),
  status text not null check (status in ('Submitted', 'Under Review', 'Verified', 'Assigned', 'In Progress', 'Resolved', 'Rejected', 'Duplicate')),
  location jsonb not null,
  photos jsonb not null default '[]',
  reporter_id text not null references users (id),
  jurisdiction text not null,
  team_id text references teams (id),
  assignment jsonb,
  history jsonb not null default '[]',
  updates jsonb not null default '[]',
  completion jsonb,
  feedback jsonb,
  flagged boolean not null default false,
  duplicate_of text references reports (id),
  public_photos_approved boolean,
  created_at timestamptz not null,
  updated_at timestamptz not null
);
create index reports_reporter on reports (reporter_id, created_at desc);
create index reports_team on reports (team_id, created_at desc);
create index reports_status on reports (status);
create index reports_road on reports (lower(location ->> 'road'));
create index reports_created on reports (created_at desc);

create table notifications (
  id text primary key default gen_random_uuid()::text,
  role text not null check (role in ('citizen', 'admin', 'maintenance')),
  user_id text references users (id) on delete cascade,
  team_id text references teams (id),
  report_id text not null references reports (id) on delete cascade,
  title text not null,
  at timestamptz not null default now(),
  read boolean not null default false
);
create index notifications_citizen on notifications (user_id, at desc) where role = 'citizen';
create index notifications_team on notifications (team_id, at desc) where role = 'maintenance';
create index notifications_admin on notifications (at desc) where role = 'admin';

-- Only this backend talks to the database. Lock out the Supabase Data API roles.
alter table settings enable row level security;
alter table teams enable row level security;
alter table users enable row level security;
alter table sessions enable row level security;
alter table uploads enable row level security;
alter table reports enable row level security;
alter table notifications enable row level security;

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'anon') then
    execute 'revoke all on all tables in schema public from anon, authenticated';
    execute 'revoke all on all sequences in schema public from anon, authenticated';
  end if;
end
$$;
