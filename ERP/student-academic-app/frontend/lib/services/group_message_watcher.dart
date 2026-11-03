import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api.dart';
import '../auth_store.dart';
import 'notification_service.dart';

/// Polls the logged-in user's groups and pops up a system notification
/// whenever a new chat message from someone else arrives.
///
/// Runs while the app is open (foreground). There is no push (FCM)
/// integration, so notifications are not delivered while the app is fully
/// closed.
class GroupMessageWatcher {
  GroupMessageWatcher._();
  static final GroupMessageWatcher instance = GroupMessageWatcher._();

  /// The open group chat screen registers itself here so we don't notify
  /// about messages the user is already reading.
  static String? activeGroupId;

  static const Duration _pollInterval = Duration(seconds: 20);

  Timer? _timer;
  bool _busy = false;

  /// groupId -> id of the newest message we have already seen.
  final Map<String, String> _lastSeenMessageId = {};

  bool get isRunning => _timer != null;

  /// Starts watching. The first pass only records the current newest
  /// messages, so old messages do not trigger notifications.
  void start() {
    if (_timer != null) return;
    _tick();
    _timer = Timer.periodic(_pollInterval, (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (_busy || AuthStore.user == null) return;
    _busy = true;
    try {
      final data = await apiGetGroups();
      final groups = (data['groups'] as List? ?? const [])
          .whereType<Map<String, dynamic>>();
      for (final g in groups) {
        final id = g['id']?.toString();
        if (id == null) continue;
        await _checkGroup(id, g['name']?.toString() ?? 'Group');
      }
    } catch (e) {
      // Offline or server hiccup - just try again on the next tick.
      debugPrint('GroupMessageWatcher poll failed: $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> _checkGroup(String groupId, String groupName) async {
    try {
      final data = await apiGetGroupMessages(groupId, limit: 5);
      final messages = (data['messages'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (messages.isEmpty) return;

      final newest = messages.last;
      final newestId = newest['id']?.toString() ?? '';
      if (newestId.isEmpty) return;

      final lastSeen = _lastSeenMessageId[groupId];
      if (lastSeen == null) {
        // First time we see this group during this app run - remember the
        // newest message but don't notify for older history.
        _lastSeenMessageId[groupId] = newestId;
        return;
      }
      if (lastSeen == newestId) return;

      // Collect messages newer than the last one we saw.
      final fresh = <Map<String, dynamic>>[];
      var foundAnchor = false;
      for (final m in messages.reversed) {
        final mid = m['id']?.toString() ?? '';
        if (mid == lastSeen) {
          foundAnchor = true;
          break;
        }
        fresh.add(m);
      }
      _lastSeenMessageId[groupId] = newestId;

      if (!foundAnchor) {
        // The anchor fell out of the fetched window - notify only the
        // latest message to avoid a burst of notifications.
        fresh
          ..clear()
          ..add(newest);
      }

      if (groupId == activeGroupId) return; // user is reading this chat

      final myId = AuthStore.user?.id;
      for (final m in fresh.reversed) {
        if (m['sender_id']?.toString() == myId) continue; // own message
        final content = m['content']?.toString() ?? '';
        if (content.isEmpty) continue;
        await NotificationService.showGroupMessage(
          groupName: groupName,
          senderName: m['sender_name']?.toString() ?? 'Someone',
          message: content.length > 200
              ? '${content.substring(0, 200)}...'
              : content,
        );
      }
    } catch (e) {
      debugPrint('GroupMessageWatcher check failed for $groupId: $e');
    }
  }
}
