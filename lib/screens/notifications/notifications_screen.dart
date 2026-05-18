import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/notification_model.dart';
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
      if (mounted) setState(() {
        _items = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<NotificationService>().markAllAsRead();
              _load();
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
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final n = _items[i];
                      return ListTile(
                        leading: Icon(
                          n.isRead ? Icons.notifications_none : Icons.notifications_active,
                          color: AppColors.purple,
                        ),
                        title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600)),
                        subtitle: Text(n.message),
                        trailing: Text(DateFormat.MMMd().format(n.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        onTap: () async {
                          if (!n.isRead) {
                            await context.read<NotificationService>().markAsRead(n.id);
                            _load();
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
