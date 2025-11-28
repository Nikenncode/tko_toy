// lib/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // ANDROID INIT
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    // IOS INIT – 🔥 ask for permissions here
    final ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // optional: handle when user taps notification while app is in foreground/background
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    final initSettings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _plugin.initialize(
      initSettings,
      // optional: tapped callback
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }

  // Called on iOS < 10 when a notification is received in foreground
  static void _onDidReceiveLocalNotification(
      int id,
      String? title,
      String? body,
      String? payload,
      ) {
    // You can show a dialog or navigate if you want.
  }

  // Called when user taps a notification (Android + iOS)
  static void _onDidReceiveNotificationResponse(
      NotificationResponse response) {
    // You can navigate based on payload if needed
  }

  static Future<void> showBasic({
    required String title,
    required String body,
  }) async {
    // ANDROID CHANNEL
    const android = AndroidNotificationDetails(
      'default_channel',
      'Default',
      channelDescription: 'General notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    // iOS DETAILS
    const ios = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: android,
      iOS: ios,
    );

    await _plugin.show(
      0,     // notification id (you can change or randomize)
      title,
      body,
      details,
    );
  }
}
