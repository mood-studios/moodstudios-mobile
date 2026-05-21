import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationBadgeProvider extends ChangeNotifier {
  NotificationBadgeProvider(this._notificationService);

  final NotificationService _notificationService;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  Future<void> refresh() async {
    try {
      final list = await _notificationService.getNotifications(unreadOnly: true);
      _unreadCount = list.length;
    } catch (_) {
      _unreadCount = 0;
    }
    notifyListeners();
  }

  void setCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }
}
