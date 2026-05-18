import '../core/network/api_client.dart';
import '../core/storage/auth_storage.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService(this._client, this._storage);

  final ApiClient _client;
  final AuthStorage _storage;

  Future<UserModel> login(String email, String password) async {
    final res = await _client.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return _saveAuthResponse(res.data as Map<String, dynamic>);
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
    return user;
  }

  Future<UserModel> _saveAuthResponse(Map<String, dynamic> body) async {
    final data = body['data'] as Map<String, dynamic>;
    final token = data['token']?.toString() ?? '';
    final user = UserModel.fromJson(data);
    await _storage.saveSession(token, user);
    return user;
  }
}
