import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final prefs = settings.preferences;

    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _SectionTitle('Appearance'),
                Card(
                  child: Column(
                    children: [
                      _ThemeSelector(
                        value: prefs.theme,
                        onChanged: (v) => settings.setTheme(v),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Language'),
                        subtitle: Text(_languageLabel(prefs.language)),
                        trailing: DropdownButton<String>(
                          value: prefs.language,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'en', child: Text('English')),
                            DropdownMenuItem(value: 'fil', child: Text('Filipino')),
                          ],
                          onChanged: (v) {
                            if (v != null) settings.setLanguage(v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionTitle('Push notifications'),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Booking updates'),
                        subtitle: const Text('Confirmations, schedule changes'),
                        value: prefs.notifications.booking,
                        activeTrackColor: AppColors.purple,
                        onChanged: (v) => settings.setNotificationPref(booking: v),
                      ),
                      SwitchListTile(
                        title: const Text('Payment updates'),
                        value: prefs.notifications.payment,
                        activeTrackColor: AppColors.purple,
                        onChanged: (v) => settings.setNotificationPref(payment: v),
                      ),
                      SwitchListTile(
                        title: const Text('New messages'),
                        value: prefs.notifications.messages,
                        activeTrackColor: AppColors.purple,
                        onChanged: (v) => settings.setNotificationPref(messages: v),
                      ),
                      SwitchListTile(
                        title: const Text('Promotions & news'),
                        value: prefs.notifications.marketing,
                        activeTrackColor: AppColors.purple,
                        onChanged: (v) => settings.setNotificationPref(marketing: v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionTitle('Email'),
                Card(
                  child: SwitchListTile(
                    title: const Text('Email digest'),
                    subtitle: const Text('Summary of bookings and gallery updates'),
                    value: prefs.emailDigest,
                    activeColor: AppColors.purple,
                    onChanged: (v) => settings.setNotificationPref(emailDigest: v),
                  ),
                ),
              ],
            ),
    );
  }

  static String _languageLabel(String code) {
    switch (code) {
      case 'fil':
        return 'Filipino';
      default:
        return 'English';
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.muted)),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Theme', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'light', label: Text('Light'), icon: Icon(Icons.light_mode)),
              ButtonSegment(value: 'dark', label: Text('Dark'), icon: Icon(Icons.dark_mode)),
              ButtonSegment(value: 'system', label: Text('System'), icon: Icon(Icons.phone_android)),
            ],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ],
      ),
    );
  }
}
