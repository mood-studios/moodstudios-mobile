import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);

  final AuthService _authService;

  UserModel? _user;
  bool _loading = false;
  String? _error;
  String? _pendingEmail;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;
  String? get pendingEmail => _pendingEmail;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    _user = await _authService.restoreSession();
    _loading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    return _run(() async {
      _user = await _authService.login(email, password);
    });
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    return _run(() async {
      _user = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      _pendingEmail = email;
    });
  }

  Future<bool> verifyOtp(String email, String otp) async {
    return _run(() async {
      _user = await _authService.verifyOtp(email, otp);
      _pendingEmail = null;
    });
  }

  Future<bool> resendOtp(String email) async {
    return _run(() async {
      await _authService.resendOtp(email);
    });
  }

  Future<bool> updateProfile({String? name, String? phone}) async {
    return _run(() async {
      _user = await _authService.updateProfile(name: name, phone: phone);
    });
  }

  void applyUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  Future<bool> refreshProfile() async {
    return _run(() async {
      _user = await _authService.fetchProfile();
    });
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _pendingEmail = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
