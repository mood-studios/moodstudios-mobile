import '../core/network/api_client.dart';
import '../core/storage/auth_storage.dart';
import '../models/user_model.dart';

class AuthResult {
  const AuthResult({
    this.user,
    this.requiresVerification = false,
    this.registeredEmail,
  });

  final UserModel? user;
  final bool requiresVerification;
  final String? registeredEmail;
}

class AuthService {
  AuthService(this._client, this._storage);

  final ApiClient _client;
  final AuthStorage _storage;

  Future<AuthResult> login(String email, String password) async {
    final res = await _client.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>? ?? {};
    final requiresVerification = data['requiresVerification'] == true;

    if (requiresVerification) {
      UserModel? user;
      if (data['token'] != null) {
        user = await _saveAuthResponse(body);
      }
      return AuthResult(user: user, requiresVerification: true);
    }

    final user = await _saveAuthResponse(body);
    return AuthResult(user: user, requiresVerification: !user.isVerified);
  }

  Future<void> sendSignupOtp(String email) async {
    await _client.dio.post('/auth/send-signup-otp', data: {'email': email});
  }

  Future<void> verifySignupOtp(String email, String otp) async {
    await _client.dio.post('/auth/verify-signup-otp', data: {
      'email': email,
      'otp': otp,
    });
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final res = await _client.dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return _saveAuthResponse(res.data as Map<String, dynamic>);
  }

  Future<UserModel> verifyOtp(String email, String otp) async {
    final res = await _client.dio.post('/auth/verify-otp', data: {
      'email': email,
      'otp': otp,
    });
    return _saveAuthResponse(res.data as Map<String, dynamic>);
  }

  Future<void> resendOtp(String email) async {
    await _client.dio.post('/auth/resend-otp', data: {'email': email});
  }

  Future<void> sendForgotPasswordOtp(String email) async {
    await _client.dio.post('/auth/forgot-password/send-otp', data: {'email': email});
  }

  Future<void> resetForgotPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    await _client.dio.post('/auth/forgot-password/reset', data: {
      'email': email,
      'otp': otp,
      'password': password,
    });
  }

  Future<UserModel> fetchProfile() async {
    final res = await _client.dio.get('/users/profile');
    final user = UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
    final token = await _storage.getToken();
    if (token != null) await _storage.saveSession(token, user);
    return user;
  }

  Future<UserModel> updateProfile({String? name, String? phone}) async {
    final res = await _client.dio.put('/users/profile', data: {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data);
    final token = await _storage.getToken();
    if (token != null) await _storage.saveSession(token, user);
    return user;
  }

  Future<void> logout() => _storage.clear();

  Future<UserModel?> restoreSession() async {
    final token = await _storage.getToken();
    final user = await _storage.getUser();
    if (token == null || user == null) return null;
    if (!user.isVerified) return null;
    return user;
  }

  Future<UserModel> _saveAuthResponse(Map<String, dynamic> body) async {
    final data = body['data'] as Map<String, dynamic>;
    final token = data['token']?.toString() ?? '';
    final user = UserModel.fromJson(data);
    if (token.isNotEmpty) {
      await _storage.saveSession(token, user);
    }
    return user;
  }
}
