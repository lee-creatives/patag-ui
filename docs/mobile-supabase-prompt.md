# Prompt: connect the mobile apps to Supabase (end to end)

Copy everything below the line into your AI coding assistant, run from the `patag-ui` repo root.

---

You are making the two PATAG Flutter apps (`citizen-mobile` and `maintenance-mobile`) work end to end against the **existing Supabase project**, on the Android emulator, on a real phone, and from a hosted backend. PATAG is an IT 305 academic pothole-reporting system.

## Architecture: keep it, do not bypass it

```
citizen-mobile ─┐
maintenance-mobile ─┼─ HTTPS/JSON ─→ backend/ (Node, Fastify) ─→ Supabase Postgres + Storage
admin-web ─┤                         holds the secrets,
maintenance-web ─┘                         enforces roles & workflow
```

- The apps talk **only** to `backend/` through `API_URL`. The backend already stores everything in Supabase (verified: tables migrated, 12 seed reports, private bucket `report-photos`).
- **Do not add `supabase_flutter` or any Supabase key to the Flutter apps.** RLS is deny-all on purpose; the workflow rules (who can verify, assign, complete, resolve) live in `backend/src/domain.ts`; and anything inside an APK can be extracted. If you believe direct Supabase access is needed for something, stop and explain why before doing it.
- Do not change the JSON contract (`docs/api-contract.md`) or the backend's business rules.

## Read first

- `backend/README.md`, `backend/.env.example`, `backend/src/config.ts`, `backend/src/index.ts`
- `docs/api-contract.md`, `docs/status-transitions.md`, `docs/supabase-connection.md`
- `citizen-mobile/lib/core/api.dart` and `maintenance-mobile/lib/core/api.dart` (both read `API_URL` via `--dart-define`; defaults `http://10.0.2.2:4100/api`)
- Each app's `android/app/src/main/AndroidManifest.xml` and `android/app/src/debug/AndroidManifest.xml` (cleartext HTTP is allowed in **debug only**)

The Flutter SDK is used from `C:\flutter` (a junction, because the real path `C:\Moble dev\flutter` contains a space that breaks native-asset builds). Use `C:\flutter\bin\flutter` in commands.

## Part 1: reliable local connection (emulator, USB phone, Wi-Fi phone)

1. **Emulator:** `API_URL=http://10.0.2.2:4100/api` with the backend on `HOST=127.0.0.1` (already the default).
2. **USB phone:** document and script `adb reverse tcp:4100 tcp:4100`, then `API_URL=http://127.0.0.1:4100/api`.
3. **Wi-Fi phone (same network):** support `HOST=0.0.0.0` in `backend/.env`, print the PC's LAN URL(s) at startup (e.g. `http://192.168.1.23:4100/api`), and document the Windows Firewall rule for port 4100 (private networks only). Warn that `ALLOW_DEMO` must stay `false` whenever `HOST=0.0.0.0`: make the backend refuse to start with that combination unless `ALLOW_DEMO_ON_LAN=true` is also set explicitly.
4. **Per-environment config files** instead of long command lines: add `citizen-mobile/env/emulator.json`, `usb.json`, `lan.example.json`, `prod.example.json` (same for maintenance-mobile) containing only `{"API_URL": "..."}`, used with `flutter run --dart-define-from-file=env/emulator.json`. Commit the `emulator`/`usb`/`*.example` files and git-ignore real `lan.json`/`prod.json`. These files must never contain secrets; `API_URL` is the only value.
5. **Root scripts** in `package.json`: `api` (exists), `api:lan` (backend with `HOST=0.0.0.0`), and `mobile:usb` (runs `adb reverse`).
6. **Connection check in both apps:** on the splash/login screen, call `GET /health`. If it fails, show a clear, friendly message with the URL being used ("Can't reach the PATAG server at http://10.0.2.2:4100/api. Is the backend running?") and a Retry button, instead of a generic error on first login. Keep the URL visible only in debug builds.

