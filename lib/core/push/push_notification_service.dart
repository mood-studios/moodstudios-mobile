import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../network/api_client.dart';
import '../navigation/notification_navigation.dart';
import '../../models/notification_model.dart';
import '../../screens/notifications/notifications_screen.dart';

const _channelId = 'mood_studios_alerts';
const _channelName = 'Mood Studios';

/// Background FCM handler (must be top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('[FCM background] ${message.notification?.title}');
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _messaging;
  ApiClient? _apiClient;
  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;
  bool _firebaseReady = false;
  bool _tokenRefreshListening = false;

  bool get isReady => _firebaseReady;

  bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  void bindNavigator(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  Future<bool> initialize() async {
    if (_initialized) return _firebaseReady;
    _initialized = true;

    if (kIsWeb || !_isMobile) {
      return false;
    }
    if (!DefaultFirebaseOptions.isConfigured) {
      if (kDebugMode) {
        debugPrint(
          '[Push] Firebase not configured. Run `flutterfire configure` in mobile_app/.',
        );
      }
      return false;
    }

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).timeout(
        const Duration(seconds: 15),
      );
      _messaging = FirebaseMessaging.instance;
      await _setupLocalNotifications().timeout(const Duration(seconds: 10));
      await _requestPermission().timeout(const Duration(seconds: 15));
      _listenMessages();
      _firebaseReady = true;
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Push] init failed: $e\n$st');
      }
      return false;
    }
  }

  Future<void> registerWithBackend(ApiClient client) async {
    if (!_firebaseReady || _messaging == null) return;
    _apiClient = client;

    final token = await _messaging!
        .getToken()
        .timeout(const Duration(seconds: 12), onTimeout: () => null);
    if (token != null) {
      await _uploadToken(token);
    }

    if (!_tokenRefreshListening) {
      _tokenRefreshListening = true;
      FirebaseMessaging.instance.onTokenRefresh.listen(_uploadToken);
    }
  }

  Future<void> unregister() async {
    try {
      if (_apiClient != null) {
        await _apiClient!.dio.put('/users/profile', data: {'fcmToken': ''});
      }
      await _messaging?.deleteToken();
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] unregister failed: $e');
    }
    _apiClient = null;
  }

  Future<void> _uploadToken(String token) async {
    final client = _apiClient;
    if (client == null || token.isEmpty) return;
    try {
      await client.dio
          .put('/users/profile', data: {'fcmToken': token})
          .timeout(const Duration(seconds: 15));
      if (kDebugMode) debugPrint('[Push] FCM token registered with backend');
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] token upload failed: $e');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      final plugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await plugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Booking, payment, and message alerts',
          importance: Importance.high,
        ),
      );
    }
  }

  Future<void> _requestPermission() async {
    final messaging = _messaging!;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
    } else {
      await messaging.requestPermission();
    }
  }

  void _listenMessages() {
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    _messaging!.getInitialMessage().then((message) {
      if (message != null) _handleOpenedMessage(message);
    });
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    refreshNotificationBadge();
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Booking, payment, and message alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: '${message.data['type'] ?? 'general'}|${message.data['referenceId'] ?? ''}',
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.contains('|')) {
      final parts = payload.split('|');
      _navigateFromPushData({
        'type': parts[0],
        'referenceId': parts.length > 1 ? parts[1] : '',
      });
    } else if (payload != null && payload.isNotEmpty) {
      _navigateFromPushData({'type': payload});
    } else {
      _openNotifications();
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    _navigateFromPushData(message.data);
  }

  void _navigateFromPushData(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? 'general';
    final ref = data['referenceId']?.toString() ?? data['bookingId']?.toString() ?? '';

    if (type == 'general' || type.isEmpty) {
      _openNotifications();
      return;
    }

    navigateFromNotification(
      AppNotification(
        id: '',
        title: '',
        message: '',
        type: type,
        referenceId: ref,
        isRead: true,
        createdAt: DateTime.now(),
      ),
    );
    refreshNotificationBadge();
  }

  void _openNotifications() {
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }
}
