# Merge review fixes — 30 October 2026

Baseline: clean working tree at `c67f0fe` (Mobile-Web merge). Changes remain local and uncommitted.

## Fixed

1. Removed both committed merge-conflict blocks from `backend/test/helpers.ts`, retaining injectable `geocode` and `corsOrigins`. Geocode tests and the custom-origin admin browser suite both pass.
2. Added account-ID membership handling to both independent demo adapters, `browser-preview/domain.mjs` and `dev-mock/domain.mjs`. Create/edit now persists selections, transfers and removals. Validation precedes mutation; invalid IDs, duplicates, ineligible accounts, non-admin callers and failed deactivation leave existing data intact. Omitted IDs and inactive membership links are preserved. Removed accounts can be edited/reassigned and cannot access private reports/events/notifications while unassigned.
3. Added theme-aware tint to both Flutter mascot widgets: navy in light mode, white in dark mode. Existing outer splash filters keep white splash artwork. Asset files, size, animation, reduced-motion handling, semantics and Crew fallback rendering are preserved.

Also prevented preview login/password hashing from saving an old workspace snapshot over a concurrent membership change. The preview re-reads current data and checks current credentials/session before saving. The preview bundler now resolves shared packages from the existing admin installation, so regenerating the artifact does not require installing Crew web dependencies.

## Verification

| Command/check | Result |
| --- | --- |
| `npm --prefix backend test` | 30 passed, 0 failed, 0 skipped; isolated PGlite SQL stores |
| `npm --prefix backend run typecheck` | Passed |
| `npm run test:api` | 12 passed, 0 failed, 0 skipped; includes 5 new membership regressions across both adapters and mock HTTP |
| `npm run build:preview` | Passed; regenerated `preview/Open-PATAG.html` |
| `npm run test:preview-members` | 5 Chrome checks passed; no runtime errors |
| `npm run test:admin-fixes` | 6 Chrome groups passed; no failures, runtime errors or failed external requests |
| Crew: `flutter test --no-pub test/mascot_test.dart test/widget_test.dart` | 7 passed |
| Citizen: `flutter test --no-pub test/mascot_test.dart` | 1 passed using the existing local SDK/package cache |
| Citizen: `flutter test --no-pub test/visual_system_test.dart --plain-name "mascot dances and stops for reduced motion"` | 1 passed using the existing local SDK/package cache |
| Conflict-marker scan | No remaining markers in affected source |
| Source-only `git diff --check` excluding generated HTML | Passed |
| Full `git diff --check` | Flags trailing whitespace in generated HTML line 267, inside bundled dependency text. This warning also exists in the baseline artifact; its JavaScript remains valid. |

The five new membership regression tests failed before implementation. The Crew mascot test failed on the original untinted widget and passed after the fix. Generated-preview Chrome checks cover checkbox create/edit/reload, removed-session access, password-edit and login races with crew transfer, and logout while a password edit is hashing. Correctness, security and testing reviewers returned no remaining blocking findings. The crew-selector screenshot was visually inspected.

For browser reproduction, run `npm run build:preview` before `npm run test:preview-members`; the latter tests the generated HTML rather than rebuilding it. Evidence is in ignored `test-results/preview-members/results.json` and `members.png`, plus `test-results/admin-fixes/results.json`.

## Limits and preserved state

A clean citizen dependency restore remains blocked: the checked-in app requires `intl ^0.20.3`, while the installed Flutter SDK's localization package pins `intl 0.20.2`. The offline lockfile-enforced restore failed. Verification commands produced lockfile/generated-localization side effects; those files were restored to their exact baseline contents. No dependency constraint or lockfile change is included. Citizen focused tests passed with the available local cache, which is controlled verification, not proof that a clean checkout resolves on this SDK.

The preview build retains warnings about `inlineDynamicImports` and bundled `use client` directives. No full mobile build or Android hardware acceptance was performed. Hosted database compatibility/acceptance remains unverified: no hosted migrations, registry/checksum records, admin passwords or deployment were changed. Existing migration files and hosted credentials were untouched.
