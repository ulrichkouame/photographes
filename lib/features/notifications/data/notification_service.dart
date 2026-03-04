/// Firebase FCM notification service: setup, foreground/background handling.
library;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler – must be top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.showLocalNotification(message);
}

/// Singleton service for Firebase Cloud Messaging and local notifications.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  late final FirebaseMessaging _messaging;

  String? _fcmToken;

  /// Returns the device FCM token.
  String? get fcmToken => _fcmToken;

  /// Initializes FCM and local notifications.
  Future<void> initialize() async {
    _messaging = FirebaseMessaging.instance;

    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Get token
    _fcmToken = await _messaging.getToken();

    // Token refresh
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
    });

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      showLocalNotification(message);
    });
  }

  /// Displays a local notification from a [RemoteMessage].
  Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'photographes_ci',
      'Photographes.ci',
      channelDescription: 'Notifications Photographes.ci',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }
}
