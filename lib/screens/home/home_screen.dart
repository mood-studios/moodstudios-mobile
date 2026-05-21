import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/push/push_notifications.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_badge_provider.dart';
import '../../widgets/mood_bottom_nav.dart';
import '../../widgets/mood_logo.dart';
import '../auth/login_screen.dart';
import '../bookings/my_bookings_screen.dart';
import '../chat/chat_screen.dart';
import '../gallery/gallery_hub_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_hub_screen.dart';
import '../services/services_screen.dart';
import 'home_dashboard_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _navItems = [
    MoodNavItem(icon: Icons.home_outlined, label: 'Home'),
    MoodNavItem(icon: Icons.camera_alt_outlined, label: 'Book'),
    MoodNavItem(icon: Icons.photo_library_outlined, label: 'Gallery'),
    MoodNavItem(icon: Icons.history, label: 'Bookings'),
    MoodNavItem(icon: Icons.person_outline, label: 'Profile'),
  ];

  late int _index;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _index = widget.initialIndex.clamp(0, _navItems.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      PushNotifications.syncWhenAuthenticated(context);
      context.read<NotificationBadgeProvider>().refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<NotificationBadgeProvider>().refresh();
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  void _goTo(int index) => setState(() => _index = index);

  Widget _navPad(Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 88),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: MoodLogo(size: 40),
        ),
        leadingWidth: 56,
        title: const Text(
          'Mood Studios',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.text),
        ),
        actions: [
          Consumer<NotificationBadgeProvider>(
            builder: (context, badge, _) {
              return IconButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                  if (context.mounted) {
                    context.read<NotificationBadgeProvider>().refresh();
                  }
                },
                icon: Badge(
                  isLabelVisible: badge.unreadCount > 0,
                  backgroundColor: AppColors.purple,
                  label: Text(
                    badge.unreadCount > 99 ? '99+' : '${badge.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Icon(Icons.notifications_outlined, color: AppColors.text),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.text),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.muted),
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          HomeDashboardTab(
            onOpenBook: () => _goTo(1),
            onOpenGallery: () => _goTo(2),
            onOpenBookings: () => _goTo(3),
          ),
          _navPad(const ServicesScreen(embedded: true)),
          _navPad(const GalleryHubScreen(embedded: true)),
          _navPad(const MyBookingsScreen(embedded: true)),
          _navPad(const ProfileHubScreen(embedded: true)),
        ],
      ),
      bottomNavigationBar: MoodBottomNav(
        currentIndex: _index,
        onTap: _goTo,
        items: _navItems,
      ),
    );
  }
}
