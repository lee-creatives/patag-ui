> Authentication follow-up: [Current login and registration flow](../auth-flow/README.md) supersedes the account-switching steps below. Registration is now a three-step signed-out flow; created staff use their password.

# Connected web-preview completion

24 October 2026. The user clarified that the target is the web preview, with no hosting or Android device setup. This work completes the missing demonstration controls while retaining the current PATAG visual system. It does not present browser storage or demo role switching as deployed authentication or cross-device persistence.

## What is now connected

- **Citizen → Profile → Accounts & sign in:** create a citizen account, sign in with its demo password, or switch among fictional citizens. Passwords use salted PBKDF2 in the portable preview. Sessions persist across refreshes, and reports remain scoped to the selected citizen. The real local API continues using scrypt.
- **LGU → Maintenance teams:** create/edit teams and change availability. An active member or unresolved assignment prevents unsafe team deactivation.
- **LGU → User accounts:** create accounts, choose roles, and attach maintenance staff to an active team. Existing accounts can change roles, team membership and active status. A crew role cannot be saved without an active team.
- **LGU → Workspace settings:** save agency, city and province to shared state. Both web portals and the citizen settings read the same values; new reports inherit the agency. Existing cases retain their jurisdiction unless forwarded explicitly.
- **Maintenance → Profile & settings → Preview account:** select a created staff account and see its team's assignments. Team names in navigation and page headings reflect the selected account.
- **LGU → Report details → Public photo visibility:** approve or hide the report's evidence for the community map. User uploads are hidden publicly by default. Added before/after evidence requires a new review. Private report details remain available to the reporter and authorized operational roles. Fictional seeded illustrations are explicitly safe demo assets.
- Public cards without approved photos show a clear review placeholder. Public timelines and summaries continue to exclude private notes, identities and feedback.

## PDF alignment

FR-01 is demonstrable through the new browser account flow (native registration already existed). The role-management responsibility and FR-10 are connected through actual team/account assignment. FR-03 and FR-13 retain before/after evidence uploads. Constraint 6 now has an explicit LGU photo-publication decision in addition to the safe public data projection. Administrative settings are shared, rather than a browser-only label. FR-02 through FR-18 retain their established report-to-repair workflow, validation, history, notification, map, feedback and export controls.

All new views use the existing Montserrat typography, orange primary actions, themed surfaces, labelled forms, standard dialogs, mobile drawer and focus styling. No separate design system was introduced.

## Try it

1. Open `http://127.0.0.1:8080/` and choose LGU / Admin.
2. In Maintenance teams, add a team. In User accounts, add a maintenance account and choose that team.
3. Save an agency in Workspace settings.
4. Switch to Citizen. Open Profile → Accounts & sign in, create a fictional account, then submit a report.
5. Switch to LGU. Review the new report, approve photos only after inspecting their contents, verify it and assign the new team.
6. Switch to Maintenance. Select the created crew account under Profile & settings, then inspect the assignment. Add before evidence, start work, save progress and submit after evidence/notes.
7. Switch to LGU and confirm the repair. Switch to the reporting citizen to view the resolved timeline and submit feedback.

Role pages in the same browser share the same preview records. Refreshes retain state. Reset preview data remains an explicit citizen settings action. Newly created accounts and reports are fictional test data; use demo-only passwords.

## Verification

- `npm run test:api`: six tests covering workflow permissions, account registration, ownership, shared settings, crew provisioning and public photo decisions.
- `node scripts/qa/preview-completion.mjs`: isolated Chrome acceptance test for the new screens; result and screenshots are saved here.
- `npm run test:preview`: full citizen → LGU → crew → LGU → citizen workflow with before/after evidence and feedback.
- Both production React builds and portable preview build pass. Existing bundle-size notices remain.

## Scope boundary

The web preview is the deliverable requested in this turn. A hosted database, secure deployed sessions/storage, email/push delivery and real-device permission testing are not being claimed. They remain separate deployment acceptance work. The PDF has no scored rubric; see `../project2-audit/audit.md` for the original requirement-by-requirement assessment, with this follow-up superseding its missing preview settings/team/account/moderation items.
