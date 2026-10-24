# Project 2 compliance matrix

Authoritative source: `references/IT 305 - PROJECT 2 (1).pdf`, all three pages inspected as rendered images and text. `references/PATAG-Brandsheet.pdf`, all seven pages inspected. No production or Android-complete claim is made.

| ID | PDF requirement | Implementation | Verification / limit |
|---|---|---|---|
| FR-01 | Registration and login | Flutter auth screens; both web login forms; demo roles and scrypt-hashed citizen accounts. | API tested; native UI unverified |
| FR-02 | Pothole reporting | Flutter four-step reporting wizard; required-field validation; POST /reports. | API creation tested; Android unverified |
| FR-03 | Photo upload | Camera/gallery in Flutter; previews/removal; repair upload in maintenance; API validates MIME, signature and size. | Web upload and API validation tested; camera unverified |
| FR-04 | GPS location | geolocator with service/permission checks and timeout; manual fallback. | Source implemented; Android permission flows unverified |
| FR-05 | Manual location selection | Flutter map tap/long-press and coordinate input; road/address fields. | Source implemented; native interaction unverified |
| FR-06 | Report description | Description, road, barangay, city, province, landmark and hazards. | API required fields tested; native UI unverified |
| FR-07 | Severity classification | Low / Medium / High in both native and web schemas; reported severity separated from verification. | API and browser filtering tested |
| FR-08 | Report management | Search, severity/status/area/team/date filtering, sorting, paging, verify/reject/flag/forward/duplicate actions. | Core search/filter/verify tested; secondary actions API domain covered in part |
| FR-09 | Status tracking | Canonical eight states in each stack; report detail timeline; no Completed canonical status. | Cross-role API/browser lifecycle tested |
| FR-10 | Assignment management | Verified-only assignment modal, team workload, maintenance-owned bootstrap. | Browser handoff and API ownership tested |
| FR-11 | Notifications | Status events create role/user/team scoped in-app notifications; polling and read states. | API delivery tested; no push/email service |
| FR-12 | Interactive map | Leaflet for web; flutter_map for native; marker details, filters, zoom/pan/recenter and fallback text. | Web maps rendered; Flutter map unverified |
| FR-13 | Repair documentation | Original evidence, uploaded after photos, notes, review and submission; pending LGU verification. | Browser upload/completion tested |
| FR-14 | Dashboard and analytics | Computed totals; status, severity, area and time distributions; workload and timestamp-based elapsed average. | Browser rendered; seed data is fictional |
| FR-15 | Report history | Append an event on each workflow mutation; report timeline and searchable admin history. | API history tested; mock log is editable local JSON |
| FR-16 | Duplicate detection | Same normalized road and haversine distance <=150 m; user/admin inspection; explicit duplicate confirmation. | Deterministic duplicate heuristic tested |
| FR-17 | Feedback | Report owner, Resolved-only, once-only 1–5 rating and text. | API feedback and repeat protection tested; Flutter form unverified |
| FR-18 | Report export | Admin selection of date/status/severity/area/fields; escaped CSV and paginated jsPDF. | Browser export blobs validated; sandbox cancels native download file writes |

Updated 24 October: Flutter analysis, 26 tests and the debug APK now pass. Actual Android permission/camera/GPS acceptance and deployed backend/security remain outstanding. The current detailed assessment supersedes stale native-unverified labels above: see [PDF requirements and UX audit](project2-audit/audit.md). Source coverage is not acceptance-test coverage.
