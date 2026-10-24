# Account flow and authentication follow-up

24 October 2026. This replaces the earlier profile account-switching demonstration.

## Pages and flow

- Citizen browser and native app: log in or create an account before entering protected report/profile screens. Signup uses **About you** (name and email), **Your address** (street or house number optional; barangay, city or municipality, and province required), and **Secure your account** (password and privacy explanation). Back preserves entered fields; browser passwords are not saved as drafts. Show/hide password and password-manager autofill are supported.
- The browser login uses a responsive split composition: PATAG identity, mascot and road-safety message at left; focused credentials at right. At tablet and phone widths it becomes a compact branded header above the form. Registration and recovery reuse the same shell, and demo access is a quiet disclosure instead of a separate boxed card. No social-provider buttons are shown.
- Admin and maintenance: login only. Authorized administrators provision staff accounts and assign maintenance membership. No public role selection is available in citizen signup.
- All roles: explicit logout. Citizen logout clears the report draft; server logout invalidates its session. Staff settings provide a labelled Log out button, in addition to the existing sidebar action.
- Automatic preview login and profile account switching are removed. A collapsed, clearly labelled fictional-demo option remains on login pages and only accesses seeded accounts without passwords. It cannot impersonate newly registered or provisioned accounts.
- Recovery screens explain that email delivery is unavailable. Email changes are read-only until verified recovery exists. No fake email verification or recovery success is displayed.

## Validation and session behavior

New citizen accounts require a trimmed name (maximum 100 characters), a normalized email (maximum 254), a private address (barangay, city or municipality, province; street or house number optional), and a password of 15–128 characters. Staff provisioning does not ask for a home address. Spaces are supported, arbitrary character-composition rules are avoided, and a small set of obvious repeated/common passwords is rejected. This is not a comprehensive breached-password database. Case-insensitive duplicate emails are rejected. Registration always creates an active citizen, ignoring supplied role/team/active values.

The local Node API stores salted scrypt password hashes, compares them with timingSafeEqual, rate-limits registration/login attempts (20 per minute per loopback client/endpoint), issues random session tokens with eight-hour expiry, enforces active users and role ownership, and revokes tokens on logout. Login can require the requested portal role. `createServer({allowDemo:false})` disables demo endpoints; the named local demo server retains them for testing.

The portable preview simulates this flow in browser storage using salted PBKDF2-SHA256 (600,000 iterations for new passwords), random recorded sessions and expiry/revocation. Existing preview hashes retain their previous iteration count for compatibility. Old prefix-based preview tokens no longer authenticate. A user who controls browser storage also controls the simulation; this is **not a deployed authentication security boundary**. Preview throttling is per page runtime, while API throttling is enforced by the server.

Email format validation does not establish ownership. New accounts explicitly carry `emailVerified:false`; no email service, verification codes or delivery claims are invented. HTTPS, managed server-side storage, verified email/recovery, secure deployment session handling and disabling demo access are still necessary before real deployment. This turn continues the requested local web-preview scope.

## Research and field selection

- [GOV.UK: Create accounts](https://design-system.service.gov.uk/patterns/create-accounts/) recommends a clear, focused creation journey without asking for the same information twice.
- [USWDS: Create account](https://designsystem.digital.gov/templates/authentication-pages/create-account/) recommends simple account creation with limited distractions and explaining extra information requests.
- [OWASP: Authentication](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html) informs password length without MFA, password-manager support, generic login errors, throttling and role/session checks.

PATAG asks for an address at the user’s request, separated from the pothole location collected when reporting. The address remains in the private account, can be corrected in Profile, and is excluded from public report cards. It does not ask for birthday, government ID, sex or phone number. No staff role selector appears in citizen registration.

## Verification

- `npm run test:api`: seven tests, including normalization, duplicate handling, role injection, portal mismatch, demo disablement, token forgery/revocation and throttling.
- `npm run test:auth`: three-step signup, back navigation, password visibility, logout/reload protection, wrong password, provisioned staff login, and 32 screen/theme/width combinations. Screenshots and results are in this directory.
- `npm run test:preview`: complete citizen submission → LGU verify/assign → crew evidence/repair → LGU resolve → citizen feedback with explicit login.
- `npm run test:preview-completion`: team/staff/settings/photo-publication workflow, now using password login for created crews.
- Native baseline: 26 tests passed, plus a new targeted registration-step test; Flutter analysis is clean. Web production and portable preview builds pass with existing bundle-size warnings.

The established PATAG typography, orange actions, themed form surfaces and transparent mascot remain. Staff mobile login uses a compact header so the form is visible sooner and the mascot cannot overlap the title.
