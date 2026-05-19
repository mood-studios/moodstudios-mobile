/// API base URL for the Mood Studios backend (Render production).
///
/// Override only if needed:
/// ```bash
/// flutter run --dart-define=API_BASE_URL=https://your-host.onrender.com/api --dart-define=SOCKET_URL=https://your-host.onrender.com
/// ```
class ApiConfig {
  static const String productionApi =
      'https://moodstudios-backend.onrender.com/api';
  static const String productionSocket =
      'https://moodstudios-backend.onrender.com';

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    return productionApi;
  }

  static String get socketUrl {
    const override = String.fromEnvironment('SOCKET_URL');
    if (override.isNotEmpty) return override;
    return productionSocket;
  }
}
