import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'core/storage/auth_storage.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/settings_provider.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/booking_service.dart';
import 'services/catalog_service.dart';
import 'services/chat_service.dart';
import 'services/gallery_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

class MoodStudiosApp extends StatelessWidget {
  const MoodStudiosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = AuthStorage();
    final apiClient = ApiClient(storage);

    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>(create: (_) => AuthService(apiClient, storage)),
        Provider<CatalogService>(create: (_) => CatalogService(apiClient)),
        Provider<BookingService>(create: (_) => BookingService(apiClient)),
        Provider<GalleryService>(create: (_) => GalleryService(apiClient)),
        Provider<ChatService>(create: (_) => ChatService(apiClient)),
        Provider<NotificationService>(create: (_) => NotificationService(apiClient)),
        Provider<UserService>(create: (_) => UserService(apiClient, storage)),
        ChangeNotifierProvider(create: (ctx) => AuthProvider(ctx.read<AuthService>())),
        ChangeNotifierProvider(create: (ctx) => SettingsProvider(ctx.read<UserService>())),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Mood Studios',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
