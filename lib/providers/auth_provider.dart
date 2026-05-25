import 'package:flutter/foundation.dart';
import '../core/push/push_notification_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);

  final AuthService _authService;

  UserModel? _user;
  bool _loading = false;
  String? _error;
  String? _pendingEmail;
  bool _needsVerification = false;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null && _user!.isVerified;
  bool get loading => _loading;
  String? get error => _error;
  String? get pendingEmail => _pendingEmail;
  bool get needsVerification => _needsVerification;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    _user = await _authService.restoreSession();
    _needsVerification = false;
    _loading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    return _run(() async {
      final result = await _authService.login(email, password);
      _user = result.user;
      _pendingEmail = result.requiresVerification ? email : null;
      _needsVerification = result.requiresVerification;
    });
  }

  Future<bool> sendSignupOtp(String email) async {
    return _run(() async {
      await _authService.sendSignupOtp(email);
    });
  }

  Future<bool> verifySignupEmail(String email, String otp) async {
    return _run(() async {
      await _authService.verifySignupOtp(email, otp);
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
      _pendingEmail = null;
      _needsVerification = false;
    });
  }

  Future<bool> verifyOtp(String email, String otp) async {
    return _run(() async {
      _user = await _authService.verifyOtp(email, otp);
      _pendingEmail = null;
      _needsVerification = false;
    });
  }

  Future<bool> resendOtp(String email) async {
    return _run(() async {
      await _authService.resendOtp(email);
    });
  }

  Future<bool> sendForgotPasswordOtp(String email) async {
    return _run(() async {
      await _authService.sendForgotPasswordOtp(email);
    });
  }

  Future<bool> resetForgotPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    return _run(() async {
      await _authService.resetForgotPassword(
        email: email,
        otp: otp,
        password: password,
      );
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
    await PushNotificationService.instance.unregister();
    await _authService.logout();
    _user = null;
    _pendingEmail = null;
    _needsVerification = false;
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
      _error = _messageFromError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  static String _messageFromError(Object e) {
    final text = e.toString();
    const prefix = 'DioException [bad response]: ';
    if (text.startsWith(prefix)) {
      return text.substring(prefix.length);
    }
    return text.replaceFirst('Exception: ', '');
  }
}
