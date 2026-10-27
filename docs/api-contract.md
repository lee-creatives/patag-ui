# Cross-platform JSON contract v1

Base: web `VITE_API_URL=http://127.0.0.1:4100/api`; Android emulator `--dart-define=API_URL=http://10.0.2.2:4100/api`. The Android localhost address points at Android itself. For physical devices use a reachable development endpoint; the service intentionally binds loopback, so prefer `adb reverse tcp:4100 tcp:4100` and API_URL=http://127.0.0.1:4100/api for a USB-connected device. Tokens are memory-only on Android and sessionStorage on web. Restarting the API invalidates all sessions.

`Authorization: Bearer <token>` is required except auth/demo, registration, login, recovery, public map, health and evidence URLs. The open demo endpoint is for LOCAL TESTING ONLY. Role and ownership checks occur again in the mock API. Error body: `{ "error": "Human readable message" }`; 400 validation, 401 expired session, 403 ownership/role, 404 missing record, 409 invalid workflow transition, 413 oversize body.

## Models

- User: id, name, email, role (citizen/admin/maintenance), active, optional teamId. Citizen and LGUPersonnel constrain role. Password hashes/salts never leave the service.
- MaintenanceTeam: id, name, members[], active.
- Coordinates: lat and lng, finite numeric degrees, ranges -90..90 / -180..180.
- LocationDetails: road, barangay, city, province, landmark, coordinates.
- Severity: Low, Medium, High. These are citizen-reported estimates.
- ReportStatus: Submitted, Under Review, Verified, Assigned, In Progress, Resolved, Rejected, Duplicate. Canonical order is held separately in Dart and TypeScript.
- PotholeReport: id, title, description, hazards, severity, status, location, photos[], reporterId, jurisdiction, createdAt, updatedAt, teamId, assignment, history[], updates[], completion, feedback, flagged, optional duplicateOf.
- ReportPhoto: id, url, name, kind (before/after), optional demo. Real uploaded photo URLs are `/uploads/<uuid>.<png|jpg|webp>`. Resolve relative URLs under the configured API base. Seed SVG illustrations are explicitly marked demo and cannot be supplied as new citizen/completion evidence.
- ReportHistoryEntry: id, at (ISO UTC), actor, action, from (nullable), to, note.
- Assignment: teamId, priority, note, targetDate (nullable ISO date), at.
- RepairProgressUpdate: at, phase, note, photos[].
- RepairDocumentation: before[], after[], note. Before references original citizen evidence; after is newly uploaded.
- CompletionVerification: state (Awaiting Verification / Additional Work Requested / Verified), note, photos[], at. Its state is separate from report status.
- Notification: id, role, optional userId/teamId, reportId, title, at, read.
- ReportFeedback: rating 1..5, text, at. Once only and owner only after Resolved.
- DuplicateCandidate: report (privacy-safe record), distance (integer metres). Same road and <=150 m haversine heuristic, never automatic merging.
- AgencyJurisdiction: id/name/municipalities in domain definitions. The mock report stores a jurisdiction label and forwarding updates this label; a real agency directory and routing service are integration requirements.

## Endpoints

| Method / path | Role | Body / result |
|---|---|---|
| GET /health | public | local demo health |
| POST /auth/demo | public, local-only | `{ "role": "admin" }` -> token + user; supports citizen and maintenance |
| POST /auth/register | public | name, email, address {line?, barangay, city, province}, password -> citizen token + user |
| POST /auth/login | public | email, password -> token + user |
| POST /auth/recovery | public | email -> demo confirmation, no email sent |
| POST /auth/logout | authenticated | invalidates current token |
| GET /bootstrap | authenticated | reports owned by citizen/team or all for admin; teams, authorized users, scoped notifications, user, statuses |
| GET /public/reports | public | allowlisted road/status/evidence records, excludes Rejected/Duplicate, identity, assignment, internal notes, landmarks and feedback |
| GET /reports/:id | owner/team/admin | report detail |
| POST /uploads | authenticated | data (base64 PNG/JPEG/WebP <=8 MB), name, kind -> ReportPhoto |
| POST /reports | citizen | report fields below; service sets owner, Submitted status and history |
| POST /duplicates | authenticated | id (optional), location -> possible matching public reports with distance |
| POST /reports/:id/events | authorized operational role | action + fields below -> updated report, event and notifications |
| POST /reports/:id/feedback | owning citizen | rating, text -> feedback |
| POST /notifications/read | recipient | id or id=all |
| PATCH /me | authenticated | name, email -> updated user |
| PATCH /users | admin | id, role, active -> updated user; cannot disable self |

