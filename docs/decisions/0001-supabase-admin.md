> Historical: identity decisions superseded by [ADR-0002](0002-shared-postgresql-accounts.md). Supabase Auth is no longer used for application accounts.

# ADR-0001: Keep the Supabase admin behind a trusted Node API

Status: accepted for local implementation; hosted acceptance pending.
Date: 27 October 2026, Asia/Manila.

The existing admin is an independent React/TypeScript/Vite application with an HTTP contract. Supabase is mandatory for its Auth and data. Existing demo clients must remain separate, and protected roles cannot come from browser state or editable Auth metadata.

Use Node built-ins plus `pg` for the compatible HTTP API, Supabase Auth REST for identity and private Storage for evidence. This preserves existing views and avoids adding a web framework or shipping a privileged Supabase client to the browser. The BFF uses an HttpOnly cookie and protected profile records. PostgreSQL transactions assume the NOLOGIN NOBYPASSRLS `patag_api` role with verified JWT claims, so RLS applies in addition to server authorization. Browser roles receive scoped read privileges and no direct mutation privileges. Audit/history writes are append-only for the API role.

The database is normalized for profiles, teams, reports, assignments, evidence, history, repair updates, completions, per-recipient notifications and audit events. Roles use a protected allowlist; a capability framework is unnecessary for the existing UI. UUIDs reference Supabase Auth identities.

Keeping direct browser tokens would retain script-readable session material. Reusing the demo service would retain unsupported persistence and demo authentication. Rewriting the views around a new data SDK would change more callers than the contract adapter requires. These options were not selected.

Auth/Storage and PostgreSQL cannot share a transaction. New Auth-account and object creation uses compensation on SQL failure; reconciliation remains necessary if cleanup or an explicit password reset fails. Access-token expiry requires sign-in rather than retaining refresh tokens. Real hosted acceptance is required before any production claim.
