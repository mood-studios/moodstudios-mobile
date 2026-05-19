# Mood Studios — Flutter Mobile App

Customer mobile app for photography booking, aligned with **mood_studios-main** branding and the **backend** REST API.

## Design

- Purple `#960FFA`, pink `#DE538D`, background `#FAF0FA`
- DM Serif Display + Outfit (via Google Fonts)
- Dashboard cards matching the web customer UI (`cus_book_1`, `cus_upcoming`)

## Features

- Login / Register / OTP verification
- Browse services & categories (cart)
- Create bookings (date, time, special requests)
- View upcoming bookings & pay (PayMongo intent)
- Photo gallery per booking
- Real-time chat with studio (Socket.IO)
- Notifications
- Profile editing

## Setup

```bash
cd mobile_app
flutter pub get
```

### Backend URL

**Local (debug default):** with `npm run dev` in `backend/` (port 5000), run:

```bash
cd mobile_app
flutter run
```

The app uses:

| Platform | API URL |
|----------|---------|
| Android emulator | `http://10.0.2.2:5000/api` |
| Windows / iOS simulator / desktop | `http://127.0.0.1:5000/api` |
| Physical phone (same Wi‑Fi) | Your PC’s LAN IP, e.g. `http://192.168.1.10:5000/api` |

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000/api --dart-define=SOCKET_URL=http://192.168.1.10:5000
```

**Production (release builds):** `https://moodstudios-backend.onrender.com`

To hit Render while debugging: `flutter run --dart-define=FORCE_PRODUCTION=true`

Health check (local): http://127.0.0.1:5000/api/health

> Render free tier may sleep after inactivity; the first request can take ~30s to wake up.

### Test login (after seed)

- Email: `customer@moodstudios.test`
- Password: `Customer123!`

## Project structure

```
lib/
├── app.dart              # Providers & theme
├── core/                 # API, theme, storage
├── models/
├── services/             # API + Socket.IO
├── providers/
├── screens/
└── widgets/
```

## Push notifications (phone alerts)

The app registers an **FCM device token** after login and the backend sends pushes for bookings, payments, and chat (when configured).

### 1. Firebase project

1. Create a project at [Firebase Console](https://console.firebase.google.com/).
2. Add an **Android** app with package name `com.moodstudios.mood_studios_mobile`.
3. Add an **iOS** app with bundle ID `com.moodstudios.moodStudiosMobile` (if you ship on iOS).
4. Download config files (or use FlutterFire CLI below).

### 2. FlutterFire (recommended)

**Prerequisites**

1. Install Firebase CLI (if needed): `npm install -g firebase-tools`
2. Log in (required — fixes “Failed to authenticate”):

```bash
firebase login
```

A browser window opens; sign in with the Google account that owns project **mood-studios-3172f**.

**Configure the app** — from `mobile_app/`:

```bash
dart pub global activate flutterfire_cli
```

On Windows, `flutterfire` may not be on your PATH. Use either:

```powershell
# Option A — add Pub to PATH for this terminal session
$env:Path = "$env:LOCALAPPDATA\Pub\Cache\bin;" + $env:Path
flutterfire configure --project=mood-studios-3172f
```

```powershell
# Option B — always works without PATH
dart pub global run flutterfire_cli:flutterfire configure --project=mood-studios-3172f
```

When prompted to **create a new Firebase project**, choose **no** — you already have `mood-studios-3172f`.

This updates `lib/firebase_options.dart` and places `android/app/google-services.json` (and iOS plist).

Those files are **gitignored** (only `*.example` templates are in the repo). Each developer runs `flutterfire configure` locally after cloning.

**Verify login:** `firebase projects:list` should list `mood-studios-3172f`.

#### If GitHub flagged a leaked API key

1. [Google Cloud Console → Credentials](https://console.cloud.google.com/apis/credentials?project=mood-studios-3172f) — restrict then **rotate/delete** the exposed Browser/Android/iOS keys.
2. Re-run `flutterfire configure --project=mood-studios-3172f` in `mobile_app/`.
3. Commit only non-secret changes (`.gitignore`, docs). Do **not** commit `firebase_options.dart` or `google-services.json`.
4. Close the GitHub secret scanning alert as **Revoked**.

Removing files from git does not erase them from **history**; rotation is what invalidates the leaked key.

### 3. Backend (FCM HTTP v1)

Your Firebase project uses **FCM API (V1)** enabled and **Legacy disabled** — that is correct.

The API does **not** use a legacy server key. In `backend/.env` set:

| Variable | Description |
|----------|-------------|
| `FIREBASE_PROJECT_ID` | `mood-studios-3172f` |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to service account JSON (local dev) |

**Get the JSON:** Firebase Console → ⚙️ Project settings → **Service accounts** → **Generate new private key** → save as `backend/firebase-service-account.json` (gitignored).

**Render:** copy the JSON into one line as `FIREBASE_SERVICE_ACCOUNT_JSON` (see `backend/.env.example`).

Without credentials, notifications are still saved in the database; the API logs `[MOCK FCM v1]` in development instead of pushing.

### 4. Run on a real device

- Use a **physical phone** or an emulator with **Google Play** image (FCM does not work on all emulator images).
- After login, allow notification permission when prompted.
- Toggle categories under **Profile → Preferences → Push notifications**.

Until Firebase is configured, the app runs normally; only system push is disabled (in-app notification list still works).

## Notes

- OTP appears in the backend console in development (`[MOCK OTP]`).
- Payment opens PayMongo flow structure; integrate PayMongo Flutter SDK for production checkout.
- Chat uses `GET /api/chat/studio` to resolve the admin contact.
