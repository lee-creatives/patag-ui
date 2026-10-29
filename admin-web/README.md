# PATAG admin web

React/TypeScript/Vite admin using the Node PostgreSQL API at /api. Normal email/password login uses the existing mobile public.users password format and public.sessions, with an HttpOnly cookie. No Supabase Auth, account-ID environment selection or local bypass is used. Account fields and roles are checked server-side; missing/expired/revoked sessions return to /admin/login.

See [setup and pending migration](../docs/supabase-backend.md), [verified account schema](../docs/shared-account-schema.md), and [latest verification](../docs/backend-verification/shared-login-2026-10-29/README.md). The hosted database must complete the reviewed upgrade; an active shared admin needs a password configured privately.

npm run dev starts Vite. npm run build checks TypeScript and bundles. npm run lint uses oxlint. From the repository root npm run test:browser uses installed Chrome, actual built admin and isolated PostgreSQL accounts without Supabase Auth. Existing polling and private Storage remain; no Realtime/Edge Function source exists here.
