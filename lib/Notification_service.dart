import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const ios = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _plugin.initialize(initSettings);
  }

  static Future<void> showBasic({
    required String title,
    required String body,
  }) async {
    const android = AndroidNotificationDetails(
      'default_channel',
      'Default',
      channelDescription: 'General notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const ios = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: android,
      iOS: ios,
    );

    await _plugin.show(
      0,
      title,
      body,
      details,
    );
  }
}
