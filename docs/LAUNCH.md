# How to launch PATAG

PATAG has three kinds of users. Each uses a different app, and **all apps need the backend running first**.

| User | App | Where it runs |
|---|---|---|
| **Citizen**: reports potholes | `citizen-mobile` (Flutter) | Android emulator or phone |
| **LGU administrator**: reviews, assigns, resolves | `admin-web` (React) | Browser: http://127.0.0.1:5173/admin/login |
| **Road crew**: repairs and uploads evidence | `maintenance-mobile` (Flutter) **or** `maintenance-web` (React) | Phone/emulator, or browser: http://127.0.0.1:5174/maintenance/login |

```
Citizen app ──┐
Admin website ─┼──→ backend (port 4100) ──→ Supabase (database + photos)
Crew app/web ──┘
```

Open every terminal in the project folder: `C:\Moble dev\patag-ui`. Keep each terminal open while you use that app.

---

## Step 0: One-time setup (first time on a PC)

1. Install **Node.js 24**, **Flutter** (use it from `C:\flutter`, a path without spaces) and **Android Studio** (for the emulator).
2. Backend packages and settings:
   ```bash
   cd backend
   npm install
   copy .env.example .env
   ```
   Fill `SUPABASE_SECRET_KEY` and `SUPABASE_DB_PASSWORD` in `backend/.env` (see [backend/README.md](../backend/README.md) for where to find them). **Never share or commit this file.**
3. Website packages:
   ```bash
   cd admin-web
   npm install
   cd ..\maintenance-web
   npm install
   ```
4. Check the connection: `cd backend`, then `npm run smoke`. It must say `mode "supabase"`.

---

## Step 1: Start the backend (always first)

```bash
npm run api
```

Ready when you see `PATAG API http://127.0.0.1:4100/api`.

**Want the "Continue as…" demo buttons?** Set `ALLOW_DEMO=true` in `backend/.env` **before** starting it (or stop with **Ctrl+C** and start again). The startup line then ends with `(demo logins ENABLED: local use only)`. The backend only reads `.env` when it starts.

---

## Citizen

**Run the app** (start the Android emulator in Android Studio first):

```bash
cd citizen-mobile
flutter run --dart-define-from-file=env/emulator.json
```

| How to sign in | Steps |
|---|---|
| New account | Tap **Create account**. It is saved to Supabase immediately. |
| Demo citizen | Needs `ALLOW_DEMO=true`. Use the demo option on the sign-in screen. |

**Try it:** Report → add a photo → set the location (or use the map ⛶ full screen → tap the road → **Report a pothole here**) → details → submit.

---

## LGU administrator

**Run the website:**

```bash
cd admin-web
npm run dev
```

Open **http://127.0.0.1:5173/admin/login**.

| How to sign in | Steps |
|---|---|
| Demo admin | Needs `ALLOW_DEMO=true`. Click **Continue as LGU administrator**. |
| Real admin account | Create it once in `backend/` (PowerShell): `$env:ADMIN_NAME="Your Name"; $env:ADMIN_EMAIL="you@example.com"; $env:ADMIN_PASSWORD="at least fifteen characters"; npm run create-admin`, then sign in with that email and password. |

**Try it:** open a new report → **Verify** → **Assign** to a team. The admin can also create teams and crew accounts (Accounts / Teams pages).

---

## Road crew

Pick **one** of the two crew apps.

**Mobile app** (emulator running):

```bash
cd maintenance-mobile
flutter run --dart-define-from-file=env/emulator.json
```

**Or the website:**

```bash
cd maintenance-web
npm run dev
```

Open **http://127.0.0.1:5174/maintenance/login**.

| How to sign in | Steps |
|---|---|
| Demo crew (Road Crew Alpha) | Needs `ALLOW_DEMO=true`. Tap **Open maintenance demo**. |
| Real crew account | The LGU admin creates it in admin-web (with a team). Sign in with that email and password. |

**Try it:** open the assigned task → **Add Before Photo** → **Start** → **Add After Photo** → **Document & Submit Completion**. It then shows "Awaiting LGU verification" until the admin resolves it.

---

## Running the citizen and crew apps at the same time

Both Flutter apps can run on the same emulator: start one, then in another terminal start the other. Both stay installed, and you can switch between them on the emulator's home screen.

## Using a real phone instead of the emulator

| Connection | Backend | App |
|---|---|---|
| USB cable (USB debugging on) | `npm run api` and `npm run mobile:usb` | `flutter run --dart-define-from-file=env/usb.json` |
| Same Wi-Fi | `npm run api:lan` (prints the address to use) | copy `env/lan.example.json` to `env/lan.json`, put that address in it, `flutter run --dart-define-from-file=env/lan.json` |

Wi-Fi also needs the firewall rule in [backend/README.md](../backend/README.md). Demo logins are refused on Wi-Fi mode unless `ALLOW_DEMO_ON_LAN=true`.

---

## Troubleshooting

| What you see | Cause | Fix |
|---|---|---|
| "Endpoint not found" when pressing a demo/"Continue as…" button | Demo logins are off | Set `ALLOW_DEMO=true` in `backend/.env`, then **restart** the backend |
| "Connection timed out" / "Can't reach the PATAG server" / "Failed to fetch" | Backend not running | Step 1: `npm run api` |
| Backend won't start: port 4100 in use | An old backend is still running | Close its terminal, or in PowerShell: `Get-NetTCPConnection -LocalPort 4100 \| Select OwningProcess`, then `Stop-Process -Id <that number>` |
| `'C:\Moble' is not recognized` when running Flutter | Terminal uses the old Flutter path (space in "Moble dev") | Run `C:\flutter\bin\flutter run ...`, or restart the PC once |
| Website: `npm run dev` fails | Packages not installed | `npm install` in that website folder |
| Nothing new appears in Supabase | Looking at the wrong tables | Table Editor → schema **public** → `users`, `reports` (not the `patag_…` tables) |
