# API_URL per environment

Each file holds only the backend address. **Never put keys or passwords here**: anything in an APK can be read.

| File | Use | Command |
|---|---|---|
| `emulator.json` | Android emulator, backend on this PC (`npm run api`) | `flutter run --dart-define-from-file=env/emulator.json` |
| `usb.json` | Phone on USB: run `npm run mobile:usb` first | `flutter run --dart-define-from-file=env/usb.json` |
| `lan.json` | Phone on the same Wi-Fi: run `npm run api:lan`, copy `lan.example.json` to `lan.json` with the LAN URL it prints | `flutter run --dart-define-from-file=env/lan.json` |
| `prod.json` | Hosted HTTPS backend: copy `prod.example.json` to `prod.json` with your real URL | `flutter build apk --release --dart-define-from-file=env/prod.json` |

`lan.json` and `prod.json` are git-ignored because the addresses are specific to your network or deployment.
