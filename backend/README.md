# PATAG backend

Node.js 24 + TypeScript + Fastify API backed by **Supabase Postgres** (data) and **Supabase Storage** (evidence photos). It implements [docs/api-contract.md](../docs/api-contract.md) and [docs/status-transitions.md](../docs/status-transitions.md) exactly, so the Flutter citizen app, admin-web and maintenance-web work with it **unchanged**. It replaces `dev-mock/` (which stays available as `npm run demo:api`).

TypeScript runs directly through Node 24's built-in type stripping. There is no build step.

## Setup (once)

1. Install dependencies:

   ```powershell
   cd backend
   npm install
   ```

2. Create `backend/.env` from the template and fill in the two secrets:

   ```powershell
   copy .env.example .env
   ```

   - `SUPABASE_DB_PASSWORD`: Supabase dashboard → **Database → Settings → Database password** (reset it there if unknown).
   - `SUPABASE_SECRET_KEY`: Supabase dashboard → **Project Settings → API Keys → Secret keys** (`sb_secret_...`). A legacy `service_role` key also works.

   `backend/.env` is git-ignored. Do not put these values anywhere else.

3. Create the tables, the private photo bucket and (optionally) the fictional demo data:

   ```powershell
   npm run migrate
   npm run setup:storage
   npm run seed
   ```

4. Create a real LGU administrator (seeded demo accounts have no password):

   ```powershell
   $env:ADMIN_NAME="Your Name"; $env:ADMIN_EMAIL="you@example.com"; $env:ADMIN_PASSWORD="at least fifteen characters"; npm run create-admin
   ```

   The admin can then create maintenance teams and crew accounts from admin-web.

## Run

```powershell
npm run dev          # from backend/ (restarts on file changes)
npm run api          # same, from the repo root
```

The API listens on `http://127.0.0.1:4100/api`. Migrations are applied automatically at startup. Keep this terminal open while you use the apps. If an app says "Connection timed out" or "Can't reach the PATAG server", the backend isn't running.

The mobile apps never talk to Supabase directly: they call this API, which holds the secrets and enforces the workflow. Each app's `env/` folder holds the API address per device ([citizen-mobile/env/README.md](../citizen-mobile/env/README.md)).

## Connect a phone or emulator

