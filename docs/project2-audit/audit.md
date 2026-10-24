# IT 305 Project 2: requirements and UX audit

Reviewed 24 October 2026 against the supplied **IT 305 - PROJECT 2 (1).pdf**, all three pages, including its image-based technical and UI tables. The source was read from `C:/Users/user/Downloads/IT 305 - PROJECT 2 (1).pdf`. The rendered pages and extracted text in this folder are review evidence.

## Authentication follow-up

See [the current account flow](../auth-flow/README.md): three-step citizen signup, staff login, visible logout, expiring sessions and stricter validation. This remains a local demonstration; email verification and deployed authentication are not claimed.

## Follow-up: web-preview scope

The user subsequently requested completion for the web preview only, without hosting or an Android device. [The preview follow-up](../preview-completion/README.md) adds citizen account creation/login, team and staff provisioning, shared agency settings, account switching, and public-photo approval. These controls are no longer missing. Deployment and actual device acceptance remain separate; the audit below records the original findings.

## Verdict

**The project is a connected, working local demonstration with all 18 functional areas represented. It is not yet fully accepted or deployment-ready.** The citizen, LGU and maintenance interfaces follow the PDF's workflow and eight recommended statuses. No numeric completion percentage or grade is justified: the supplied PDF contains **no scored rubric, criterion weights or grade thresholds**.

The PDF asks for a mobile-friendly citizen interface and permits Flutter, React Native or responsive/PWA alternatives. It does not mandate 55 screens, a particular visual palette, a PWA, offline sync, AI duplicate detection, or push notifications specifically. The supplied UI screenshots are examples alongside a functional screen list; their exact colors/layout are not requirements. PATAG's branding and light/dark themes can remain.

### Corrections made during this audit

1. Added maintenance **before-repair photo upload** on assigned/in-progress tasks. Original citizen evidence remains. The crew can now upload both before and after evidence as explicitly requested on pages 1 and 3. Adding evidence does not resolve or verify the case; LGU approval remains mandatory.
2. Replaced public-report object spreading with an explicit safe-field projection in both local API and browser preview. Account/team IDs, assignment, feedback, private notes, raw free-text descriptions/titles, landmarks and original filenames are not exposed by that projection. Status events, location, evidence and repair-review state remain usable. Public detail pages now select public records even when the viewer owns the same report.
3. Added regression checks for authentication, ownership, invalid transitions, forwarding and public privacy; extended the cross-role browser workflow to upload crew before photos.
4. Corrected stale documentation claiming Flutter had not compiled or only had 13/25 tests. The current baseline is 26 passing Flutter tests and a successful debug APK build.

## Functional requirement matrix

“Verified locally” means source plus automated local API/browser evidence, not field validation or production certification. Native UI existence and an APK build do not prove camera/GPS behavior on a phone.

