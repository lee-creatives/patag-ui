# ADR-0003: Restore login using the existing shared mobile contract

29 October 2026. Supersedes ADR-0002's temporary local/no-identity operating mode, preserving its public.users single source of truth and Auth-removal decision.

The user expects normal administrator login. Code in this repository's local Citizen-mobile-Backend and Maintenance_Mobile-Backend branches already defines NFKC scrypt32768/8/1 credentials and SHA-256 opaque-token public.sessions with eight-hour expiry. Reuse those contracts rather than invent another account system or require account-ID environment configuration. Deliver the admin token through an HttpOnly SameSite=Strict cookie, Secure with HTTPS. Verify current account/session/role inside actual operation transactions; revoke shared sessions when access changes.

The constraint screenshot was an unapplied-migration mismatch: legacy UUID patag_profiles remained a table while shared account IDs are text. Fail with explicit schema-required503 before account queries. Preserve the immutable original migration and require approval before hosted application.

The user confirmed the colliding legacy/shared administrators are different. An explicit one-time distinct legacy email option preserves both IDs and report relationships atomically with the upgrade; no merge or existing mobile credential overwrite occurs. Password initialization is a guarded private command for an existing active admin with NULL credential only. Real personal emails/passwords are not committed to source.

This provides basic shared credential authentication, not verified production security. MFA, email recovery, reset, hosting/gateway/TLS, deployed mobile acceptance and load testing remain follow-ups. No hosted migration, account rename or password setup was performed during implementation.
