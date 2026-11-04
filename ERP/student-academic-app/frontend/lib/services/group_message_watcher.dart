import 'dart:async';

class GroupMessageWatcher {
  static final GroupMessageWatcher _instance = GroupMessageWatcher._internal();
  factory GroupMessageWatcher() => _instance;
  GroupMessageWatcher._internal();

  Timer? _timer;
  Duration _interval = const Duration(seconds: 30);
  Function(String groupId)? onNewMessage;
  static String? activeGroupId;

  void setWatchInterval(Duration interval) {
    _interval = interval;
  }

  void startWatching(String groupId) {
    stopWatching();
    _timer = Timer.periodic(_interval, (_) async {
      // Simulate checking for new messages
      onNewMessage?.call(groupId);
    });
  }

  void stopWatching() {
    _timer?.cancel();
    _timer = null;
  }

  bool get isWatching => _timer != null && !_timer!.isCancelled;
  Duration get interval => _interval;
}
