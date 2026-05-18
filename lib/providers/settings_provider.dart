import 'package:flutter/material.dart';
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

  ThemeMode get themeMode {
    switch (_preferences.theme) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

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

  Future<bool> setTheme(String theme) =>
      updatePreferences(_preferences.copyWith(theme: theme));

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

  Future<bool> setLanguage(String language) =>
      updatePreferences(_preferences.copyWith(language: language));
}
