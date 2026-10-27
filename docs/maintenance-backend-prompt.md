# Prompt: connect maintenance-mobile to the PATAG backend

Copy everything below the line into your AI coding assistant, run from the `patag-ui` repo root.

---

You are connecting **maintenance-mobile** (the Flutter road-crew app for PATAG, an IT 305 academic pothole-reporting system) to the real backend.

**Do not create a second backend.** `backend/` (Node 24 + TypeScript + Fastify, Supabase Postgres + Storage) already implements the shared contract for all roles, including `maintenance`. One API serves citizen-mobile, maintenance-mobile, admin-web and maintenance-web, because they share the same reports, teams and notifications. Your job:

1. Fix the maintenance app so its requests match the backend contract.
2. Make the small backend additions listed below.
3. Prove the crew workflow end to end with tests.

## Read first

- `docs/api-contract.md` (source of truth) and `docs/status-transitions.md`
- `backend/README.md`, `backend/src/app.ts`, `backend/src/domain.ts` (`transition()`), `backend/test/api.test.ts`
- `maintenance-mobile/lib/core/api.dart`: `PatagMaintenanceStore`, the HTTP client
- `maintenance-mobile/lib/core/models.dart`, `lib/features/screens.dart` (calls at roughly lines 89, 191, 209, 1202, 1232, 1262, 1714, 1735), `lib/shared/widgets/ui.dart` (`PhotoWidget`, ~line 440), `lib/main.dart` (routes)
- `citizen-mobile/lib/core/api.dart`: a client that already works against this backend, so follow its patterns (`photoUrl`, error handling, timeouts)

## What the maintenance app calls today

| App call | Sends | Backend expects | Result today |
|---|---|---|---|
| `POST /auth/login` | `email, password, role:"maintenance"` | same | ✅ matches |
| `POST /auth/demo` | `{role:"maintenance"}` | same (only if `ALLOW_DEMO=true`) | ✅ matches |
| `GET /bootstrap` | none | same; returns `reports` (team-scoped), `teams`, `notifications`, `user` | ✅ matches |
| `POST /uploads` | `data` (data URL), `name`, `kind` | same | ✅ matches, but see fallback bug #4 |
| `POST /reports/:id/events` `start_repair` | `{action:"start_repair", note}` | `action:"start"` | ❌ 409, then hidden by a local fake |
| `POST /reports/:id/events` `upload_evidence` | `{action:"upload_evidence", photo:{…}, note}` | `{action:"before-photos", photos:[…]}` | ❌ 409, then hidden by a local fake |
| `POST /reports/:id/events` `complete` | `{action:"complete", note, photos:[…]}` | same | ⚠️ matches, but the fallback fakes "Resolved" |
| `POST /auth/logout` | `{}` | same | ✅ matches |
| `POST /notifications/read` | never called | `{id}` or `{id:"all"}` | ❌ notifications never get marked read |

## Part 1: fix maintenance-mobile (client)

Fix these in `lib/core/api.dart`, `screens.dart` and `ui.dart`:

1. **Remove every fake/offline fallback.** They hide real errors and show invented data:
   - `authenticate()` calls `_setDemoSession()` on **any** error, so a wrong password or a server that's down still "logs in". Remove that branch: on failure, rethrow so the login screen shows the error.
   - `demoLogin()` falls back to `_setDemoSession()`. Remove it and show the error instead (demo login needs `ALLOW_DEMO=true` on the backend).
   - `refresh()` swallows errors, sets `networkError = null` and injects demo data. Instead set `networkError = clean(e)` and rethrow, as citizen-mobile does.
   - `event()` mutates reports locally on failure (`start_repair` → In Progress, `complete` → **Resolved**, which crews can never do). Remove it: rethrow so the screen shows the server's message, and only change state after a successful response plus `refresh()`.
   - `upload()` returns a `data:` URL on failure. The backend rejects data URLs as evidence, so remove it and rethrow.
   - Delete `_setDemoSession()` and the hard-coded IDs (`team-alpha`, `usr-maintenance-1`, `crew@malolos.gov.ph`), which don't exist in the database (seed IDs are `team-1`, `maintenance-1`, `crew@example.test`).
2. **Use the contract's action names:**
   - Start repair: `{action:"start", note}` (status `Assigned` → `In Progress`).
   - Before photo: `{action:"before-photos", photos:[uploadedPhoto]}`. Allowed while `Assigned` or `In Progress`, not while awaiting verification.
   - After photo: there is no separate "after photo" event. Collect after photos in the completion screen and send them with `{action:"complete", note, photos:[…]}`. The note and at least one photo are required. Status stays `In Progress` and `completion.state` becomes `Awaiting Verification`; only the LGU admin can resolve. Change the "Add After Photo" button on the task screen to open the completion screen, or have it add a progress update instead (see Part 2).
   - Optional progress notes: `{action:"progress", phase, note, photos?}`.
