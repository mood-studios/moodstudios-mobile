import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/resume_draft_banner.dart';

class HomeDashboardTab extends StatelessWidget {
  const HomeDashboardTab({
    super.key,
    required this.onOpenBook,
    required this.onOpenGallery,
    required this.onOpenBookings,
  });

  final VoidCallback onOpenBook;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenBookings;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = user?.name.split(' ').first ?? 'there';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              'Hello, $firstName',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'What would you like to do today?',
              style: TextStyle(fontSize: 14, color: AppColors.muted.withValues(alpha: 0.9)),
            ),
          ),
          const ResumeDraftBanner(),
          SizedBox(
            height: 118,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                DashboardCard(
                  title: 'Book Session',
                  subtitle: 'Schedule your next shoot',
                  icon: Icons.camera_alt_outlined,
                  onTap: onOpenBook,
                ),
                const SizedBox(width: 12),
                DashboardCard(
                  title: 'My Gallery',
                  subtitle: 'View your photos',
                  icon: Icons.photo_library_outlined,
                  onTap: onOpenGallery,
                ),
                const SizedBox(width: 12),
                DashboardCard(
                  title: 'Upcoming',
                  subtitle: 'Your bookings',
                  icon: Icons.calendar_today_outlined,
                  onTap: onOpenBookings,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Use the menu below to browse services, gallery, and your profile.',
              style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