## Create example

```json
{"title":"Damaged outer lane","description":"Pothole beside the crossing.","hazards":"Water collects after rain.","severity":"High","photos":[{"id":"upload-id","url":"/uploads/uuid.png","name":"road.png","kind":"before"}],"location":{"road":"Test Road","barangay":"Guinhawa","city":"Malolos","province":"Bulacan","landmark":"Waiting shed","coordinates":{"lat":14.852,"lng":120.811}}}
```

Maintenance can also send `before-photos` with uploaded `photos` while Assigned or In Progress (except while awaiting verification); original evidence is retained.

## Event examples

```json
{"action":"review","note":"Checking location and photo."}
{"action":"verify","note":"Location and damage confirmed."}
{"action":"reject","note":"Evidence does not show road damage."}
{"action":"flag","note":"Please inspect the exact road section."}
{"action":"duplicate","duplicateOf":"PTG-2026-0102","note":"Same damage confirmed."}
{"action":"forward","jurisdiction":"Responsible road agency","note":"Jurisdiction review required."}
{"action":"assign","teamId":"team-1","priority":"High","targetDate":"2026-10-26","note":"Inspect the outer lane."}
{"action":"start","note":"Crew arrived on site."}
{"action":"progress","phase":"Repair","note":"Base prepared.","photos":[]}
{"action":"complete","note":"Patch compacted and road cleared.","photos":[{"id":"upload-id","url":"/uploads/uuid.png","name":"after.png","kind":"after"}]}
{"action":"return","note":"Please inspect the patch edge."}
{"action":"resolve","note":"Completion evidence verified."}
```

CSV/PDF exports are generated in the admin frontend from its authorized report snapshot, not by an export server endpoint. Production should provide a server-authorized export endpoint with filters, audit and file retention. In-app notifications are polling-based mock events; there is no push/email transport. JSON fixtures demonstrate one jurisdiction and two teams; there is no production LGU directory.

## Connected workspace operations (24 October)

- Bootstrap now includes shared `settings: {agency, city, province}`, dynamic `teams`, and `demo: true` in the local demonstration service.
- Admin `PATCH /settings` validates and saves shared agency/city/province. New reports inherit the configured agency.
- Admin `POST /teams` creates a team; `PATCH /teams` edits its name/active state. Teams with active members or open work cannot be deactivated.
- Admin `POST /users` takes name/email/password/role/teamId and creates an account. Maintenance roles require an active team. `PATCH /users` also updates team membership. Password material is never returned by these endpoints.
- Demo-only `GET /auth/demo/accounts` lists active fictional accounts; `POST /auth/demo` optionally selects `userId` within a role. Do not expose demo authentication publicly.
- Admin report event `{action:"publication", approved:true|false}` controls public photo visibility. New before/after evidence clears approval. Original photos remain available to authorized roles. This is a publication workflow, not automatic face/plate redaction or secure object-storage authorization.

## Authentication follow-up

Citizen signup now requires name (1–100 characters), normalized email (maximum 254), private address (barangay, city or municipality, province; optional street/house number), and a password of 15–128 characters; the same creation policy applies to staff provisioning. Optional `role` on `/auth/login` must match the account. `/auth/register` ignores role/team/active injection and always creates an active citizen with `emailVerified:false`.

Sessions expire after eight hours and are revoked on logout. Registration/login are limited to 20 requests per minute per client/endpoint in the Node service. Demo endpoints only select seeded accounts without password hashes; `createServer({allowDemo:false})` disables them. `/me` allows the citizen to correct the private address with the same validation. It cannot change email without a verified recovery workflow. See `docs/auth-flow/README.md` for preview boundaries and test evidence.
