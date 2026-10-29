# Mobile ↔ Supabase end-to-end checklist

Run once per environment (emulator, USB phone, Wi-Fi phone, hosted). Everything created here is **real data** in the Supabase project `backend/.env` points to.

**Before you start**

- [ ] Backend running: `npm run api` (or `api:lan` / a hosted URL), and `npm run smoke` passes
- [ ] An LGU admin account exists (`npm run create-admin`), and admin-web is open (`cd admin-web; npm run dev`)
- [ ] A maintenance team and crew account exist (created by the admin in admin-web)
- [ ] Both apps launched with the matching `--dart-define-from-file=env/<device>.json`
- [ ] Both sign-in screens show **no** "Can't reach the PATAG server" banner

| # | Step | Expected | Result |
|---|---|---|---|
| 1 | Citizen app: **Create account** | Account created within a couple of seconds; home screen shows | |
| 2 | Citizen: **Report** → add a photo → location → details → submit | Success screen with a `PTG-YYYY-NNNN` ID | |
| 3 | Citizen: community map → ⛶ full screen → tap the road → **Report a pothole here** | Report form opens with that location filled in | |
| 4 | Admin-web: open the report → **Verify** → **Assign** to the crew's team | Status Assigned | |
| 5 | Maintenance app: sign in as the crew | The report is under new assignments; a notification "… assigned to <team>" | |
| 6 | Crew: **Add Before Photo** → **Start** | Status In Progress | |
| 7 | Crew: **Add After Photo** → **Document & Submit Completion** (note + photo) | "Awaiting LGU Verification"; no further crew actions | |
| 8 | Admin-web: **Resolve** | Status Resolved | |
| 9 | Citizen app (wait ~8 s) | Report shows Resolved; leave feedback (rating + text) | |
| 10 | Supabase dashboard → Table Editor | New rows in `users`, `reports` (with history), `notifications`, `uploads`; feedback on the report | |
| 11 | Supabase dashboard → Storage → `report-photos` | The uploaded before/after photos are there | |

**Failure checks**

- [ ] Stop the backend, then open a sign-in screen: the banner says the server can't be reached, and **Retry** works after restarting it
- [ ] Wrong password: clear error, no login
- [ ] Hosted (free plan) after 15+ min idle: "Connecting to PATAG…" appears, then the app works

Notes / date / environment:
