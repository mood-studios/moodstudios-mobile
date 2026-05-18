import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/mood_scaffold.dart';
import '../auth/login_screen.dart';
import '../bookings/my_bookings_screen.dart';
import '../chat/chat_screen.dart';
import '../gallery/gallery_hub_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_hub_screen.dart';
import '../services/services_screen.dart';

enum HomeTab { book, gallery, upcoming, profile }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialTab = HomeTab.book});

  final HomeTab initialTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return MoodScaffold(
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatScreen()),
          ),
        ),
        IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'Hello, ${user?.name.split(' ').first ?? 'there'}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                DashboardCard(
                  title: 'Book Session',
                  subtitle: 'Schedule your next shoot',
                  icon: Icons.camera_alt,
                  active: _tab == HomeTab.book,
                  onTap: () => setState(() => _tab = HomeTab.book),
                ),
                const SizedBox(width: 10),
                DashboardCard(
                  title: 'My Gallery',
                  subtitle: 'View your photos',
                  icon: Icons.photo_library_outlined,
                  active: _tab == HomeTab.gallery,
                  onTap: () => setState(() => _tab = HomeTab.gallery),
                ),
                const SizedBox(width: 10),
                DashboardCard(
                  title: 'Upcoming',
                  subtitle: 'Your bookings',
                  icon: Icons.event,
                  active: _tab == HomeTab.upcoming,
                  onTap: () => setState(() => _tab = HomeTab.upcoming),
                ),
                const SizedBox(width: 10),
                DashboardCard(
                  title: 'Profile',
                  subtitle: 'Edit your details',
                  icon: Icons.person_outline,
                  active: _tab == HomeTab.profile,
                  onTap: () => setState(() => _tab = HomeTab.profile),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case HomeTab.book:
        return const ServicesScreen(embedded: true);
      case HomeTab.gallery:
        return const GalleryHubScreen(embedded: true);
      case HomeTab.upcoming:
        return const MyBookingsScreen(embedded: true);
      case HomeTab.profile:
        return const ProfileHubScreen(embedded: true);
    }
  }
}
