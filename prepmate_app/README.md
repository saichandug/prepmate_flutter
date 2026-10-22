# PrepMate (Flutter app)

Flutter client for the PrepMate API. It runs on Android, iOS, web and Windows from one codebase and talks to the Express + MongoDB backend in `../backend`.

## 1. Start the backend

See `../backend/README.md`. For local testing run it on your PC (`npm run dev`, port 5000). The app defaults to the hosted API at `https://prepmate-aity.onrender.com`, so you can also skip this step and use that.

## 2. One-time Flutter setup

Install Flutter (https://docs.flutter.dev/get-started/install), then from this folder:

```powershell
.\setup.ps1          # Windows
./setup.sh           # macOS / Linux
```

This creates the `android/`, `ios/`, `web/` folders, adds the Android internet permission and runs `flutter pub get`.

## 3. Run

```bash
flutter run                                   # uses https://prepmate-aity.onrender.com
flutter run -d chrome                         # web
flutter run --dart-define=API_URL=http://10.0.2.2:5000    # Android emulator -> backend on your PC
flutter run --dart-define=API_URL=http://localhost:5000   # web / Windows -> backend on your PC
```

On a real phone use your PC's LAN address, e.g. `--dart-define=API_URL=http://192.168.1.20:5000`. Android blocks plain `http://` addresses in release builds, so use an `https://` API for release.

## Build

```bash
flutter build apk --dart-define=API_URL=https://your-api.example.com
flutter build web --dart-define=API_URL=https://your-api.example.com
```

## How it is organised

| Folder | Purpose |
| --- | --- |
| `lib/logic/` | Pure Dart ports of the original JS logic: validation, JD analyzer, answer scoring, roadmap, streaks |
| `lib/data/` | Question bank and skill dictionary (generated from the original JS data) |
| `lib/services/` | API client (Bearer token) and token storage |
| `lib/providers/` | `AuthController` (sign in / sign up / sign out) and `WorkspaceController` (applications + progress) |
| `lib/screens/` | Login, dashboard, applications, preparation (JD analyzer + roadmap), coding practice, mock interview, streak |

## Tests

```bash
flutter test                         # unit tests
dart run tool/parity_check.dart      # compares the Dart logic with the original JavaScript outputs
```
