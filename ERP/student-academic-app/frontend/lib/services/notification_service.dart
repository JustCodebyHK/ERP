import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Wraps local notifications so the app can pop up a system notification
/// when a new group chat message arrives.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    try {
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }
  }

  /// Asks the user for permission to show notifications (Android 13+).
  /// Returns true when notifications are allowed.
  static Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;
    await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      if (granted == true) return true;
      // Fallback for devices where the plugin cannot show the dialog.
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('NotificationService requestPermission failed: $e');
      return false;
    }
  }

  /// Asks for the notification permission and, when it is not granted,
  /// explains how to enable it from the system settings.
  static Future<void> requestPermissionWithHelp(BuildContext context) async {
    final granted = await requestPermission();
    if (granted || !context.mounted) return;
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable Notifications'),
        content: const Text(
            'To get pop-up alerts when a new group message arrives, allow '
            'notifications for this app in the system settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    if (open == true) {
      await openAppSettings();
    }
  }

  /// Whether notifications are currently allowed for this app.
  static Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return true;
    await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      if (enabled == false) return false;
      return await Permission.notification.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Shows a notification for a new group chat message.
  static Future<void> showGroupMessage({
    required String groupName,
    required String senderName,
    required String message,
  }) async {
    await init();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'group_messages',
        'Group Messages',
        channelDescription: 'Notifications for new group chat messages',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.message,
        styleInformation: BigTextStyleInformation(''),
      ),
    );
    final id = DateTime.now().millisecondsSinceEpoch % 100000;
    try {
      await _plugin.show(
        id: id,
        title: '$senderName in $groupName',
        body: message,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('NotificationService show failed: $e');
    }
  }
}
