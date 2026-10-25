# Prompt: build the PATAG backend

Copy everything below the line into your AI coding assistant, run from the `patag-ui` repo root.

---

You are building the production-style backend for **PATAG** ("Pa-tag lubak, lubak patag"), an IT 305 academic pothole-reporting system. The repo already contains the clients; your job is the server they talk to.

## Context you must read first

- `citizen-mobile/lib/core/api.dart`: the Flutter citizen app's HTTP client (`PatagStore`). This defines what the backend MUST return.
- `citizen-mobile/lib/core/models.dart`, `citizen-mobile/lib/core/domain.dart`: Dart models.
- `citizen-mobile/lib/features/screens.dart`, `report_wizard.dart`: call sites and request bodies.
- `docs/api-contract.md`: the JSON contract v1 (endpoints, models, error codes, event actions). **This is the source of truth.**
- `docs/status-transitions.md`: the report workflow state machine.
- `docs/supabase-connection.md`: the existing Supabase project and env-var rules.
- `dev-mock/server.mjs`, `dev-mock/domain.mjs`, `dev-mock/*.test.mjs`: the current local mock API. Your backend replaces it. Reuse its tests as behavioral spec.
- `admin-web/` and `maintenance-web/` API adapters: they use the same API, so keep them working too.

## Goal

Create a new `backend/` folder with a Node.js (TypeScript) HTTP API that implements **the exact contract in `docs/api-contract.md`**, so that the Flutter app, admin-web and maintenance-web work **without any client changes** by pointing them at it:

- Base path `/api`, default port **4100** (Flutter uses `http://10.0.2.2:4100/api` on the emulator).
- Persistence: the existing **Supabase** project (Postgres + Storage). Do not use local JSON files.
- Framework: Fastify or Express with `zod` validation; `pg` or `@supabase/supabase-js` with a **server-side** secret key.

## Hard requirements from the Flutter client

1. **Auth responses** for `/auth/login`, `/auth/register`, `/auth/demo` return `{ token, user }`, where `user.role` is `"citizen" | "admin" | "maintenance"`. The app rejects non-citizen users itself. Requests send `Authorization: Bearer <token>`.
2. **Errors** are always JSON `{ "error": "Human readable message" }` with codes 400/401/403/404/409/413. On **401** the app logs the user out, so only return 401 for missing, expired or revoked sessions.
3. **Every response body must be valid JSON**, including logout and success responses (the client always calls `jsonDecode`).
4. Requests are JSON only. GET is used when there is no body, POST when there is a body, and PATCH only for `/me`.
5. The app polls `GET /bootstrap` and `GET /public/reports` **every 8 seconds**, so keep both fast and indexed.
6. Request timeout is 20 s.

### Endpoints the citizen app calls (must match exactly)

