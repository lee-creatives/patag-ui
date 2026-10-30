# PATAG admin fixes — 30 October 2026

## Delivered locally

- Native Leaflet map fullscreen control with accessible Enter/Exit labels, actual `fullscreenchange` state, Escape exit, restored button focus, translated zoom controls, and the existing resize observer.
- Create/Edit Team member checkboxes use authoritative admin bootstrap account IDs. Active maintenance accounts can be moved, added, and removed. The backend rejects duplicates, malformed or ineligible accounts and non-admin callers. Team metadata/member changes are atomic; omitted member IDs preserve existing links. Account editing shares the lock order so it cannot restore stale team membership.
- Fixed-size, centered password visibility buttons reserve input space, remain fixed while pressed, preserve the input value/mouse focus, support keyboard activation, and cannot submit a form. The shared fix is mirrored in both web apps.
- English/Tagalog selector in admin settings uses the existing native selection styling. English is the default and fallback; the preference is saved under `patag-language` in browser storage. UI labels, navigation, status/severity displays, dialogs, controls, dates and feedback use the local catalog. Canonical API/filter values and user-entered names/content remain unchanged. No language service or dependency was added.

## Reproduction and verification

Original browser reproduction found zero fullscreen buttons and zero member controls in Create Team. The login input intercepted pointer clicks on the password toggle. No prior Crew web/mobile language selector/catalog existed in this checkout; the user authorized creating English/Tagalog locally. The initial two membership regression tests failed on the original backend, then passed with the changes.

- `npm --prefix backend test`: 27 passed, 0 failed, 0 skipped, using isolated PGlite SQL stores. Includes account-ID validation, duplicate display names, omitted-member compatibility, unauthorized calls, post-write rollback, removed-member report/event/notification isolation, reassignment, and concurrent account-edit/crew-transfer final-state checks.
- `npm run test:admin-fixes`: 6 browser groups passed, 0 failed, 0 skipped; 0 runtime errors and 0 failed external requests. The self-contained harness starts a synthetic PGlite API and programmatic Vite server, fails on an occupied test port, and verifies the browser API identity before mutation. Installed Chrome is used.
- Browser checks cover actual fullscreen element and map dimensions, zoom/recenter, button/Escape exits, crew create/edit/reload persistence, 12 password form/theme/width combinations (login/create/edit × light/dark × 390/1440), pointer-down/release geometry, value/focus, keyboard/no-submit, Tagalog routes/navigation/dialogs/map controls, canonical filters, reload persistence, English restoration, unsupported-preference fallback, inherited dictionary-key fallback, and preservation of a crew named `Overview`.
- `npm --prefix backend run typecheck`: passed.
- `npm --prefix admin-web run build`: passed, with the existing large-chunk warning (>500 kB).
- `npm --prefix admin-web run lint`: exit 0 with 4 warnings: two set-state-in-effect, one dialog ref cleanup, and one regex escape warning. No lint errors.
- `git diff --check`: passed.
- Correctness, security/authorization, and tests/maintainability reviewers returned no remaining actionable findings after fixes.
- Visual inspection of fullscreen and Tagalog screenshots completed.

Evidence: `test-results/admin-fixes/results.json`, `fullscreen.png`, `crew-members.png`, and `tagalog-settings.png` (ignored generated files). Run the browser command again to regenerate.

## Database boundary and limits

`backend/migrations/001_init.sql` is unchanged. New local `002_unassigned_crew.sql` removes only `maintenance_has_team`, allowing a removed crew account to remain active but unassigned. Foreign keys, crew records, accounts, report assignments, and inactive membership links are retained. New crew accounts still require an active team. Unassigned crews are denied private unassigned report detail and event access.

The new migration targets this checkout's local v1 schema. It is not proof of compatibility with the unresolved hosted migration/checksum state. Hosted migration/registry/checksum records, admin passwords, and deployments were not changed. Do not point normal backend startup at that project: startup automatically runs migrations. Recover the originally applied SQL and review a compatible hosted upgrade first.

Hosted acceptance and real PostgreSQL multi-client scheduling were not tested. PGlite concurrency checks establish local final-state behavior only. The Crew web build attempt was blocked because its local `tsc` executable/dependencies are absent; no dependencies were installed. Its mirrored password CSS/handlers were reviewed, but independent Crew browser/build acceptance remains unverified. Mobile apps and unrelated preview/mock suites were not changed or run.