## Part 2: hosted backend (so the apps work without a PC)

1. Make the backend deployable on a free/low-cost Node host (pick **one**, e.g. Render or Railway, and justify it): add a `Dockerfile` or the platform's config, honour the platform's `PORT`, default `HOST=0.0.0.0` in that config, and add a `/health` health check. Node 24 is required (TypeScript runs via Node type stripping, so there's no build step).
2. Configure secrets **only in the host's environment settings**: `SUPABASE_URL`, `SUPABASE_SECRET_KEY`, `SUPABASE_DB_HOST/PORT/NAME/USER/PASSWORD`, `STORAGE_BUCKET`, `ALLOW_DEMO=false`, `CORS_ORIGINS` (the deployed admin/maintenance web URLs if any). Never commit them; never put them in Flutter or `VITE_*`.
3. Turn on certificate verification: download the Supabase CA (Dashboard → Database → Settings → SSL), add it to the backend (`SUPABASE_DB_CA_CERT`) and make it work in the deployed environment too, so the startup warning disappears.
4. Add trusted-proxy handling for the login rate limiter (Fastify `trustProxy` limited to the platform's proxy), so all users don't share one IP behind the host's load balancer.
5. **Release builds use HTTPS only:** the hosted URL must be `https://…/api`; confirm the release manifest does not allow cleartext; build with `flutter build apk --release --dart-define-from-file=env/prod.json`.

## Part 3: real accounts in Supabase

- Document and run (with the user's confirmation, since this writes to the **production** Supabase project):
  - `npm run create-admin` for the LGU administrator (env vars `ADMIN_NAME`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`).
  - Creating maintenance teams and crew accounts from admin-web.
  - Citizen self-registration in the citizen app.
- Seeded demo accounts have no passwords and only work through `/auth/demo` with `ALLOW_DEMO=true` on a local backend. Say this clearly in the README.
- Recommend (do not silently create) a separate Supabase project or branch for testing, so test reports and accounts don't mix with real data. If the user agrees, support it through a second `.env` (e.g. `backend/.env.test`) and an `npm run dev:test` script.

## Part 4: prove it end to end

1. Add `backend/scripts/smoke.ts` (`npm run smoke -- --url <API_URL>`), run manually, never in CI, which against a running backend:
   - checks `/health` reports `mode: "supabase"`
   - reads `/public/reports`
   - with `--write` only: registers a uniquely named test citizen (`smoke+<timestamp>@example.test`), uploads a tiny PNG, submits a report, reads it back from `/bootstrap`, then prints the report ID so it can be found in Supabase.

   Never delete production data automatically; print what was created instead.
2. Manual walkthrough on the emulator (write it as a checklist in `docs/mobile-supabase-checklist.md`):
   1. citizen registers → reports a pothole with a photo (also try the full-screen map "Report a pothole here")
   2. admin-web verifies → assigns to a team
   3. maintenance-mobile crew sees it → before photo → start → complete with an after photo → "Awaiting verification"
   4. admin resolves → citizen sees Resolved within ~8 s and leaves feedback
   5. In the Supabase dashboard, confirm the rows in `reports`, `notifications`, `uploads` and the files in the `report-photos` bucket.
3. Run and show the output of: `npm test` in `backend/`, plus `flutter analyze` and `flutter test` in both mobile apps.

## Done when

- Both apps work against Supabase on the emulator, a USB phone and a Wi-Fi phone, with one documented command each.
- A hosted HTTPS backend is deployed (or fully prepared, with the exact remaining steps listed if deployment needs the user's account), and a release APK points at it.
- No Supabase key, database password or secret exists in any Flutter file, web env file, commit or log.
- All tests pass, and the checklist has been completed once with results noted.
- Summarize every file changed, and list anything that needs the user's action (accounts, dashboard settings, hosting sign-up).
