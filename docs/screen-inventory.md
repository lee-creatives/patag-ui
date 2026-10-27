# Screen inventory

All 55 specified route entries have source implementations. The PDF requires functional areas, not 55 distinct pages. Related views intentionally reuse the report workspace component. Web routes were opened in local Chrome; this is route smoke coverage, not proof of every control. Flutter source now passes analysis and 26 widget/model tests; actual Android device validation remains incomplete. See redesign-validation.md for the latest evidence.

| ID | Screen | Route | Scope | Evidence |
|---|---|---|---|---|
| C01 | Splash Screen | `/` | Expanded brief | Source implemented; Android device check outstanding |
| C02 | Onboarding | `/onboarding` | Expanded brief | Source implemented; Android device check outstanding |
| C03 | Welcome / Authentication Entry | `/welcome` | Expanded brief | Source implemented; Android device check outstanding |
| C04 | Registration | `/register` | Expanded brief | Source implemented; Android device check outstanding |
| C05 | Login | `/login` | Expanded brief | Source implemented; Android device check outstanding |
| C06 | Forgot Password | `/forgot-password` | Expanded brief | Source implemented; Android device check outstanding |
| C07 | Citizen Home Dashboard | `/home` | PDF functional area | Source implemented; Android device check outstanding |
| C08 | Report A Pothole | `/report/new` | PDF functional area | Source implemented; Android device check outstanding |
| C09 | Report Submission Success | `/report/success/:id` | Expanded brief | Source implemented; Android device check outstanding |
| C10 | My Reports | `/reports` | PDF functional area | Source implemented; Android device check outstanding |
| C11 | Report Details And Status Timeline | `/reports/:id` | PDF functional area | Source implemented; Android device check outstanding |
| C12 | Public Pothole Map | `/map` | PDF functional area | Source implemented; Android device check outstanding |
| C13 | Public Report Details | `/map/reports/:id` | Expanded brief | Source implemented; Android device check outstanding |
| C14 | Notifications | `/notifications` | PDF functional area | Source implemented; Android device check outstanding |
| C15 | Repair Feedback | `/reports/:id/feedback` | PDF functional area | Source implemented; Android device check outstanding |
| C16 | Profile | `/profile` | Expanded brief | Source implemented; Android device check outstanding |
| C17 | Edit Profile | `/profile/edit` | Expanded brief | Source implemented; Android device check outstanding |
| C18 | Settings | `/settings` | Expanded brief | Source implemented; Android device check outstanding |
| C19 | Help And Reporting Guide | `/help` | Expanded brief | Source implemented; Android device check outstanding |
| C20 | About Patag | `/about` | Expanded brief | Source implemented; Android device check outstanding |
| A01 | Admin Login | `/admin/login` | Expanded brief | Browser route opened; core workflows tested |
| A02 | Admin Dashboard | `/admin/dashboard` | PDF functional area | Browser route opened; core workflows tested |
| A03 | All Reports | `/admin/reports` | PDF functional area | Browser route opened; core workflows tested |
| A04 | Report Details | `/admin/reports/:id` | PDF functional area | Browser route opened; core workflows tested |
| A05 | Verification Queue | `/admin/verification` | PDF functional area | Browser route opened; core workflows tested |
| A06 | Verification Workspace | `/admin/verification/:id` | Expanded brief | Browser route opened; core workflows tested |
| A07 | Duplicate Report Review | `/admin/duplicates` | Expanded brief | Browser route opened; core workflows tested |
| A08 | Interactive Admin Map | `/admin/map` | PDF functional area | Browser route opened; core workflows tested |
| A09 | Assignment Management | `/admin/assignments` | PDF functional area | Browser route opened; core workflows tested |
| A10 | Assign A Maintenance Team | `/admin/assignments/new/:reportId` | PDF functional area | Browser route opened; core workflows tested |
| A11 | Maintenance Teams | `/admin/teams` | Expanded brief | Browser route opened; core workflows tested |
| A12 | Maintenance Team Details | `/admin/teams/:id` | Expanded brief | Browser route opened; core workflows tested |
| A13 | Repair Completion Verification | `/admin/completions` | PDF functional area | Browser route opened; core workflows tested |
| A14 | Verify Completed Repair | `/admin/completions/:id` | PDF functional area | Browser route opened; core workflows tested |
| A15 | User Management | `/admin/users` | PDF functional area | Browser route opened; core workflows tested |
| A16 | User Details | `/admin/users/:id` | Expanded brief | Browser route opened; core workflows tested |
| A17 | Analytics | `/admin/analytics` | PDF functional area | Browser route opened; core workflows tested |
| A18 | Export Center | `/admin/exports` | PDF functional area | Browser route opened; core workflows tested |
| A19 | Notifications / Activity | `/admin/notifications` | Expanded brief | Browser route opened; core workflows tested |
| A20 | Settings | `/admin/settings` | Expanded brief | Browser route opened; core workflows tested |
| A21 | Report History / Audit View | `/admin/activity` | Expanded brief | Browser route opened; core workflows tested |
| M01 | Maintenance Login | `/maintenance/login` | Expanded brief | Browser route opened; core workflows tested |
| M02 | Maintenance Dashboard | `/maintenance/dashboard` | PDF functional area | Browser route opened; core workflows tested |
| M03 | My Assignments | `/maintenance/assignments` | PDF functional area | Browser route opened; core workflows tested |
| M04 | Task Details | `/maintenance/assignments/:id` | PDF functional area | Browser route opened; core workflows tested |
| M05 | Assigned Task Map | `/maintenance/map` | PDF functional area | Browser route opened; core workflows tested |
| M06 | Repair In Progress | `/maintenance/progress` | Expanded brief | Browser route opened; core workflows tested |
| M07 | Update Repair Progress | `/maintenance/progress/:id` | PDF functional area | Browser route opened; core workflows tested |
| M08 | Repair Documentation | `/maintenance/repairs/:id/document` | PDF functional area | Browser route opened; core workflows tested |
| M09 | Submit Repair Completion | `/maintenance/repairs/:id/submit` | PDF functional area | Browser route opened; core workflows tested |
| M10 | Completion Submission Success | `/maintenance/repairs/:id/success` | Expanded brief | Browser route opened; core workflows tested |
| M11 | Completion Submissions | `/maintenance/submissions` | Expanded brief | Browser route opened; core workflows tested |
| M12 | Repair History | `/maintenance/history` | Expanded brief | Browser route opened; core workflows tested |
| M13 | Notifications | `/maintenance/notifications` | Expanded brief | Browser route opened; core workflows tested |
| M14 | Profile | `/maintenance/profile` | Expanded brief | Browser route opened; core workflows tested |

A10 uses the parameter name `:id` internally for the same report reference. Mobile route arguments are parsed by onGenerateRoute. Splash redirects based on onboarding preference; sessions are intentionally memory-only on Android.
