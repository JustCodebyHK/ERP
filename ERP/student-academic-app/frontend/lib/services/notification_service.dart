import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    final service = _instance;
    await service._init();
  }

  Future<void> _init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  static Future<bool> hasPermission() async {
    return true;
  }

  static Future<void> requestPermission() async {
    return;
  }

  static Future<void> requestPermissionWithHelp(BuildContext context) async {
    return;
  }

  static Future<void> showGroupMessage({
    required String groupName,
    required String senderName,
    required String message,
  }) async {
    final service = _instance;
    await service._showGroupMessage(
      groupName: groupName,
      senderName: senderName,
      message: message,
    );
  }

  Future<void> _showGroupMessage({
    required String groupName,
    required String senderName,
    required String message,
  }) async {
    const android = AndroidNotificationDetails(
      'group_chat_channel',
      'Group Chat',
      channelDescription: 'New messages in group chats',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: android);
    await _plugin.show(
      0,
      'New message in $groupName',
      '$senderName: $message',
      details,
    );
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
    await _plugin.show(id, title, body, details);
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
