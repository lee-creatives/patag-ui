# Shared administrator login fix — 29 October 2026

Status: implemented and verified locally; hosted application pending explicit approval. Only C:/Users/Admin/Documents/ChatGPT/patag-ui was inspected/changed. Existing work from the prior refactor remains intact. No hosted account, credential, schema or service change was made.

## Findings and resulting behavior

The local account-ID mode did not provide normal login. The existing mobile PostgreSQL login implementation was found in THIS repository's local Citizen-mobile-Backend and Maintenance_Mobile-Backend branches: backend/src/passwords.ts, app.ts and store.ts. Both branches use NFKC scrypt32768/8/1,16-byte salt,64-byte key; sessions use SHA-256 hashes of random32-byte base64url tokens in public.sessions, expire after8h and resolve current active users. Reuse this contract instead of another provider/store.

Read-only hosted metadata confirmed the reported constraint error's cause: only202610270001_admin.sql was applied, patag_profiles remained a UUID TABLE, while the configured shared active admin has a text ID. The shared admin has no password_hash. There is one legacy/shared administrator email collision and no team identity collisions. The user confirmed the administrators are DIFFERENT and supplied a distinct legacy address privately; that address is available. They must never be merged.

Normal email/password login now uses shared public.users/public.sessions. The local account-ID bypass and corresponding config properties are removed; old bypass env values are ignored. HttpOnly SameSite=Strict/Secure-over-HTTPS cookies keep opaque tokens out of JS/token JSON/browser storage. Current account/session/admin status is locked and rechecked in actual protected operation transactions. Logout removes its shared session; disable/role changes permanently revoke target shared sessions, so reactivation does not revive old tokens. Password parsing bounds the mobile hash format and uses dummy work for invalid/missing credentials. Existing RLS, validation, quota/CSRF rules, private Storage and polling remain. No Supabase Auth, Edge Functions or Realtime implementation was introduced.

Schema readiness now gives explicit migration-required503 before UUID actor queries. A live read-only API probe (PostgreSQL default_transaction_read_only=on) confirmed that response on the current hosted schema. It performs no fallback/casting/account mutation.

The pending upgrade now includes the scoped public.teams policies required by the real mobile schema's enabled RLS, restricted session access and scoped session revocation. The original applied migration remains unchanged. The explicit legacyAdminEmail option validates exactly one conflicting legacy admin and an unused distinct address, then renames only that legacy profile atomically with the upgrade. Both account IDs, the existing mobile email/hash and all legacy report references remain intact. Failure rolls everything back. Real personal addresses/passwords are not committed to source.

A guarded admin:set-password command sets a mobile-compatible initial hash ONLY on an existing active admin with NULL hash, revokes its earlier sessions and refuses account creation, promotion or credential overwrite. It requires explicit hosted-mutation authorization. No password was requested in chat, generated, printed or set. Existing Supabase Auth passwords cannot automatically authenticate the separate application credential field.

## Verification

| Check | Result |
| --- | --- |
| npm test | PASS:39 tests,0 failures,0 skips; isolated PostgreSQL, bounded concurrency |
| npm run build | PASS:TypeScript and Vite; existing large-chunk warning |
| npm run lint | Exit0,4 existing warnings; no new suppressions |
| npm run test:browser | PASS:16 checks,0 page errors,0 unexpected failed API responses,0 demo requests; real built admin and Node API, isolated SQL accounts, no Supabase Auth schema, synthetic private Storage boundary |
| git diff --check | PASS; only LF/CRLF normalization notices |
| Hosted read-only preflight | Old UUID table/original-only migration confirmed, configured shared admin valid, missing password credential, one separate-admin collision, chosen distinct address available |
| Live read-only readiness probe | PASS:503 with explicit required-migration message; database writes disabled |

Tests cover known mobile-format hash/NFKC compatibility; wrong/missing/malformed credentials; valid-password citizen/inactive denial with uniform401/no session insertion; cookie flags; expired/logout/revoked sessions; operation-time revocation/demotion; deactivate/reactivate and demote/promote permanent revocation; old-schema HTTP503; initial-password null-only/no-promotion behavior; atomic separation of administrators and existing FK/hash preservation; shared teams under RLS; existing account/workflow behavior. Browser verification covers normal sign-in, anonymous redirect, account list/details/filter/paging/status/create, report actions/exports/notifications/outage recovery and sign-out. Expected anonymous bootstrap401 is explicitly scoped; other failures remain failures.

