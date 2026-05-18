/// API base URL for the Mood Studios backend.
///
/// **Production (default):** https://moodstudios-backend.onrender.com
///
/// **Local backend** (`npm run dev`):
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api --dart-define=SOCKET_URL=http://10.0.2.2:5000
/// ```
/// iOS simulator: use `http://localhost:5000` instead of `10.0.2.2`.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://moodstudios-backend.onrender.com/api',
  );

  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://moodstudios-backend.onrender.com',
  );
}