Run these from the repo root, then the `flutter` command inside `citizen-mobile/` or `maintenance-mobile/`. Use `C:\flutter\bin\flutter` if `where flutter` still shows `C:\Moble dev\flutter` (that path's space breaks builds).

| Device | Backend | App |
|---|---|---|
| Android emulator | `npm run api` | `flutter run --dart-define-from-file=env/emulator.json` |
| Phone on USB (USB debugging on) | `npm run api` and `npm run mobile:usb` | `flutter run --dart-define-from-file=env/usb.json` |
| Phone on the same Wi-Fi | `npm run api:lan` (prints the LAN URL) | copy `env/lan.example.json` to `env/lan.json`, put that URL in it, then `flutter run --dart-define-from-file=env/lan.json` |

For Wi-Fi phones, Windows Firewall must allow port 4100 on **private** networks. Run once in an **admin** PowerShell:

```powershell
New-NetFirewallRule -DisplayName "PATAG API (dev)" -Direction Inbound -Protocol TCP -LocalPort 4100 -Profile Private -Action Allow
```

Your Wi-Fi must be set to "Private" in Windows settings. Remove the rule later with `Remove-NetFirewallRule -DisplayName "PATAG API (dev)"`. On a network you don't control (school, café), use USB instead.

Web portals are unchanged: they default to `http://127.0.0.1:4100/api` (`cd admin-web; npm run dev`, `cd maintenance-web; npm run dev`).

## Accounts

| Who | How |
|---|---|
| Citizens | Register in the citizen app (saved to Supabase immediately). |
| LGU administrator | `npm run create-admin` (see Setup step 4). |
| Maintenance crews | The admin creates teams and crew accounts in admin-web. Crews sign in to maintenance-mobile with that email and password. |
| Seeded demo accounts | Fictional, **no passwords**. They only work through the "demo"/"Continue as…" buttons when `ALLOW_DEMO=true` on a backend running on your own PC. The server refuses `ALLOW_DEMO=true` together with `npm run api:lan` unless you also set `ALLOW_DEMO_ON_LAN=true` (trusted classroom network only). |

The Supabase project in `.env` is the **production** project (`main / PRODUCTION`): everything you create while testing is real data. Consider creating a second Supabase project for testing and pointing a copy of `.env` at it.

## Check the connection

```powershell
npm run smoke                                   # read-only: /health is "supabase", public reports load
npm run smoke -- --url https://<host>/api       # against a hosted backend
npm run smoke -- --write                        # ALSO creates a test citizen + one report (real data, not deleted)
```

The full walkthrough is in [docs/mobile-supabase-checklist.md](../docs/mobile-supabase-checklist.md).

## Deploy (Render)

Render was chosen because it runs this Dockerfile on a free web service with HTTPS and health checks, has a Singapore region near the Philippines, and reads a [render.yaml](../render.yaml) blueprint from the repo. Railway and Fly.io need a paid plan or card for always-on use.

1. Push this branch to GitHub. In Render: **New → Blueprint**, pick the repo, and it reads `render.yaml`.
2. Render asks for the values marked `sync: false`:
   - `SUPABASE_SECRET_KEY` and `SUPABASE_DB_PASSWORD`: same as your `backend/.env`.
   - `SUPABASE_DB_CA_CERT`: paste the **contents** of the Supabase CA file (Dashboard → Database → Settings → SSL → Download certificate).
   - `CORS_ORIGINS`: your deployed admin/maintenance web URLs, or leave empty if only the mobile apps use it.
3. Wait for the deploy, then run `npm run smoke -- --url https://<your-service>.onrender.com/api`.
4. Put that URL in each app's `env/prod.json` and build: `flutter build apk --release --dart-define-from-file=env/prod.json`. Release builds only allow HTTPS (cleartext is enabled in the **debug** manifest only).

The **free** plan sleeps after about 15 minutes idle; the first request then takes about a minute. The apps show "Connecting to PATAG… A server that was asleep can take up to a minute." while it wakes. For a demo or defense, open the app a minute early, or switch the service to the Starter plan.

`TRUST_PROXY=1` is set in the blueprint so the login rate limit counts each real client behind Render's load balancer. Locally, leave it unset.

## Tests

```powershell
npm test
```

The tests run every SQL statement and migration against an embedded Postgres (PGlite), with no Supabase connection needed. They port the `dev-mock` test cases and add coverage for duplicates, upload validation, JSON errors, CORS, body limits and session revocation. `npm run typecheck` runs the TypeScript compiler.

## Design notes

| Area | Choice |
|---|---|
| Layout | `src/app.ts` routes and validation · `src/domain.ts` workflow, privacy projection, field rules · `src/store.ts` all SQL · `src/db.ts` pg adapter and migrations · `src/blobs.ts` Supabase Storage |
| Schema | `migrations/001_init.sql`. Report sub-records (photos, history, updates, completion, feedback, assignment) are `jsonb` columns on `reports`: they are always read and written with their report, which keeps the contract shape exact. Users, sessions, teams, uploads and notifications are relational. |
| Concurrency | Every workflow event locks its report row (`select … for update`) inside a transaction together with its notifications. |
| Sessions | Opaque 256-bit random tokens; only SHA-256 hashes are stored. Sessions expire after 8 h, are revoked on logout, and are revoked immediately when an admin disables the account. Supabase Auth was not used because the clients expect this API's `{token, user}` login contract and role model. |
| Passwords | scrypt (N=2¹⁵, r=8, p=1) via Node's crypto. Memory-hard and needs no native build. Login runs the same hash work for unknown emails. |
| Photos | PNG/JPEG/WebP ≤ 8 MB, verified by magic bytes, stored in the private `report-photos` bucket under random UUID names. Served through `GET /api/uploads/:file` without auth (as the contract requires for `Image.network`/`<img>`); the UUID is the capability. Reports and events only accept photos that were actually uploaded. |
| Database access | RLS is enabled on every table with no policies, and `anon`/`authenticated` privileges are revoked. Supabase's public Data API cannot read anything; only this backend (as the database owner) can. |
| Rate limiting | Login and registration: 20 requests/min per IP and endpoint, in memory. Use a shared store if you run several instances. |
| Not included | Real email delivery for `/auth/recovery` (it returns a generic message), push notifications (clients poll), server-side CSV/PDF export. |
