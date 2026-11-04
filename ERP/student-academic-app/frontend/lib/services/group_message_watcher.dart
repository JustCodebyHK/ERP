import 'dart:async';

class GroupMessageWatcher {
  static final GroupMessageWatcher _instance = GroupMessageWatcher._internal();
  static GroupMessageWatcher get instance => _instance;
  factory GroupMessageWatcher() => _instance;
  GroupMessageWatcher._internal();

  Timer? _timer;
  Duration _interval = const Duration(seconds: 30);
  Function(String groupId)? onNewMessage;
  static String? activeGroupId;

  void start() {
    // No-op start for compatibility
  }

  void stop() {
    stopWatching();
  }

  void setWatchInterval(Duration interval) {
    _interval = interval;
  }

  void startWatching(String groupId) {
    stopWatching();
    _timer = Timer.periodic(_interval, (_) async {
      onNewMessage?.call(groupId);
    });
  }

  void stopWatching() {
    _timer?.cancel();
    _timer = null;
  }

  bool get isWatching => _timer != null && _timer!.isActive;
  Duration get interval => _interval;
}
