> Earlier snapshot: the temporary no-login/local mode is superseded by [shared PostgreSQL login](../shared-login-2026-10-29/README.md). Earlier test results remain historical evidence.

# Shared PostgreSQL accounts: implementation and verification

Date: 29 October 2026. Workspace: C:/Users/Admin/Documents/ChatGPT/patag-ui. Initial Git status was clean on Admin-webBackend. Work remains uncommitted; no push, publication or deployment was performed.

## Implemented changes

Admin account list/detail/filter/pagination/creation/status queries now use the verified public.users table directly. IDs remain text, including existing non-UUID IDs. Existing lower(email) uniqueness prevents duplicates. Responses expose only id,name,email,role,active,optional teamId. Password hashes, verification state and private addresses are not exposed. Status-only changes preserve existing credential/address values exactly.

Supabase Auth HTTP client, login/logout/MFA/recovery/password flows, cookies/JWT handling, provisioning compensation, seed command, reset UI, Auth-only tests/browser runner and login styling were removed. The publishable key/seed-password configuration requirements were removed. The private service-role key remains solely for existing evidence Storage. Existing ignored credential files were preserved.

The original checksummed migration is unchanged. The new migration merges compatible legacy-only profile rows into users while preserving IDs; conflicts abort atomically. Dependent account foreign keys become text references to users. patag_profiles becomes a security-invoker compatibility VIEW with no separate account storage. The old private admin Auth-session table is retired. The application does not require auth.users/auth.sessions; tests remove the entire Auth schema and still exercise account reads and report events. The historical initial migration still describes the former Auth foundation and is retained for deployed checksum compatibility.

Existing RLS scope/owner/team checks, workflow idempotency, audit, evidence validation, transactions and private Storage behavior remain. Admin-created report-workflow teams keep matching shared-team metadata coherent in the same transaction. Municipal account assignment requires an existing scoped team mapping; unmapped shared teams fail closed for municipal administrators. Deactivation can preserve an existing inactive team without enabling new assignments.

Native citizen API_URL no longer defaults to the JSON demo. It must explicitly target the existing mobile PostgreSQL API. The supplied maintenance-mobile folder has no application lib source to refactor. Explicit historical demo/preview clients remain separate references; the real admin has no account-store fallback.

## Authoritative account table and schema evidence

The user identified public.users. A current hosted read-only metadata transaction verified columns, constraints, indexes and relevant relationships without reading account contents. TLS stayed verified using the existing repository CA. No hosted data/schema/account changes occurred.

Fields: id text PRIMARY KEY DEFAULT gen_random_uuid()::text; name text; email text; role text constrained to citizen/admin/maintenance; active boolean; nullable team_id text FK public.teams; nullable address jsonb; email_verified boolean; nullable password_hash text; created_at/updated_at timestamptz. Existing unique index users_email_lower enforces lower(email). Maintenance requires a team. Full details: [schema](../../shared-account-schema.md).

Admin creation intentionally supplies no password_hash: it creates a compatible application record, not a usable credential/login. Credential enrollment must use the existing mobile/server workflow once available; no replacement authentication was built. No mobile record/password was deleted, rewritten or reset.

## Edge Functions and Realtime disposition

No Edge Function handler, invocation, deploy configuration or script exists in this checkout; none was removed or added. No Supabase Realtime subscription/channel/client exists; none was removed or added. Older endpoint references do not prove either capability. Therefore function/channel runtime tests are inapplicable, not passes.

Existing five-second SQL-backed API polling remains. Account list/details refetch the normal API with cleanup, stale-response protection, no overlapping polling, visible failure and recovery. Chrome verifies the account page remains usable after a temporary API failure with no Realtime dependency. No sensitive account payload is broadcast.

## Security boundary

Removing Auth removes operator identity verification. Workspace access is disabled by default and always blocked in production. Explicit local review requires PATAG_ALLOW_UNAUTHENTICATED_LOCAL_ADMIN=true plus a server-only PATAG_LOCAL_ADMIN_ID for a current active shared admin record. Socket/Host/origin checks restrict this to loopback; state-changing requests retain CSRF requirements and validated fields. These controls do not authenticate a person. Anyone with access to the enabled local workspace can use that configured administrator's privileges. Never expose this mode through LAN, a public proxy or tunnel.

Production identity verification/authorization is not implemented. Browser database grants/private actor helper access are revoked, SQL stays server-side, and privileged credentials are never VITE_* inputs. Existing mobile services must use their established trusted database boundary; direct anonymous/Auth Data API consumers may lose access after RLS/grant changes and must be checked before deployment.

