# SMARTTT Frontend

A Flutter mobile and desktop application for the SMARTTT Smart Timetable System. Students at Tharaka University can view their class schedule, sync registered units from the student portal, and manage their academic timetable.

---

## Tech Stack

- **Framework:** Flutter 3 (Dart SDK ^3.9.2)
- **State Management:** Riverpod
- **Navigation:** GoRouter
- **HTTP Client:** Dio
- **Local Storage:** SharedPreferences
- **WebView:** webview_flutter (mobile/web only)
- **Fonts & Icons:** Google Fonts, Iconsax

---

## Project Structure

```
SMARTTT_fronted/
├── lib/
│   ├── core/
│   │   ├── network/
│   │   │   └── api_client.dart       # Dio base client + base URL config
│   │   ├── theme/
│   │   │   └── app_theme.dart        # Colors, typography, dark/light theme
│   │   └── router/                   # GoRouter route definitions
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   └── auth_repository.dart   # Login, register, token storage
│   │   │   └── presentation/              # Login and Register screens
│   │   └── schedule/
│   │       ├── data/
│   │       │   └── timetable_repository.dart  # Fetch timetable, sync units
│   │       └── presentation/
│   │           ├── schedule_screen.dart        # Main timetable view (M/T/W/T/F/S/S)
│   │           └── portal_sync_screen.dart     # WebView portal sync (mobile) /
│   │                                           # Browser redirect (desktop)
│   └── main.dart
├── android/
├── ios/
├── linux/
├── windows/
├── macos/
├── web/
└── pubspec.yaml
```

---

## Prerequisites

- Flutter SDK (stable channel, version matching Dart SDK ^3.9.2)
- Dart SDK ^3.9.2
- For Android: Android Studio + emulator or physical device
- For Linux desktop: `clang`, `cmake`, `ninja-build`, `libgtk-3-dev`
- For Chrome: Chrome browser

---

## Local Setup

### 1. Clone the repository

```bash
git clone https://github.com/Kim-254-de/SMARTTT_fronted.git
cd SMARTTT_fronted
```

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Configure the backend URL

Open `lib/core/network/api_client.dart` and set the base URL to point to your local backend:

```dart
// For local development — change this line
const String _baseUrl = 'http://127.0.0.1:8000/api/v1/';
```

By default, the app ships pointing to the production server on Render:

```dart
// Production (default — do NOT use for local development)
const String _baseUrl = 'https://smarttt-backend-n44z.onrender.com/api/v1/';
```

> **Important:** If you skip this step, the app will hit the live Render server instead of your local Django backend. This causes `400 Bad Request` errors on registration and `401 Unauthorized` errors on the Schedule screen if your local account doesn't exist on the production server.

After making the change, hot restart the Flutter app by pressing `Shift+R` in the terminal running `flutter run`.

### 4. Run the app

```bash
# Check available devices
flutter devices

# Android emulator or physical device
flutter run -d android

# Chrome (web)
flutter run -d chrome

# Linux desktop
flutter run -d linux

# Windows desktop
flutter run -d windows
```

---

## Linux Desktop — Additional Setup

Install required system libraries before running on Linux:

```bash
sudo apt update
sudo apt install clang cmake ninja-build libgtk-3-dev -y
```

Then run:

```bash
flutter run -d linux
```

---

## Platform Support

| Platform | Supported | Notes |
|---|---|---|
| Android | ✅ | Full support including WebView portal sync |
| iOS | ✅ | Full support including WebView portal sync |
| Web (Chrome) | ✅ | Full support |
| Linux Desktop | ✅ | Portal sync opens in system browser instead of WebView |
| Windows Desktop | ✅ | Portal sync opens in system browser instead of WebView |
| macOS | ✅ | Portal sync opens in system browser instead of WebView |

> On desktop platforms, `webview_flutter` is not supported. The Portal Sync screen automatically detects the platform and opens the student portal in the default system browser instead.

---

## Features

### Class Schedule
- View weekly timetable (Monday to Sunday)
- Day selector with highlighted active day
- Shows unit name, room, lecturer, and time slot

### Portal Unit Sync (Mobile)
- Embedded WebView opens the Tharaka University student portal
- Automatically extracts registered units from the portal page
- Syncs extracted units to the backend with one tap

### Portal Unit Sync (Desktop)
- Opens the student portal in the system browser
- Students manually register units on the portal, which are then reflected in the app

### Authentication
- Student login and registration
- JWT token management (access + refresh)
- Tokens stored securely in SharedPreferences
- Auto token refresh on expiry

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^3.3.1 | State management |
| `go_router` | ^17.2.3 | Navigation |
| `dio` | ^5.9.2 | HTTP requests |
| `shared_preferences` | ^2.5.2 | Local token storage |
| `webview_flutter` | ^4.13.0 | In-app portal browser (mobile) |
| `google_fonts` | ^8.1.0 | Typography |
| `flutter_animate` | ^4.5.2 | Animations |
| `iconsax` | ^0.0.8 | Icons |
| `flutter_svg` | ^2.2.4 | SVG asset rendering |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

---

## Common Issues

**`WebViewPlatform.instance != null` crash on desktop**  
`webview_flutter` does not support Linux/Windows/macOS. The app handles this automatically by showing a browser redirect on desktop. If you see this error, make sure you are using the updated `portal_sync_screen.dart`.

**`DioException [bad response]: 401 Unauthorized` on Schedule screen**  
The JWT token is missing or expired. Log out and log back in. Also check that the backend URL in `api_client.dart` is correct and the backend is running.

**`DioException [bad response]: 400 Bad Request` on Register screen**  
The backend URL is pointing to the wrong server (production vs local). Update `api_client.dart` to point to your local backend at `http://127.0.0.1:8000/api/v1/`.

**`flutter pub get` fails**  
Make sure your Flutter SDK is on the stable channel: `flutter channel stable && flutter upgrade`.

**No devices found**  
Run `flutter doctor` to diagnose missing platform setup (Android SDK, emulator, Linux build tools, etc.).

---

## Related

- **Backend Repository:** [SMARTTT_BACKEND](https://github.com/Kim-254-de/SMARTTT_BACKEND)
- **Live API:** `https://smarttt-backend-n44z.onrender.com/api/v1/`
