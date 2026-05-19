import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/push/push_notifications.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/mood_logo.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.init();
    if (!mounted) return;
    if (auth.user != null) {
      context.read<SettingsProvider>().applyFromUser(auth.user!.preferences);
    }
    if (auth.isAuthenticated) {
      await PushNotifications.syncWhenAuthenticated(context);
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.purple.withValues(alpha: 0.2),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MoodLogo(size: 88),
                const SizedBox(height: 20),
                Text('Mood Studios', style: AppTheme.displayHeading(context, size: 32)),
                const SizedBox(height: 8),
                const Text('Capture every moment', style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 32),
                const CircularProgressIndicator(color: AppColors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