## Exact verification results

| Command / check | Final result |
| --- | --- |
| npm test | PASS: 31 tests, 0 failed, 0 skipped; node --test --test-concurrency=1 backend/tests/*.test.mjs admin-web/tests/*.test.mjs |
| node --test --test-concurrency=1 backend/tests/shared-accounts.test.mjs backend/tests/http.test.mjs | PASS: 4 focused tests after address-preservation change; final full suite also covers inactive-team deactivation |
| node --test backend/tests/account-boundaries.test.mjs | PASS: 1 test after final styling/Auth cleanup |
| npm run lint | Exit 0; 4 existing warnings: Date during render, 2 existing synchronous setState effects, existing dialog-ref cleanup |
| npm run build | PASS: TypeScript project check and Vite production build; existing >500 kB chunk warning; final CSS 65.22 kB |
| npm run test:browser | PASS: 15 checks, 0 page errors, 0 unexpected failed API responses, 0 demo requests; latest run after final styling cleanup |
| flutter --no-version-check analyze --no-pub lib/core/api.dart (citizen-mobile) | PASS: no issues found |
| flutter --no-version-check test --no-pub test/auth_test.dart (citizen-mobile) | PASS: 2 tests including missing API_URL failing before networking |
| npm ls --depth=0; npm --prefix admin-web ls --depth=0 | Both exit 0; installed dependencies valid; no dependency added/upgraded |
| npm audit --json --cache C:/Users/Admin/Documents/ChatGPT/patag-ui/.npm-cache | Root: exit 0, 0 vulnerabilities |
| npm --prefix admin-web audit --json --cache C:/Users/Admin/Documents/ChatGPT/patag-ui/.npm-cache | Admin: exit 0, 0 vulnerabilities |
| Access-guard mutation check | PASS: copied HTTP test rejected inverted opt-in condition (expected 200 versus 503 assertion failure); temporary copies removed, live source untouched |
| git diff --check | PASS: no whitespace errors; Git emits only LF-to-CRLF normalization notices for two files |
| Migration/schema tests | PASS: full runner, populated legacy upgrade, preserved mobile hash/IDs/report references, repeat/checksum handling, atomic identity-conflict refusal, post-Auth removal RLS/report events |
| Removed-code/secret/fallback checks | PASS: targeted current admin/backend source scan for Auth calls/imports, privileged frontend identifiers, account storage fallback; historical migrations and separate demos are excluded deliberately |

Tests use isolated synthetic PostgreSQL via PGlite, never application fallback storage. Chrome uses the actual built React admin and Node API with no Auth schema; evidence downloads use a synthetic Storage boundary. Browser checks include mobile-shaped SQL account visibility, details with text IDs, create/status/filter/paging, existing verification/assignment/resolution/export/notifications and outage recovery. [Saved browser results](browser-results.json), [account screenshot](shared-accounts.png), [report screenshot](admin-report.png). The account screenshot was visually inspected.

The initial RED test failed because getUser/listUsers did not exist. Intermediate checks found/fixed a text/UUID notification comparison. Initial unrestricted full-suite concurrency exhausted Node memory (4 worker failures); one Host-header harness assertion also failed because fetch did not send the overridden Host. Test concurrency is now bounded and the assertion uses native HTTP. An initial Chrome assertion ambiguously selected an option and status badge; it is now scoped to the table. A source scan initially mistook unrelated repair-draft sessionStorage for account persistence; it now targets account/token keys. These failures are resolved and not counted as final passes.

## Independent reviewer findings and resolutions

The implementing root acted as Agent 1; separate read-only correctness and security code reviewers plus a read-only test engineer inspected the work. Reviewers did not edit or spawn teams.

- Correctness: fixed text/UUID notification comparison; synchronized admin/shared teams; allowed safe deactivation with unchanged inactive-team membership. Final review: no actionable correctness findings.
- Security: restricted municipal shared-team assignment/listing to verified scope mappings; removed broad self-update RLS policy. Default denial, production block, safe response fields, secrets, migration conflicts and documented absent identity were reviewed. Final review: no actionable security findings.
- Tests: removed stale Auth-only recovery-browser runner; malformed percent-encoded account IDs now return 400 with regression coverage; bounded text-ID tests added. Final review: no blocking test findings. The linked verification report and architecture date were completed afterward.

## Skips, blockers and deployment risks

No hosted migration, account mutation, production deployment, real email/message, password reset or hosted Storage write was authorized/performed. Hosted read-only schema metadata is not live acceptance of changed behavior. Migration requires explicit separate authorization, backup, private collision inspection and mobile access checks. The migration may lock dependent tables while converting FK account columns; plan a maintenance window. Existing external consumers expecting a profile TABLE or UUID account columns need review. Identity collisions abort rather than merge different IDs by email. No automatic down migration is supplied; recovery requires reviewed backup/identity reconciliation. Supabase Auth's own existing identities are untouched.

Actual deployed mobile API integration/registration/credential enrollment/session enforcement remains unverified because that PostgreSQL mobile server implementation is not supplied in this working tree. Mobile/API consumers must continue checking active. Native device/Android end-to-end, maintenance-mobile runtime, full Flutter suite, hosted private Storage, load/race tests, production gateway/TLS, retention and backup/restore acceptance were not run. No independent Chrome DevTools MCP was available; installed Chrome/Playwright supplied browser verification. No standalone dead-code analyzer was configured; targeted import scans and TypeScript checking were used.

Only files inside C:/Users/Admin/Documents/ChatGPT/patag-ui were changed. No source, configuration or dependency was inspected/imported from the prohibited checkout. No secrets or ignored credential files were changed.

## Exact file inventory

M = modified, D = removed, A = added. All paths are within the permitted repository. Build output, npm cache and Chrome temporary profiles/downloads are generated ignored files inside this same repository.

| Status | Absolute path |
| --- | --- |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/.env.example |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/admin-web/.env.example |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/admin-web/README.md |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/admin-web/src/api.ts |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/admin-web/src/App.tsx |
| D | C:/Users/Admin/Documents/ChatGPT/patag-ui/admin-web/src/recovery.ts |
| D | C:/Users/Admin/Documents/ChatGPT/patag-ui/admin-web/src/ResetPassword.tsx |
| D | C:/Users/Admin/Documents/ChatGPT/patag-ui/admin-web/src/styles/login-redesign.css |
| D | C:/Users/Admin/Documents/ChatGPT/patag-ui/admin-web/tests/recovery-browser.mjs |
| D | C:/Users/Admin/Documents/ChatGPT/patag-ui/admin-web/tests/recovery.test.mjs |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/admin-web/tests/supabase-browser.mjs |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/.env.example |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/accounts.mjs |
| D | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/auth.mjs |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/config.mjs |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/db.mjs |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/queries.mjs |
| D | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/seed-admin.mjs |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/server.mjs |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/service.mjs |
| A | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/tests/account-boundaries.test.mjs |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/tests/accounts.test.mjs |
| D | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/tests/auth.test.mjs |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/tests/config.test.mjs |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/tests/database.mjs |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/tests/database.test.mjs |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/tests/evidence.test.mjs |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/tests/http.test.mjs |
| D | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/tests/mfa-recovery.test.mjs |
| D | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/tests/recovery.test.mjs |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/tests/regressions.test.mjs |
| D | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/tests/seed.test.mjs |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/tests/service.test.mjs |
| A | C:/Users/Admin/Documents/ChatGPT/patag-ui/backend/tests/shared-accounts.test.mjs |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/citizen-mobile/lib/core/api.dart |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/citizen-mobile/test/auth_test.dart |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/docs/api-contract.md |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/docs/architecture.md |
| A | C:/Users/Admin/Documents/ChatGPT/patag-ui/docs/backend-verification/shared-accounts-2026-10-29/admin-report.png |
| A | C:/Users/Admin/Documents/ChatGPT/patag-ui/docs/backend-verification/shared-accounts-2026-10-29/browser-results.json |
| A | C:/Users/Admin/Documents/ChatGPT/patag-ui/docs/backend-verification/shared-accounts-2026-10-29/README.md |
| A | C:/Users/Admin/Documents/ChatGPT/patag-ui/docs/backend-verification/shared-accounts-2026-10-29/shared-accounts.png |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/docs/decisions/0001-supabase-admin.md |
| A | C:/Users/Admin/Documents/ChatGPT/patag-ui/docs/decisions/0002-shared-postgresql-accounts.md |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/docs/environment.md |
| A | C:/Users/Admin/Documents/ChatGPT/patag-ui/docs/shared-account-schema.md |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/docs/supabase-backend.md |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/package.json |
| M | C:/Users/Admin/Documents/ChatGPT/patag-ui/README.md |
| A | C:/Users/Admin/Documents/ChatGPT/patag-ui/supabase/migrations/202610290001_shared_accounts.sql |
