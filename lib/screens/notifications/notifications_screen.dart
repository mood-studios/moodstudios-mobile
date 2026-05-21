import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/navigation/notification_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_badge_provider.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final list = await context.read<NotificationService>().getNotifications();
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
        context.read<NotificationBadgeProvider>().setCount(
              list.where((n) => !n.isRead).length,
            );
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onTap(AppNotification n) async {
    if (!n.isRead) {
      await context.read<NotificationService>().markAsRead(n.id);
    }
    if (!mounted) return;
    Navigator.pop(context);
    navigateFromNotification(n);
    refreshNotificationBadge();
  }

  int get _unreadCount => _items.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    final unread = _unreadCount;
    return Scaffold(
      appBar: AppBar(
        title: Text(unread > 0 ? 'Notifications ($unread)' : 'Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<NotificationService>().markAllAsRead();
              await _load();
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : _items.isEmpty
              ? const Center(child: Text('No notifications yet'))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.purple,
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final n = _items[i];
                      return ListTile(
                        leading: Icon(
                          n.isRead ? Icons.notifications_none : Icons.notifications_active,
                          color: AppColors.purple,
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(n.message),
                        trailing: Text(
                          DateFormat.MMMd().format(n.createdAt),
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                        onTap: () => _onTap(n),
                      );
                    },
                  ),
                ),
    );
  }
}
