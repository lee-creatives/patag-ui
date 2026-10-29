> Earlier snapshot: the temporary no-login/local mode is superseded by [shared PostgreSQL login](0003-shared-account-login.md). Earlier test results remain historical evidence.

# ADR-0002: Use shared PostgreSQL application accounts

Date: 29 October 2026. Supersedes ADR-0001 identity decisions; report workflow and private Storage remain.

The user identified public.users as mobile's authoritative table. Read-only hosted metadata verified its text IDs, admin/citizen/maintenance roles, credential/address fields and unique lower(email) index. The former UUID patag_profiles/auth.users pair created a separate boundary and excluded mobile-created accounts.

Use public.users directly for admin account reads/writes. Replace patag_profiles with a security-invoker compatibility view, convert dependent account FK columns to text and preserve shared rows/credentials/IDs. Abort identity conflicts rather than guess or overwrite mobile records. Do not rewrite the checksummed original migration. Do not add a second identity provider or duplicate profile store.

Removing Auth removes authentication. Workspace access defaults to disabled and production remains blocked. Explicit local review chooses an existing administrator only from private server configuration; it does not verify the operator. Production needs a separately designed, verified existing identity/authorization boundary before exposure. Preserve RLS scopes, field validation, uniqueness, transactional audit and private Storage credentials. No deployed migration or account mutation is part of implementation verification.

No Edge Functions or Realtime implementation exists to retain or remove. Existing polling remains independent of both. Future functions/subscriptions must operate on shared PostgreSQL data with server-validated authorization and minimal invalidations; endpoint references do not establish functionality.

See [schema](../shared-account-schema.md), [setup/risks](../supabase-backend.md) and [verification](../backend-verification/shared-accounts-2026-10-29/README.md).
