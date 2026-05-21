import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_badge_provider.dart';
import '../../screens/bookings/booking_detail_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/gallery/gallery_screen.dart';
import '../../screens/home/home_screen.dart';

/// Navigate to the screen that matches this notification (uses root navigator).
void navigateFromNotification(AppNotification notification) {
  final context = appNavigatorKey.currentContext;
  if (context == null) return;

  switch (notification.type) {
    case 'message':
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
      return;
    case 'booking':
    case 'payment':
      if (notification.referenceId.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookingDetailScreen(bookingId: notification.referenceId),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 3)),
        );
      }
      return;
    case 'gallery':
      if (notification.referenceId.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GalleryScreen(bookingId: notification.referenceId),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 2)),
        );
      }
      return;
    default:
      return;
  }
}

void refreshNotificationBadge() {
  final context = appNavigatorKey.currentContext;
  if (context == null) return;
  try {
    context.read<NotificationBadgeProvider>().refresh();
  } catch (_) {
    /* provider not mounted */
  }
}
