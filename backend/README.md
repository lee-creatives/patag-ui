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

The API listens on `http://127.0.0.1:4100/api`. Migrations are applied automatically at startup.

Clients:

```powershell
# Flutter (Android emulator)
cd citizen-mobile
flutter run --dart-define=API_URL=http://10.0.2.2:4100/api

# Web portals: unchanged, they default to http://127.0.0.1:4100/api
cd admin-web; npm run dev
cd maintenance-web; npm run dev
```

To use the "Continue as ..." demo buttons in the web portals or demo citizen login, set `ALLOW_DEMO=true` in `backend/.env` **on your own PC only** and run `npm run seed`.

Physical Android phone over USB: `adb reverse tcp:4100 tcp:4100`, then `--dart-define=API_URL=http://127.0.0.1:4100/api`.

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
