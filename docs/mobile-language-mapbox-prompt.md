# Prompt: Mapbox address autofill + language settings (mobile)

Copy everything below the line into your AI coding assistant, run from the `patag-ui` repo root.

---

You are adding three features to the PATAG Flutter apps (IT 305 academic pothole-reporting system):

1. **Citizen app:** when the citizen drops or moves the map pin, fill the address fields automatically using Mapbox reverse geocoding.
2. **Citizen app:** a language setting (English / Tagalog), **English by default**.
3. **Road crew app:** the same language setting, **Tagalog by default**.

## Read first

- `citizen-mobile/lib/features/report_wizard.dart` — the 4-step report form. `setPin(LatLng)` (~line 178) is called by the map (`RoadMap(onPin: setPin)`) and by GPS; fields `road`, `barangay`, `city`, `province`, `landmark`; the draft is saved to SharedPreferences (`patag-draft`).
- `citizen-mobile/lib/features/report_map.dart` — `RoadMap`, `FullMapScreen` (full-screen picker returns the pin), `locate()` (GPS).
- `citizen-mobile/lib/features/screens.dart` — `SettingsScreen` (~line 1328), `ProfileScreen`; `lib/main.dart` (`PatagApp`, routes); `lib/core/api.dart` (`PatagStore`, `call()`).
- `maintenance-mobile/lib/features/screens.dart` — `ProfileTab` (~line 1985, the crew's settings area); `lib/main.dart`; `lib/core/api.dart`.
- `backend/src/app.ts`, `backend/src/config.ts`, `backend/.env.example`, `backend/test/*` — the Node/Fastify API the apps already use.
- `docs/api-contract.md` — keep the existing contract unchanged; only add the new endpoint below.

Use `C:\flutter\bin\flutter` for Flutter commands (the default SDK path contains a space that breaks builds).

## Part 1 — Mapbox address autofill (citizen)

### Architecture: geocode through the backend

Do **not** put a Mapbox token in the Flutter app (anything in an APK can be extracted, and the apps only talk to `backend/`). Add one endpoint to the backend instead:

- `GET /api/geocode/reverse?lat=<lat>&lng=<lng>&lang=<en|fil>` — authenticated (any signed-in role), validates coordinates, rate-limited (e.g. 30/min per user).
- The backend calls the Mapbox Geocoding API v6 reverse endpoint (`https://api.mapbox.com/search/geocode/v6/reverse`) with `MAPBOX_TOKEN` from `backend/.env` (add it to `.env.example` with a placeholder and a comment on where to create it: Mapbox account → Tokens). Restrict results to the Philippines (`country=ph`) and request the closest street-level result.
- Map the result to PATAG fields and return only these:
  ```json
  { "road": "MacArthur Highway", "barangay": "Guinhawa", "city": "Malolos", "province": "Bulacan", "source": "mapbox" }
  ```
  Use Mapbox context: street/address → `road`; neighborhood or locality → `barangay`; place → `city`; region → `province`. Any part Mapbox doesn't know is returned as `""` — never invent values.
- Cache responses in memory for ~10 minutes keyed by coordinates rounded to ~5 decimals, so dragging the pin back and forth doesn't repeat calls.
- Errors: Mapbox down, quota exceeded or no token → respond `200` with all fields `""` and `"source": "none"` (autofill is a convenience, never a blocker). Log the cause server-side only.
- Tests in `backend/test/geocode.test.ts` with a mocked `fetch`: field mapping, missing parts, Mapbox error → empty result, invalid coordinates → 400, unauthenticated → 401, rate limit. Never call the real Mapbox API in tests.

### App behaviour (report form, Location step)

- After `setPin` (map tap, pin drag, GPS, or the full-screen picker), call the endpoint, **debounced ~600 ms** so dragging doesn't spam requests.
- Show a small "Finding address…" indicator while waiting; never block the form.
- **Only fill fields the citizen hasn't typed in themselves.** Track which fields were auto-filled; a new pin may replace auto-filled values but must never overwrite text the citizen typed or edited.
- Show a short note under the fields when autofill was used: "Filled from the map — please check it." (translated). Fields stay fully editable, and the existing validation (road, barangay, city, province required) is unchanged.
- If the lookup returns nothing or fails: leave the fields as they are, no error popup (optionally a subtle "Couldn't find the address — please type it").
- The filled values must be saved into the existing draft like typed values.
- Mention in the app's help/privacy text that the pin's coordinates are sent to Mapbox (via PATAG's server) to look up the address.
- Widget/unit tests with a mock HTTP client: autofill fills empty fields; does not overwrite typed fields; a second pin updates only auto-filled fields; failure leaves fields unchanged; debounce sends one request for rapid pin moves.

(Optional, only if asked: switching the map tiles from OpenStreetMap to Mapbox is a separate change — don't do it in this task.)

## Part 2 — Language settings (both apps)

### Setup (same in both apps)

- Use Flutter's official localization: `flutter_localizations` + `intl`, `generate: true`, ARB files in `lib/l10n/`: `app_en.arb` and `app_fil.arb`.
  - Use the locale code **`fil` (Filipino/Tagalog)** — Flutter's Material widgets support `fil`; `tl` is not supported.
  - Label the options in the UI as **"English"** and **"Tagalog"**.
- Move **every user-visible string** in each app into the ARB files: screens, buttons, captions, form labels, validation messages, empty states, snackbars, dialogs, the server-status banner, status names shown to users, and the bottom navigation. Dates/times via `intl` `DateFormat` with the current locale.
- Keep the brand's Taglish lines as they are in **both** languages: "May lubak sa daan?", "Na-tag na ang lubak!", "Pa-tag lubak, lubak patag.", "I-tag mo na."
- Report **status values sent to/received from the backend stay in English** (they are API values like `In Progress`); translate only how they're displayed.
- Error messages that come from the backend are English; map the common ones (session expired, wrong password, can't reach server, photo too large, wrong file type) to translated text in the app, and show the server's text for anything unmapped.
- Write natural, everyday Tagalog (the way Filipino commuters and LGU crews talk), not word-for-word machine translation. Mark the Tagalog strings for review by a native speaker in the PR description.

### Language choice

- **Citizen app:** default **English**. Add a "Language / Wika" setting in `SettingsScreen` with English / Tagalog.
- **Crew app:** default **Tagalog**. Add the same "Wika / Language" setting in the crew's settings area (`ProfileTab` or a settings screen reachable from it) with Tagalog / English.
- Show the setting's title in both languages ("Language / Wika") so someone who can't read the current language can still find it.
- The choice applies **immediately** (no restart) and is saved in SharedPreferences (`patag-language` / `maintenance-language`); on start the app uses the saved choice, otherwise its default. Don't follow the phone's system language unless the user picks it (keep the defaults above).
- Also offer the language choice on the sign-in screens (a small toggle), so it can be changed before logging in.

### Tests

- ARB parity test: every key in `app_en.arb` exists in `app_fil.arb` and vice versa, with matching placeholders.
- Citizen app starts in English; crew app starts in Tagalog.
- Changing the setting updates visible text immediately and persists across a restart (mock SharedPreferences).
- A few key screens render in both languages without overflow at 360 px width (Tagalog strings are often longer).
- Existing tests keep passing (update expected text where it moved into ARB files).

## Done when

- `npm test` in `backend/` passes (including the new geocode tests), and `flutter analyze` + `flutter test` pass in both apps. Show the output.
- On the emulator, with `MAPBOX_TOKEN` set in `backend/.env`: dropping the pin on a road in Malolos fills road, barangay, city and province; typed fields are never overwritten; with the token removed the form still works normally.
- Citizen app opens in English, crew app opens in Tagalog; both switch languages instantly from Settings and remember the choice.
- No Mapbox token or other secret in any Flutter file, ARB file, commit or log.
- Summarize every changed file and list the Tagalog strings that need a native-speaker check.