| PDF ID | Requirement | Code and connected UI | Finding |
| --- | --- | --- | --- |
| FR-01 | Registration and secure login | Flutter `/register`, `/login`; web role login; `dev-mock/server.mjs` registration/login, scrypt hashes and scoped tokens | **Partial.** Actual citizen registration/login, wrong-password rejection, logout and ownership pass. Open `/auth/demo` issues privileged local demo sessions; preview tokens are intentionally browser-local. Not secure deployment authentication. |
| FR-02 | Citizen reporting | Flutter `report_wizard.dart`; browser `/citizen/report/new`; POST `/reports` | **Verified locally.** Photo, location, description/severity, review and success link are connected. Server assigns Submitted and reporter ownership; no automatic verification. |
| FR-03 | One or more photos | Native camera/multi-image picker; browser evidence uploads; validated local upload endpoint | **Verified locally; device check pending.** Web/API upload, removal and invalid-file rejection work. Real Android camera/gallery lifecycle remains untested. |
| FR-04 | GPS capture with permission | `report_map.dart: locate()` checks service/permission and calls geolocator; browser GPS action | **Implemented, device acceptance pending.** User invokes GPS; capture then occurs through device permission. Test allowed/denied/permanently denied/GPS-off paths on Android. |
| FR-05 | Manual map/address location | Map tap/long-press and coordinate/address inputs in report wizard | **Verified browser path; native interaction pending.** Manual location works without GPS. Coordinates remain required for mapping; typed addresses are not automatically geocoded. The PDF permits map pin OR address, so geocoding is not required. |
| FR-06 | Description/road/landmark/hazards | Wizard fields, API validation, report details shown to LGU/crew | **Verified locally.** Private report text is retained for authorized review; public map uses a generic summary. |
| FR-07 | Low/medium/high severity | Three-value schemas, citizen field, badges, report/map filters | **Verified locally.** Severity is citizen-reported; LGU sees it before verification. Assignment priority is distinct. No automatic engineering severity certification is claimed. |
| FR-08 | Admin search/filter/verify/manage | `/admin/reports`, `/verification`, detail actions; domain transitions | **Verified locally.** Search/severity filters, verify and assignment tested in browser. Rejection, flags, duplicate confirmation and forwarding are explicit domain actions. |
| FR-09 | Current status | My reports/community filters, status badges, detail progress/timeline, shared canonical statuses | **Verified locally.** All eight PDF statuses represented. Completion submission remains In Progress while awaiting LGU verification. |
| FR-10 | Assign verified reports | Admin assignment form, active team selection; maintenance scoped bootstrap | **Verified locally.** Assignment before verification rejected. Only assigned crew can access a task through the API. |
| FR-11 | Notify relevant users | Role/user/team-scoped notifications; native polling and web refresh; notification links/read actions | **Verified locally for in-app delivery.** No push/email transport. The functional requirement does not prescribe a channel; the suggested technology illustration mentions email/push. Confirm instructor expectations if external delivery is required. |
| FR-12 | Interactive map | Leaflet web; flutter_map native; geographic markers, details, filters and recenter | **Verified web; native device check pending.** Public/assigned maps follow visibility rules. Tiles require network/provider access; tests do not guarantee tile availability in deployment. |
| FR-13 | Repair notes/completion photos | Maintenance task before upload, progress/document/submit; LGU before/after comparison | **Verified locally after correction.** Crew uploads before and after photos; notes and after evidence required for completion. Citizen evidence retained. Only LGU can resolve. |
| FR-14 | Totals/pending/completed/statistics | Admin dashboard and analytics; maintenance overview; derived report counts/charts | **Verified local rendering.** Values derive from fictional records. They are not real LGU statistics. |
| FR-15 | Update/action history | Domain append events; report timeline; admin history | **Verified locally.** Mutations retain from/to/time/role/note. JSON storage is not a tamper-resistant production audit log. Public views expose status events without internal notes. |
| FR-16 | Possible duplicates | `/duplicates`, same-road and <=150m proximity heuristic; wizard review and admin duplicate workspace | **Verified basic implementation.** Heuristic suggestions require human confirmation; no automatic merge. Street spelling variants and semantic description similarity remain limitations, not a claimed AI feature. |
| FR-17 | Feedback after repair | Citizen resolved-report feedback route; ownership, rating and once-only validation | **Verified locally.** Accepted only after LGU resolution; repeats/other-owner access rejected. Feedback is excluded from public projection. |
| FR-18 | Authorized CSV/PDF export | `/admin/exports`, filtered admin snapshot; CSV escaping and jsPDF | **Verified locally.** Browser-generated files validated. Deployment still needs secure admin authentication; the local demo login cannot be treated as authorization for a public service. |

## UI/UX traceability to page 3

| Required screen/control | Implementation and destination |
| --- | --- |
| Citizen home + submission button | Native `/home`; browser `/citizen/home` → report/new |
| Reporting form | Four steps: photo → location → details → review/submit |
| Camera/image upload | Native image_picker camera/gallery; browser file upload |
| GPS/map selector | Report location step with GPS and manual fallback |
| My Reports | `/reports` native; `/citizen/reports` browser, search/status/sort controls |
| Details + timeline | `/reports/:id`, public `/map/reports/:id`; status and event history |
| Notifications + feedback | Notifications deep-link to report; feedback appears only after Resolved |
| Admin totals + pending | `/admin/dashboard`, linked verification and completion queues |
| Status/severity breakdown | `/admin/analytics`, dashboard, table filters |
| Admin interactive map | `/admin/map` → report workspace |
| Searchable reports table | `/admin/reports` → report details |
| Verification/assignment | `/admin/verification/:id`, `/admin/assignments/new/:id` |
| User management | `/admin/users`, account details/active-role controls; demo limitations below |
| Statistics + export | `/admin/analytics`, `/admin/exports` |
| Maintenance assigned tasks | `/maintenance/assignments` and dashboard |
| Location/description | `/maintenance/assignments/:id` |
| Navigation/map link | Task external navigation link and `/maintenance/map` |
| Repair progress | `/maintenance/progress/:id` |
| Before/after uploads | Task before-evidence control and `/maintenance/repairs/:id/document` |
| Completion submission | `/maintenance/repairs/:id/submit` → confirmation; LGU completion queue |

