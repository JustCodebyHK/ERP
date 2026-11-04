import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String type = 'info',
    DateTime? scheduledAt,
  }) async {
    const android = AndroidNotificationDetails(
      'channel_id',
      'Channel',
      channelDescription: 'App notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: android);
    if (scheduledAt != null) {
      await _plugin.zonedSchedule(
        id, title, body, scheduledAt, details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      await _plugin.show(id, title, body, details);
    }
  }

  Future<void> showInfoNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await showNotification(id: id, title: title, body: body, type: 'info');
  }

  Future<void> showWarningNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await showNotification(id: id, title: title, body: body, type: 'warning');
  }

  Future<void> showErrorNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await showNotification(id: id, title: title, body: body, type: 'error');
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
