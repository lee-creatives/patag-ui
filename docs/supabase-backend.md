# Shared PostgreSQL admin login — 29 October 2026

PostgreSQL public.users remains the sole mobile/admin account store. Supabase Auth is not used. The admin now has ordinary email/password login using the existing mobile backend's credential and public.sessions contract, verified from both local Citizen-mobile-Backend and Maintenance_Mobile-Backend branches. There is no second identity provider, account copy, profile store or browser account-store fallback.

## Login and access

Open /admin/login and sign in with an existing active public.users account whose role is admin and whose password_hash is configured. No account-ID environment setting is needed. PATAG_LOCAL_ADMIN_ID and PATAG_ALLOW_UNAUTHENTICATED_LOCAL_ADMIN are ignored; the former unauthenticated local mode is removed. Anonymous workspace requests return 401 and redirect to login.

Passwords use the existing mobile format: NFKC normalization, scrypt N=32768/r=8/p=1, 16-byte salt, 64-byte key. The verifier bounds parameters and encodings and uses dummy work for absent/invalid credentials. Wrong credentials, inactive accounts, non-admin roles and missing hashes return the same login failure. No password or token is returned to browser JavaScript or saved in browser storage.

A random 32-byte opaque token is delivered in an HttpOnly SameSite=Strict cookie scoped to /api, Secure when ADMIN_ORIGIN uses HTTPS. Only its SHA-256 hash is stored in existing public.sessions with the shared text user ID and eight-hour expiry. Logout deletes that session and clears the cookie. Protected operations lock/recheck the current active admin and live session inside the actual SQL transaction. Deactivation or role changes revoke all sessions for the target account, including mobile sessions, so re-enabling does not revive old tokens. Existing server-side municipality/team/owner checks and RLS still apply. CSRF Origin/header checks and bounded PostgreSQL rate limits remain.

This restores basic credential authentication; it is not a production-security acceptance claim. MFA, email recovery, password reset, production gateway/TLS, session retention cleanup, monitoring and multi-connection load testing remain separate work. Supabase Auth passwords do not automatically become application password_hash credentials.

## Why the reported constraint error occurred

Hosted read-only inspection found only the original admin migration applied, with UUID public.patag_profiles still an ordinary table, while the configured shared user ID is text. The previous generic 400 hid that deployment mismatch. Current API readiness checks reject the old schema with explicit 503 explaining that 202610290001_shared_accounts.sql is required, before actor queries or credential checks. The UI labels this as a setup problem. It does not cast/rewrite mobile IDs or silently use another database.

## Pending hosted upgrade and separate administrators

The original 202610270001_admin.sql checksum remains unchanged. The pending 202610290001_shared_accounts.sql copies compatible legacy-only accounts while preserving IDs, converts dependent account FKs to text users IDs, and replaces patag_profiles with a security-invoker compatibility view. It preserves existing mobile credentials, IDs, address fields and email verification; profile projection stores no data. It also adds the scoped shared-team policies required by the actual mobile schema's enabled RLS, hardens shared-session access, and provides scoped session revocation for admin account updates.

A read-only preflight found one legacy/shared email collision. The user confirmed these are different administrators, so they MUST NOT be merged. migrate(pool,{legacyAdminEmail}) or process-only PATAG_LEGACY_ADMIN_EMAIL explicitly supplies a distinct address for exactly one conflicting legacy administrator. The runner validates the address is unused, updates only that legacy profile inside the upgrade transaction, and preserves both IDs and legacy report relationships. Every original conflict remains an error unless specifically resolved. No real personal address is committed to source/configuration examples.

No hosted upgrade, account rename, password initialization or deployment has been performed for this fix. The proposal needs explicit authorization under the user's hosted-migration restriction. Review the SQL and back up first; conversion may lock tables, and existing direct Data API consumers lose browser grants. Old external consumers expecting a profile TABLE/UUID account columns must be reviewed. The original mobile server uses trusted backend database access; no browser receives credentials. Recovery from a deployed schema change requires a reviewed backup plan, not a blind down migration.

After explicit approval, run from this repository with private credentials already configured:

~~~powershell
$env:NODE_EXTRA_CA_CERTS = "$PWD/backend/certs/supabase-prod-ca-2021.crt"
$env:PATAG_ALLOW_HOSTED_MUTATIONS = 'true'
$env:PATAG_LEGACY_ADMIN_EMAIL = Read-Host 'Approved distinct legacy administrator email'
try { npm run db:migrate }
finally {
  $env:PATAG_ALLOW_HOSTED_MUTATIONS = 'false'
  Remove-Item Env:PATAG_LEGACY_ADMIN_EMAIL -ErrorAction SilentlyContinue
}
~~~

## Initialize a missing administrator password privately

The existing shared administrator inspected has no password_hash. A null hash is not a valid login and is never treated as a passwordless administrator. npm run admin:set-password reuses the mobile hash format, changes only an existing active admin whose hash is NULL, refuses overwrites/promotions/account creation, and revokes that account's former sessions atomically. It also requires explicit hosted-mutation authorization and a completed schema upgrade.

Use the existing administrator email you intend to log in with. Do not send a password in chat or store it in source. This runs only after approving the target account and hosted credential initialization:

~~~powershell
$credential = Get-Credential -Message 'Set the initial PATAG administrator password'
$env:ADMIN_EMAIL = $credential.UserName
$env:ADMIN_PASSWORD = $credential.GetNetworkCredential().Password
$env:PATAG_ALLOW_HOSTED_MUTATIONS = 'true'
try { npm run admin:set-password }
finally {
  Remove-Item Env:ADMIN_EMAIL, Env:ADMIN_PASSWORD -ErrorAction SilentlyContinue
  $env:PATAG_ALLOW_HOSTED_MUTATIONS = 'false'
  $credential = $null
}
~~~

Use 15–128 characters. An existing password is never reset by this command. No real password was chosen or initialized by the agent.

## Start and verify

Required private server configuration remains SUPABASE_URL, SUPABASE_DB_URL, SUPABASE_SERVICE_ROLE_KEY and ADMIN_ORIGIN. The service key is retained only for private evidence Storage; no publishable/Auth key is needed. Keep TLS verification enabled and real secrets out of VITE_* variables. API defaults to /api; Vite proxies to loopback:4101. Configure exact ADMIN_ORIGIN; production requires HTTPS. Start npm run dev:api and npm --prefix admin-web run dev, then use /admin/login. Existing local-bypass variables can be removed; they no longer select or authorize an account.

No Edge Functions or Supabase Realtime implementation exists in this checkout. Neither was added or removed. Existing five-second PostgreSQL API polling remains, with failures/recovery and no sensitive broadcasts. Private evidence Storage and current report workflows remain. [Schema](shared-account-schema.md), [current API](api-contract.md), [login decision](decisions/0003-shared-account-login.md), [new verification](backend-verification/shared-login-2026-10-29/README.md).
