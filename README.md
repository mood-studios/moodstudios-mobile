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

**Production (default):** `https://moodstudios-backend.onrender.com`

Just run:

```bash
flutter run
```

**Local backend** (optional):

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api --dart-define=SOCKET_URL=http://10.0.2.2:5000
```

Health check: https://moodstudios-backend.onrender.com/api/health

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