3. **Show success only after the server confirms it.** "Repair submitted" means "sent for LGU verification", not "resolved". The progress bar and history must read `status` + `completion.state` from the server.
4. **Show server photos.** `PhotoWidget` only renders `data:` URLs. Add `photoUrl(path)` like citizen-mobile (`<API base without /api>/api<path>`) and use `Image.network` for `/uploads/...` and `/demo-*.svg` URLs, with an error placeholder. Note: Flutter's `Image.network` cannot render SVG, so keep the placeholder for `.svg`.
5. **Timeouts:** raise the request timeout from 4 s to 20 s. An 8 MB photo is about 11 MB of base64 and will not upload in 4 s on mobile data.
6. **Uploads:** reject file types other than PNG/JPEG/WebP before uploading, as citizen-mobile does. The current code labels unknown types as JPEG, which the server then rejects by magic bytes.
7. **Notifications:** when one is tapped, call `POST /notifications/read` with `{id}` and open `/assignments/<reportId>`. Add a "Mark all read" action that sends `{id:"all"}`. Refresh after both.
8. **Session expiry:** the existing 401 handling (clear state) is correct. Also navigate to `/login` when it happens.
9. Keep the API URL as a compile-time define: `--dart-define=API_URL=http://10.0.2.2:4100/api` on the emulator. On Flutter web it uses `http://127.0.0.1:4100/api`.

## Part 2: backend additions (`backend/`)

Keep the existing contract; do not rename actions to match the old app.

1. **CORS for Flutter web:** `flutter run -d chrome` serves from a random localhost port. Allow `CORS_ORIGINS` entries with a wildcard port for localhost only (e.g. `http://localhost:*`, `http://127.0.0.1:*`), off by default and documented in `.env.example`. Never use `*` in production.
2. **Progress photos:** make sure `progress` events validate their photos as real uploads (already done) and store them with `kind:"before"`/`"after"` correctly. Accept an optional `kind` on progress photos (default `after`).
3. **Crew notifications:** confirm that maintenance users get a notification when a report is assigned to their team and when the admin returns work ("Additional Work Requested"), with a clear title such as `PTG-2026-0103 assigned to Road Crew Alpha` / `PTG-2026-0103: more work requested`. Today the title for every event is `<id>: <status>`. Improve the titles per action without changing the notification shape `{id, reportId, title, at, read}`.
4. **Bootstrap for crews:** maintenance users must receive only their team's reports (already true) and their own team in `teams` with `members`. Check that a crew member whose team was deactivated, or who was moved to another team, sees the right data on the next poll.
5. Do **not** add `start_repair` / `upload_evidence` aliases. One contract, fixed in the client.

## Part 3: tests

- **Backend** (`backend/test/`, uses the embedded PGlite Postgres): add `maintenance.test.ts` covering the exact sequence the app performs:
  1. crew login with `role:"maintenance"`, and rejection of a citizen account logging into the maintenance portal
  2. bootstrap is team-scoped, so another team's report returns 403 on `GET /reports/:id`
  3. upload → `before-photos` (Assigned) → `start` → `progress` → `complete` without photos (400) → `complete` with photos → status `In Progress` + `Awaiting Verification` → crew `resolve` returns 409
  4. admin `return` → crew gets a notification → crew completes again → admin `resolve`
  5. `POST /notifications/read` for one id and for `all` only affects that crew's notifications
  6. unknown action (`start_repair`) returns 409 with a JSON `{error}`

  Run `npm test` in `backend/` and show the output.
- **Flutter** (`maintenance-mobile/test/`): unit-test `PatagMaintenanceStore` with `package:http/testing.dart` `MockClient` (inject the client). Cover: login error is shown (no fake session), `event()` sends `start`/`before-photos`/`complete` with the right bodies, a failed event leaves local state unchanged, a 401 clears the session. Run `flutter analyze` and `flutter test`, and show the output.

## Done when

- `npm test` (backend) and `flutter analyze` + `flutter test` (maintenance-mobile) pass.
- With the backend running (`npm run api`, `ALLOW_DEMO=true` locally, after `npm run seed`), this works on the Android emulator:
  `cd maintenance-mobile` then `flutter run --dart-define=API_URL=http://10.0.2.2:4100/api`.
  Log in as the demo crew, start PTG-2026-0104, add a before photo, complete with an after photo, and see "Awaiting verification". Admin-web then shows it ready to resolve; after resolving, the crew app shows Resolved on the next poll.
- No fake data, local status changes or `data:` evidence URLs remain in maintenance-mobile.
- Summarize every file changed. If any contract change seems necessary, list it and ask before making it.
