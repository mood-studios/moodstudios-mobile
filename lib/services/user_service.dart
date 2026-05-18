import '../core/network/api_client.dart';
import '../core/storage/auth_storage.dart';
import '../models/user_model.dart';
import '../models/user_preferences.dart';

class UserService {
  UserService(this._client, this._storage);

  final ApiClient _client;
  final AuthStorage _storage;

  Future<UserModel> fetchProfile() async {
    final res = await _client.dio.get('/users/profile');
    final user = UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
    await _persistUser(user);
    return user;
  }

  Future<UserModel> updateProfile({String? name, String? phone}) async {
    final res = await _client.dio.put('/users/profile', data: {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
    });
    final user = UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
    await _persistUser(user);
    return user;
  }

  Future<UserPreferences> fetchPreferences() async {
    final res = await _client.dio.get('/users/preferences');
    return UserPreferences.fromJson(res.data['data'] as Map<String, dynamic>?);
  }

  Future<UserPreferences> updatePreferences(UserPreferences prefs) async {
    final res = await _client.dio.put('/users/preferences', data: prefs.toJson());
    return UserPreferences.fromJson(res.data['data'] as Map<String, dynamic>?);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.dio.put('/users/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> deleteAccount(String password) async {
    await _client.dio.delete('/users/me', data: {'password': password});
    await _storage.clear();
  }

  Future<void> _persistUser(UserModel user) async {
    final token = await _storage.getToken();
    if (token != null) await _storage.saveSession(token, user);
  }
}
