import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../auth_store.dart';
import '../models/group.dart';
import '../services/group_message_watcher.dart';
import '../services/notification_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupType;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupType,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<GroupMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _beforeTimestamp;
  String? _error;
  Timer? _pollTimer;
  String? _currentUserId;
  String? _currentUserRole;

  /// Built widgets (date separators + message bubbles) for the list view.
  List<Widget> _messageWidgets = [];

  @override
  void initState() {
    super.initState();
    GroupMessageWatcher.activeGroupId = widget.groupId;
    _initChat();
  }

  Future<void> _initChat() async {
    final user = AuthStore.user;
    _currentUserId = user?.id;
    _currentUserRole = user?.role;
    await _loadMessages();
    _startPolling();
  }

  Future<void> _loadMessages({bool prepend = false}) async {
    try {
      final data = await apiGetGroupMessages(
        widget.groupId,
        before: prepend ? _beforeTimestamp : null,
        limit: 50,
      );
      final loaded = (data['messages'] as List)
          .map((e) => GroupMessage.fromJson(e as Map<String, dynamic>))
          .toList();

      if (loaded.isNotEmpty) {
        // Backend returns DESC (newest first). The oldest message in the page is loaded.last.
        _beforeTimestamp = loaded.last.createdAt.toIso8601String();
      }

      // Convert to chronological (oldest at top, newest at bottom)
      final chronological = loaded.reversed.toList();

      if (mounted) {
        setState(() {
          if (prepend) {
            _messages.insertAll(0, chronological);
          } else {
            _messages.clear();
            _messages.addAll(chronological);
          }
          _loading = false;
          _rebuildMessageWidgets();
        });

        if (!prepend) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_loading) {
        _pollNewMessages();
      }
    });
  }

  Future<void> _pollNewMessages() async {
    try {
      if (_messages.isEmpty) return;
      // Fetch latest messages from server (no 'before' filter - get newest)
      final data = await apiGetGroupMessages(
        widget.groupId,
        limit: 50,
      );
      final loaded = (data['messages'] as List)
          .map((e) => GroupMessage.fromJson(e as Map<String, dynamic>))
          .toList();

      if (loaded.isEmpty) return;

      // Backend returns DESC (newest first); reverse to chronological
      final newMessages = loaded.reversed.toList();

      // Filter out any we already have (safety dedup)
      final existingIds = _messages.map((m) => m.id).toSet();
      final trulyNew = newMessages.where((m) => !existingIds.contains(m.id)).toList();

      if (trulyNew.isNotEmpty && mounted) {
        setState(() {
          _messages.addAll(trulyNew);
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          _rebuildMessageWidgets();
        });
        _scrollToBottom();

        // Notify for new messages from others while the chat is open too
        final myId = _currentUserId;
        for (final m in trulyNew) {
          if (m.senderId != myId) {
            NotificationService.showGroupMessage(
              groupName: widget.groupName,
              senderName: m.senderName ?? 'Someone',
              message: m.content,
            );
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _messageCtrl.clear();

    // Optimistic message — appears instantly, synced with server below.
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = GroupMessage(
      id: tempId,
      groupId: widget.groupId,
      senderId: _currentUserId ?? '',
      content: text,
      type: 'text',
      createdAt: DateTime.now(),
      senderName: AuthStore.user?.name ?? 'You',
      senderRole: AuthStore.user?.role ?? 'student',
      readCount: 0,
    );

    setState(() {
      _messages.add(optimistic);
      _rebuildMessageWidgets();
    });
    _scrollToBottom();

    try {
      final res = await apiSendGroupMessage(widget.groupId, {
        'content': text,
        'type': 'text',
      });

      // Replace optimistic message with server data if available.
      if (mounted && res['message'] != null) {
        final serverMsg = GroupMessage.fromJson(
          res['message'] as Map<String, dynamic>,
        );
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == tempId);
          if (idx != -1) {
            _messages[idx] = serverMsg;
          } else {
            _messages.add(serverMsg);
          }
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          _rebuildMessageWidgets();
        });
      }
    } catch (e) {
      // Remove optimistic message if send failed.
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == tempId);
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onRefresh() async {
    await _loadMessages(prepend: true);
  }

  @override
  void dispose() {
    if (GroupMessageWatcher.activeGroupId == widget.groupId) {
      GroupMessageWatcher.activeGroupId = null;
    }
    _pollTimer?.cancel();
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Date separator shown between messages on different days.
  Widget _dateSeparator(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    String label;
    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      label = 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      label = 'Yesterday';
    } else {
      label = DateFormat('dd MMM yyyy').format(date);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: context.cs.outlineVariant, height: 1)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: context.cs.outlineVariant, height: 1)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.groupName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.groupType == 'channel' ? 'Channel' : 'Group',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.cs.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => _loadMessages(),
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load messages',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _error = null;
                                _loading = true;
                                _messages.clear();
                              });
                              _loadMessages();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _loading && _messages.isEmpty
                    ? _buildLoadingState()
                    : _messages.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: EmptyState(
                                icon: Icons.chat_bubble_outline,
                                title: 'No messages yet',
                                subtitle: 'Start the conversation!',
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _onRefresh,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messageWidgets.length,
                              itemBuilder: (context, index) =>
                                  _messageWidgets[index],
                            ),
                          ),
          ),
          if (widget.groupType == 'group' || _currentUserRole == 'teacher')
            _buildInputBar(),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Rebuild the flat widget list (separators + bubbles) from _messages.
  void _rebuildMessageWidgets() {
    final widgets = <Widget>[];
    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final isOwn = msg.senderId == _currentUserId;

      // Add a date separator when this is the first message or the day changed.
      if (i == 0 || !_sameDay(_messages[i - 1].createdAt, msg.createdAt)) {
        widgets.add(_dateSeparator(msg.createdAt));
      }

      widgets.add(
        _MessageBubble(
          message: msg,
          isOwn: isOwn,
          showSenderName: !isOwn && widget.groupType == 'group',
        ),
      );
    }
    _messageWidgets = widgets;
  }

  Widget _buildLoadingState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: List.generate(
        10,
        (i) =>
            LoadingShimmer(height: 70, borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: context.cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              decoration: InputDecoration(
                hintText:
                    widget.groupType == 'channel' &&
                        _currentUserRole != 'teacher'
                    ? 'Only admins can post in channels'
                    : 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              enabled:
                  widget.groupType == 'group' || _currentUserRole == 'teacher',
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _sending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.cs.onPrimary,
                      ),
                    )
                  : Icon(Icons.send, color: context.cs.onPrimary),
              onPressed:
                  (widget.groupType == 'group' ||
                          _currentUserRole == 'teacher') &&
                      !_sending
                  ? _sendMessage
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final GroupMessage message;
  final bool isOwn;
  final bool showSenderName;

  const _MessageBubble({
    required this.message,
    required this.isOwn,
    this.showSenderName = false,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.createdAt.toLocal());
    final senderName = message.senderName ?? 'Unknown';
    final senderRole = message.senderRole ?? 'student';
    final isAlert =
        message.type == 'alert' ||
        message.type == 'notification' ||
        message.type == 'system';
    final isFile = message.type == 'file' || message.type == 'image';

    // Bubble color: own = primary, others = surface, alerts = error tint
    final bubbleColor = isOwn
        ? Theme.of(context).colorScheme.primary
        : (isAlert
            ? context.cs.error.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surfaceContainerHighest);
    final textColor = isOwn
        ? context.cs.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name + role badge (for others)
          if (!isOwn && showSenderName)
            Padding(
              padding: const EdgeInsets.only(left: 52, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _getRoleColor(context, senderRole),
                    ),
                  ),
                  if (senderRole == 'teacher') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: context.cs.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'TEACHER',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: context.cs.primary,
                        ),
                      ),
                    ),
                  ],
                  if (isAlert) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.notifications,
                      size: 12,
                      color: context.cs.error,
                    ),
                  ],
                ],
              ),
            ),
          Row(
            mainAxisAlignment:
                isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isOwn) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      _getRoleColor(context, senderRole).withValues(alpha: 0.18),
                  child: Text(
                    senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(context, senderRole),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment:
                      isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        border: isAlert && !isOwn
                            ? Border.all(
                                color: context.cs.error.withValues(alpha: 0.4),
                                width: 1,
                              )
                            : null,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft:
                              isOwn ? const Radius.circular(16) : Radius.zero,
                          bottomRight:
                              isOwn ? Radius.zero : const Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isOwn
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.content,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: isAlert && !isOwn
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          if (isFile) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  message.type == 'image'
                                      ? Icons.image
                                      : Icons.insert_drive_file,
                                  size: 16,
                                  color: isOwn
                                      ? context.cs.onPrimary.withValues(alpha: 0.7)
                                      : context.cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  message.type == 'image' ? 'Image' : 'File',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isOwn
                                        ? context.cs.onPrimary.withValues(alpha: 0.7)
                                        : context.cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 10,
                              color: context.cs.onSurfaceVariant,
                            ),
                          ),
                          if (isOwn) ...[
                            const SizedBox(width: 6),
                            Icon(
                              message.readCount > 0
                                  ? Icons.done_all
                                  : Icons.done,
                              size: 14,
                              color: message.readCount > 1
                                  ? context.cs.primary
                                  : context.cs.onSurfaceVariant,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwn) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.18),
                  child: const Icon(Icons.person, size: 16),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(BuildContext context, String role) {
    switch (role) {
      case 'teacher':
        return context.cs.primary;
      case 'owner':
        return context.cs.secondary;
      case 'admin':
        return context.cs.tertiary;
      default:
        return context.cs.onSurfaceVariant;
    }
  }
}
