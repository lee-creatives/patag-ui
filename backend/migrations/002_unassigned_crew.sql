-- Crew removal keeps the account active but without access to any team workload.
-- Existing assignments, foreign keys, and account data are preserved.
alter table users drop constraint if exists maintenance_has_team;
