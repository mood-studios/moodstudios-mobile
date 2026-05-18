import '../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService(this._client);

  final ApiClient _client;

  Future<List<AppNotification>> getNotifications({bool unreadOnly = false}) async {
    final res = await _client.dio.get('/notifications', queryParameters: {
      if (unreadOnly) 'unreadOnly': 'true',
    });
    final list = res.data['data'] as List;
    return list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markAsRead(String id) async {
    await _client.dio.patch('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _client.dio.patch('/notifications/read-all');
  }
}
