import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../network/api_client.dart';
import '../../providers/auth_provider.dart';
import 'push_notification_service.dart';

/// Registers the device for push after the user is logged in and verified.
class PushNotifications {
  static Future<void> syncWhenAuthenticated(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    final api = context.read<ApiClient>();
    final push = PushNotificationService.instance;
    final ready = await push.initialize();
    if (!ready) return;
    await push.registerWithBackend(api);
  }

  static Future<void> clearOnLogout() async {
    await PushNotificationService.instance.unregister();
  }
}