The UI is connected to the PDF's responsibilities, not only styled to resemble screenshots. Filters preserve canonical status names. Success pages lead back to the created report. Crew completion does not bypass LGU verification. Public pages use separate visibility rules from owner/operational pages. Dark-mode legibility, responsive navigation, button spacing and reduced-motion support have additional visual checks; these do not substitute for functional acceptance.

## Technical requirements and constraints

- **Web/mobile:** React/TypeScript and Flutter are expressly compatible with the suggested stack. The portable HTML is a separate browser demonstration, not the native Flutter app.
- **Backend/API and centralized data:** Independent production-source apps share the local HTTP API, with a persistent JSON file and local uploads. This demonstrates central state on one machine. There is no PostgreSQL/MySQL deployment, transactional database, migration/backup plan, or independently verified equivalent for concurrent deployed users. The portable preview uses same-browser storage and is **not cross-device synchronization**.
- **Authorized staff:** Role/ownership rules exist in the API, but open demo entry bypasses real staff identity. Do not deploy that endpoint. Admin role changes do not provision a maintenance-team membership for a new crew user; seeded teams/accounts are the tested setup.
- **Settings:** Theme/unread preferences and workspace label are local preferences. The UI explicitly labels the agency setting as local. There is no server-backed multi-user system configuration service.
- **Jurisdiction:** Each operational report shows a responsible-agency label and has a forwarding action/history. This meets the UI mechanism, but does not deliver a report to another real agency or establish an actual LGU partnership.
- **Public privacy:** Structured private data leakage corrected. Uploaded evidence can still contain faces, plates or EXIF/personal content; real publication needs moderation/redaction and appropriate storage access rules. File-signature checks do not replace image decoding/security review. Upload ownership/existence checks and storage lifecycle hardening remain deployment work.
- **Connectivity:** Internet required; saved drafts are not an offline synchronization implementation. The PDF makes offline reporting optional.
- **Verification:** Submission is always unverified Submitted. Completion evidence cannot directly set Resolved; only LGU verification can do so.

## Evidence and acceptance limits

- Five API/domain tests pass: normal lifecycle plus registration/login, ownership, forwarding, invalid transitions, public projection, photo validation and notification handoffs.
- Both React production builds and portable preview build pass; existing bundle warnings remain.
- Production browser suite: 33 routes, 20 viewport checks, seven workflow checks, no JS/console errors. CSV/PDF export content validated.
- Browser citizen → LGU → crew → LGU → citizen workflow passes with before/after evidence, resolution, notification/history and feedback.
- Existing current native baseline: Flutter analysis clean, 26 tests passing and debug APK built. No Flutter source changed in this audit. The device integration test only covers launch and has not been run on an Android device here.

See `../visual-system/production-results.json`, `preview-workflow-results.json`, `dev-mock/project2.test.mjs`, and `../visual-system/validation.md` for executable checks and evidence. A route opening successfully is not proof that every secondary control was exercised. Visual screenshots are not proof of persistence or authorization.

## Remaining acceptance gates

1. Replace or explicitly obtain instructor acceptance of the local demo backend/storage as an equivalent. For a deployed submission, provide centralized durable database/file storage, real staff authentication, team provisioning, authorization, and server-backed settings. Disable demo role access outside local testing.
2. Run the actual Flutter app on Android against that API: registration/login, camera/gallery cancellation and success, GPS allowed/denied/off/manual fallback, draft recovery, submit, cross-device refresh, notifications, and feedback. Record the device/OS and results.
3. Verify public evidence moderation/privacy and uploaded-file ownership/access. Test simultaneous writes and restart persistence with the chosen database.
4. Demonstrate the full workflow using separate citizen/LGU/crew sessions on the intended deployment. Confirm external map tiles, export downloads and any instructor-required email/push channel there.
5. The PDF specifies 4–5 group members, a 12–30 October project period and **2 November 2026 submission**. Team membership and actual submission are not verifiable from source code. No marking rubric is attached; obtain the separate rubric if one exists before assigning a grade.

These gates are explicit outstanding requirements/evidence, not hidden behind a claim of 100% completion.
