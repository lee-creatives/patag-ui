# Current shared PostgreSQL admin contract — 29 October 2026

Base /api, Node port4101. public.users is the sole application account table; no Supabase Auth API or auth.users identity is required. Login reuses the existing mobile scrypt password format and public.sessions SHA-256 opaque-token records with eight-hour expiry. The browser receives only an HttpOnly SameSite=Strict cookie, Secure with HTTPS, and an allowlisted user response. No editable client role or account ID authorizes a request.

| Endpoint | Behavior |
| --- | --- |
| GET /health | {backend:'postgresql',identityVerification:true}; explicit503 if the required shared-account upgrade is absent |
| POST /auth/login | {email,password}; only active shared admin accounts with valid credentials; uniform401 failures; bounded attempts; cookie plus safe user response, no token JSON |
| POST /auth/logout | Empty object; revoke current shared session and clear cookie |
| GET /users | Direct users query; q(max100),role(admin/citizen/maintenance),active(true/false),limit1–100,offset0–100000; stable {users,nextOffset} |
| GET /users/:id | URL-encoded text ID; safe detail response, never credential/address fields |
| POST /users | name,email,role,active,optional teamId/municipality; shared row, no password; duplicate409 |
| PATCH /users | id,role,active,optional teamId/municipality; credentials/address preserved; own-access changes denied; disable/role-change permanently revokes target's shared sessions |
| GET /account-teams | Up to100 active shared teams, verified municipal mapping for scoped administrators |
| GET/PATCH /me | Current shared account; name update only, unchanged email required |
| GET /bootstrap | Current scoped report/team/notification workspace; demo:false and bounded nextOffset |
| GET /reports; GET /reports/:id; GET /reports/:id/history | Existing scoped report search/details/paged history; report IDs remain UUID |
| POST /reports/:id/events | Existing validated/idempotent workflow actions with atomic audit/notifications |
| GET/POST/PATCH /teams | Existing report teams; synchronize shared metadata transactionally with scoped RLS |
| PATCH /settings; GET /statistics; POST /exports; GET /activity | Existing administrator scope and bounded/allowlisted audited operations |
| GET /notifications; POST /notifications/read; GET/POST /duplicates | Existing scoped polling, notice changes and bounded candidates |
| POST /uploads; GET /evidence/:id | Private Storage and authorized evidence streaming; service credentials stay server-side |

Mutations require exact Origin, X-Patag-Request:1 and application/json. Sessions and current active admin role are revalidated inside operation transactions. Error shape {error:string}: 400 validation,401 login/session,403 scope/CSRF,404 missing/unsupported recovery/MFA routes,405 method,409 conflict,413 size,415 type,429 quota,503 setup/database. Accounts never fall back to mocks, JSON, browser storage or another database. Recovery/MFA/password-reset endpoints remain unsupported; no email was sent.

See [setup and pending migration](supabase-backend.md) and [schema](shared-account-schema.md). Existing mobile API flows remain separate consumers of the same users/sessions; hosted compatibility is unverified. Historical demo behavior below is not the real-admin fallback.

# Historical cross-platform demo contract

The contract below remains reference for dev-mock and the unchanged citizen/maintenance demos. Its bearer/sessionStorage, public uploads and demo endpoints do not apply to the real admin.

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