| Call | Body | Must return |
|---|---|---|
| `POST /auth/register` | `name, email, password, role:"citizen", address{line?, barangay, city, province}` | `{token, user}`. Always creates an active citizen; ignore injected role/team/active. |
| `POST /auth/login` | `email, password, role?` | `{token, user}`. If `role` is given it must match the account. |
| `POST /auth/demo` | `{role, userId?}` | `{token, user}`. **Only when `ALLOW_DEMO=true`**; 404 otherwise. |
| `POST /auth/recovery` | `email` | `{message}`. Same generic message whether or not the email exists. |
| `POST /auth/logout` | `{}` | `{}` or `{ok:true}`. Revokes the token. |
| `GET /bootstrap` | none | `{user, reports[], notifications[], teams[], statuses[], settings{agency,city,province}}`, scoped by role (citizen: own reports; team: team's; admin: all). |
| `GET /public/reports` | none (no auth) | Array of privacy-safe reports. Exclude Rejected/Duplicate, reporter identity, assignment, internal notes, landmark, feedback, and unapproved photos. |
| `POST /uploads` | `data` (data URL, base64 PNG/JPEG/WebP, ≤ 8 MB), `name`, `kind` | `ReportPhoto {id, url:"/uploads/<uuid>.<ext>", name, kind}` |
| `GET /uploads/:file` | none | The image bytes. The client builds `<API_BASE>/uploads/...`. |
| `POST /duplicates` | report draft (uses `location`, optional `id`) | `[{report, distance}]`: same road and ≤ 150 m haversine; never auto-merge. |
| `POST /reports` | `title, description, hazards, severity, photos[], location{road, barangay, city, province, landmark, coordinates{lat,lng}}` | Created report incl. `id` (format like `PTG-2026-0102`). Server sets reporter, `Submitted`, history, jurisdiction from settings. |
| `POST /reports/:id/feedback` | `rating 1..5, text` | Owner only, status Resolved, once only. |
| `POST /notifications/read` | `{id}` or `{id:"all"}` | Updated result |
| `PATCH /me` | `name, email, address?` | Updated user. Email change is not allowed without verification (400). |

The app reads these fields from each report: `id, title, description, status, severity, createdAt, location.{road,barangay,city,province,coordinates.{lat,lng}}, photos[].{url,name}, history[].{at,note,…}, completion, feedback`. It reads these from each notification: `id, reportId, title, at, read`. From the user: `name, email, address`.

### Also implement (used by admin-web / maintenance-web)

`GET /health`, `GET /reports/:id`, `POST /reports/:id/events` (actions: review, verify, reject, flag, duplicate, forward, assign, start, progress, complete, return, resolve, before-photos, publication), `PATCH /users`, `POST /users`, `POST /teams`, `PATCH /teams`, `PATCH /settings`, `GET /auth/demo/accounts` (demo only). Follow the payloads in `docs/api-contract.md`.

## Business rules

- **Status values** (exact strings): `Submitted, Under Review, Verified, Assigned, In Progress, Resolved, Rejected, Duplicate`. Severity: `Low, Medium, High`.
- Enforce `docs/status-transitions.md` exactly. Return **409** for invalid transitions and **403** when the role or ownership is wrong. Maintenance can never resolve. "Awaiting Verification" is a `completion.state`, not a status.
- Append a `ReportHistoryEntry {id, at (ISO UTC), actor, action, from, to, note}` on every action, and create scoped notifications (citizen on status changes, team on assign/return, admin on submit/complete).
- Validation: name 1–100 characters, email normalized and ≤ 254 characters, password 15–128 characters, coordinates finite and in range, photos ≤ 8 MB with real magic-byte check (not just extension). Citizens cannot submit seed/demo photos as evidence.
- Passwords: argon2id or bcrypt. Never return hashes.
- Sessions: opaque random tokens stored hashed in the DB (or Supabase Auth JWTs if you choose; justify the choice). Expire after **8 h**, revoke on logout.
- Rate limit `/auth/login` and `/auth/register` to 20 requests/min per IP.
- New before/after photos reset public photo approval. Only admin `publication` approval makes photos public.

## Database (Supabase Postgres)

Write SQL migrations in `backend/migrations/`. Suggested tables: `users`, `sessions`, `teams`, `team_members`, `reports`, `report_photos`, `report_history`, `report_updates`, `report_completion`, `report_feedback`, `notifications`, `settings`. Use `uuid` PKs (keep the human `PTG-YYYY-NNNN` report code as a unique column), `timestamptz`, `CHECK` constraints for enums, and indexes on `reports(reporter_id)`, `reports(team_id)`, `reports(status)`, `notifications(user_id, read)`. Enable RLS on all tables and deny anon access; the backend connects server-side. Store images in a private Storage bucket `report-photos`, served through `GET /uploads/:file`.

Include a seed script with fictional data only: 1 admin, 2 maintenance teams with crew accounts, a few citizens and reports around Malolos, Bulacan, matching the current `dev-mock/data` fixtures.

## Configuration and secrets

- Read `SUPABASE_URL`, `SUPABASE_PROJECT_REF`, `SUPABASE_DB_*` from env. Put the DB password and `SUPABASE_SECRET_KEY` only in `backend/.env` (git-ignored) and document them in `backend/.env.example` with placeholders.
- Never put secrets in Flutter `--dart-define`, `VITE_*` vars, the root `.env.local`, logs or commits.
- Env flags: `PORT=4100`, `HOST` (default `127.0.0.1`; `0.0.0.0` for LAN devices), `ALLOW_DEMO=false`, `CORS_ORIGINS=http://127.0.0.1:5173,http://127.0.0.1:5174`.

## Deliverables

1. `backend/` with source, migrations, seed, `.env.example`, and a `README.md` covering setup and run (`npm install`, `npm run migrate`, `npm run seed`, `npm run dev`).
2. Tests (Vitest or `node:test` + supertest): port the cases in `dev-mock/server.test.mjs` and `dev-mock/project2.test.mjs`, plus tests for auth, every transition (valid and invalid), ownership/403, public-report privacy filtering, upload validation and duplicate detection.
3. A root `package.json` script `"api": "npm --prefix backend run dev"`.
4. Confirm by running the tests and showing the output. Then confirm the Flutter app works unchanged with:
   `flutter run --dart-define=API_URL=http://10.0.2.2:4100/api`

Do not modify the Flutter app, admin-web or maintenance-web unless a contract mismatch forces it. If one does, list each mismatch and ask before changing a client.
