import 'package:flutter/foundation.dart';

/// API base URL for the Mood Studios backend.
///
/// **Debug (default):** local backend at port 5000 (`npm run dev` in `backend/`).
/// **Release:** Render production URL.
///
/// Override anytime:
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000/api --dart-define=SOCKET_URL=http://192.168.1.10:5000
/// ```
///
/// Force production while debugging:
/// ```bash
/// flutter run --dart-define=FORCE_PRODUCTION=true
/// ```
class ApiConfig {
  static const String productionApi = 'https://moodstudios-backend.onrender.com/api';
  static const String productionSocket = 'https://moodstudios-backend.onrender.com';

  /// Host for local dev (no path). Android emulator uses 10.0.2.2 → host machine.
  static String get _localOrigin {
    if (kIsWeb) return 'http://localhost:5000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://127.0.0.1:5000';
  }

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    const forceProduction = bool.fromEnvironment('FORCE_PRODUCTION');
    if (kReleaseMode || forceProduction) return productionApi;

    return '$_localOrigin/api';
  }

  static String get socketUrl {
    const override = String.fromEnvironment('SOCKET_URL');
    if (override.isNotEmpty) return override;

    const forceProduction = bool.fromEnvironment('FORCE_PRODUCTION');
    if (kReleaseMode || forceProduction) return productionSocket;

    return _localOrigin;
  }

  /// True when the app is talking to a local/dev server (for UI hints).
  static bool get isLocalDev => !baseUrl.startsWith('https://moodstudios-backend');
}
