# Shared PostgreSQL accounts

The user identified public.users as the mobile account table. Read-only hosted information_schema/pg_constraint/pg_indexes inspection on 29 October 2026 verified the following schema. No account contents were read; no hosted data or schema was changed. TLS verification remained enabled with the repository CA certificate.

| Column | PostgreSQL type / behavior |
| --- | --- |
| id | text PRIMARY KEY, default gen_random_uuid()::text; existing text IDs remain unchanged |
| name | text NOT NULL, length 1–100 |
| email | text NOT NULL, at most 254 characters; existing users_email_lower UNIQUE index on lower(email) |
| role | text NOT NULL: citizen, admin, maintenance |
| active | boolean NOT NULL DEFAULT true |
| team_id | nullable text FK public.teams(id); required for maintenance |
| address | nullable jsonb; existing application fields are preserved |
| email_verified | boolean NOT NULL DEFAULT false |
| password_hash | nullable text; private, never selected into API account responses or changed by admin account management |
| created_at / updated_at | timestamptz NOT NULL DEFAULT now() |

Existing public.sessions, reports, notifications and uploads reference public.users. They are preserved. Shared public.teams has text id (UUID-text default), name, active and created_at. It does not carry municipality, so municipal administrators can assign only teams with a matching, currently visible public.patag_teams jurisdiction record. Province-wide administrators can select active shared teams. Existing admin team creation/updates maintain the matching shared team row transactionally.

public.users is the sole account store. The internal public.patag_profiles name becomes a security-invoker VIEW over users, mapping admin to administrator for existing report logic and deriving municipality/province from address.city/address.province. It stores no data and has no password column. Account APIs query users directly. Report/workflow tables retain their names and UUID report/team IDs; only account foreign-key columns change to text.

Normal administrator login uses this table’s existing mobile-format password_hash and public.sessions; it requires no account ID in environment configuration. The local citizen client requires explicit API_URL for its existing mobile API contract. This admin BFF does not implement citizen registration/login, credential enrollment, report intake, or a new identity provider. The deployed mobile backend must use this shared table and enforce its existing credential/session rules. Its deployed behavior was not exercised in this refactor.
