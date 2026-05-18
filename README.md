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

## Notes

- OTP appears in the backend console in development (`[MOCK OTP]`).
- Payment opens PayMongo flow structure; integrate PayMongo Flutter SDK for production checkout.
- Chat uses `GET /api/chat/studio` to resolve the admin contact.