[Browser results](browser-results.json), [restored login](login.png), [accounts](shared-accounts.png), [report](admin-report.png). Login screenshot was visually inspected.

## Reviews and remaining deployment work

Separate read-only correctness/security/test reviewers found and resolved: actual mobile-team RLS mismatch, operation-time session revocation race, shared-session revival after reactivation, valid-password role-denial coverage and HTTP migration-readiness coverage. Final reviewers report no remaining actionable/blocking findings. Reviewers did not edit or run competing suites.

The hosted database has NOT been upgraded; neither administrator was renamed/merged and no credential was initialized. Before applying: obtain explicit approval, review/secure a backup, use the user-chosen distinct legacy email, and apply the tested upgrade transaction. Then the operator sets the intended administrator password PRIVATELY via admin:set-password and restarts the API. No account-ID copying is needed for login. [Setup and private password steps](../../supabase-backend.md), [ADR](../../decisions/0003-shared-account-login.md).

The migration changes account FK column types, replaces the old profile table with a view and adjusts grants/RLS; external consumers, locks/maintenance window and backup/recovery need review. Actual mobile/server integration, hosted credential login, concurrent-load races, real Storage, production gateway/TLS, MFA/recovery/reset and deployment acceptance remain unverified. No new dependencies were added. Previous refactor's no-login report is a historical snapshot and is superseded here.

## File inventory

This snapshot includes the complete uncommitted refactor plus this login correction. M=modified,D=removed,A=added. Real ignored credential files are not changed; generated build/cache/browser temporary files remain inside this repository.

| Status | Repository-relative file |
| --- | --- |
| M | .env.example |
| M | admin-web/.env.example |
| M | admin-web/README.md |
| M | admin-web/src/api.ts |
| M | admin-web/src/App.tsx |
| D | admin-web/src/recovery.ts |
| D | admin-web/src/ResetPassword.tsx |
| D | admin-web/tests/recovery-browser.mjs |
| D | admin-web/tests/recovery.test.mjs |
| M | admin-web/tests/supabase-browser.mjs |
| M | backend/.env.example |
| M | backend/accounts.mjs |
| D | backend/auth.mjs |
| M | backend/config.mjs |
| M | backend/db.mjs |
| M | backend/migrate.mjs |
| A | backend/passwords.mjs |
| M | backend/queries.mjs |
| D | backend/seed-admin.mjs |
| M | backend/server.mjs |
| M | backend/service.mjs |
| A | backend/sessions.mjs |
| A | backend/set-admin-password.mjs |
| A | backend/tests/account-boundaries.test.mjs |
| M | backend/tests/accounts.test.mjs |
| D | backend/tests/auth.test.mjs |
| M | backend/tests/config.test.mjs |
| M | backend/tests/database.mjs |
| M | backend/tests/database.test.mjs |
| M | backend/tests/evidence.test.mjs |
| M | backend/tests/http.test.mjs |
| D | backend/tests/mfa-recovery.test.mjs |
| D | backend/tests/recovery.test.mjs |
| M | backend/tests/regressions.test.mjs |
| D | backend/tests/seed.test.mjs |
| M | backend/tests/service.test.mjs |
| A | backend/tests/sessions.test.mjs |
| A | backend/tests/shared-accounts.test.mjs |
| M | citizen-mobile/lib/core/api.dart |
| M | citizen-mobile/test/auth_test.dart |
| M | docs/api-contract.md |
| M | docs/architecture.md |
| A | docs/backend-verification/shared-accounts-2026-10-29/admin-report.png |
| A | docs/backend-verification/shared-accounts-2026-10-29/browser-results.json |
| A | docs/backend-verification/shared-accounts-2026-10-29/README.md |
| A | docs/backend-verification/shared-accounts-2026-10-29/shared-accounts.png |
| A | docs/backend-verification/shared-login-2026-10-29/admin-report.png |
| A | docs/backend-verification/shared-login-2026-10-29/browser-results.json |
| A | docs/backend-verification/shared-login-2026-10-29/login.png |
| A | docs/backend-verification/shared-login-2026-10-29/README.md |
| A | docs/backend-verification/shared-login-2026-10-29/shared-accounts.png |
| M | docs/decisions/0001-supabase-admin.md |
| A | docs/decisions/0002-shared-postgresql-accounts.md |
| A | docs/decisions/0003-shared-account-login.md |
| M | docs/environment.md |
| A | docs/shared-account-schema.md |
| M | docs/supabase-backend.md |
| M | package.json |
| M | README.md |
| A | supabase/migrations/202610290001_shared_accounts.sql |
