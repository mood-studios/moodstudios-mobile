import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import 'account_settings_screen.dart';
import 'edit_profile_screen.dart';
import 'preferences_screen.dart';

class ProfileHubScreen extends StatefulWidget {
  const ProfileHubScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProfileHubScreen> createState() => _ProfileHubScreenState();
}

class _ProfileHubScreenState extends State<ProfileHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final settings = context.read<SettingsProvider>();
      if (auth.user != null) {
        settings.applyFromUser(auth.user!.preferences);
      }
      await settings.loadPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.purplePale,
            child: Text(
              (user?.name.isNotEmpty == true ? user!.name[0] : '?').toUpperCase(),
              style: const TextStyle(fontSize: 36, color: AppColors.purple, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(user?.name ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(user?.email ?? '', style: const TextStyle(color: AppColors.muted)),
          if (user != null) ...[
            const SizedBox(height: 8),
            _VerifiedChip(verified: user.isVerified),
          ],
          const SizedBox(height: 24),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Edit profile',
            subtitle: 'Name, phone number',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Account settings',
            subtitle: 'Password, security, delete account',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.tune,
            title: 'Preferences',
            subtitle: 'Notifications, theme, language',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PreferencesScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip({required this.verified});
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: verified ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(verified ? Icons.verified : Icons.mark_email_unread,
              size: 16, color: verified ? Colors.green : Colors.orange),
          const SizedBox(width: 6),
          Text(
            verified ? 'Email verified' : 'Email not verified',
            style: TextStyle(fontSize: 12, color: verified ? Colors.green.shade800 : Colors.orange.shade800),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.purple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
