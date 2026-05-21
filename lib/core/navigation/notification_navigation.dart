import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../screens/bookings/booking_detail_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/home/home_screen.dart';

void navigateFromNotification(BuildContext context, AppNotification notification) {
  switch (notification.type) {
    case 'message':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
      return;
    case 'booking':
    case 'payment':
      if (notification.referenceId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailScreen(bookingId: notification.referenceId),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 3)),
        );
      }
      return;
    default:
      return;
  }
}
