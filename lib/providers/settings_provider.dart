import 'package:flutter/foundation.dart';
import '../models/user_preferences.dart';
import '../services/user_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._userService);

  final UserService _userService;

  UserPreferences _preferences = const UserPreferences();
  bool _loading = false;
  String? _error;

  UserPreferences get preferences => _preferences;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadPreferences() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _preferences = await _userService.fetchPreferences();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void applyFromUser(UserPreferences prefs) {
    _preferences = prefs;
    notifyListeners();
  }

  Future<bool> updatePreferences(UserPreferences prefs) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _preferences = await _userService.updatePreferences(prefs);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setNotificationPref({
    bool? booking,
    bool? payment,
    bool? messages,
    bool? marketing,
    bool? emailDigest,
  }) =>
      updatePreferences(
        _preferences.copyWith(
          emailDigest: emailDigest,
          notifications: _preferences.notifications.copyWith(
            booking: booking,
            payment: payment,
            messages: messages,
            marketing: marketing,
          ),
        ),
      );
}
