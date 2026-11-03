import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../models/announcement.dart';
import '../widgets/app_theme.dart';

class StudentAnnouncementsScreen extends StatefulWidget {
  const StudentAnnouncementsScreen({super.key});

  @override
  State<StudentAnnouncementsScreen> createState() =>
      _StudentAnnouncementsScreenState();
}

class _StudentAnnouncementsScreenState extends State<StudentAnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _allFuture;
  late Future<Map<String, dynamic>> _globalFuture;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _allFuture = apiListAnnouncementsCached();
      _globalFuture = apiListAnnouncementsCached(batchId: 'global');
    });
    _refreshUnread();
  }

  Future<void> _refreshUnread() async {
    try {
      final data = await apiUnreadAnnouncementsCount();
      if (mounted) setState(() => _unreadCount = data['count'] as int? ?? 0);
    } catch (_) {}
  }

  Future<void> _markRead(Announcement a) async {
    try {
      await apiMarkAnnouncementRead(a.id);
      _loadAll();
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All ${_unreadCount > 0 ? '($_unreadCount)' : ''}'),
            const Tab(text: 'Global'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AnnouncementsList(
            future: _allFuture,
            emptyMessage: 'No announcements yet',
            onMarkRead: _markRead,
            onRefresh: _loadAll,
          ),
          _AnnouncementsList(
            future: _globalFuture,
            emptyMessage: 'No global announcements',
            onMarkRead: _markRead,
            filterGlobal: true,
            onRefresh: _loadAll,
          ),
        ],
      ),
    );
  }
}

class _AnnouncementsList extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final String emptyMessage;
  final Future<void> Function(Announcement) onMarkRead;
  final bool filterGlobal;
  final Future<void> Function()? onRefresh;

  const _AnnouncementsList({
    required this.future,
    required this.emptyMessage,
    required this.onMarkRead,
    this.filterGlobal = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load: ${snapshot.error}'));
        }
        final data = snapshot.data!;
        final announcements = (data['announcements'] as List)
            .map((e) => Announcement.fromJson(e))
            .where((a) => !filterGlobal || a.isGlobal)
            .toList();

        if (announcements.isEmpty) {
          return Center(child: Text(emptyMessage));
        }

        return RefreshIndicator(
          onRefresh: onRefresh ?? () async => future,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            itemBuilder: (context, i) {
              final a = announcements[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => onMarkRead(a),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: a.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(a.icon, color: a.color, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          a.typeLabel,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        backgroundColor: a.color.withValues(
                                          alpha: 0.1,
                                        ),
                                        labelStyle: TextStyle(color: a.color),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const SizedBox(width: 8),
                                      if (a.isGlobal)
                                        Chip(
                                          label: const Text(
                                            'Global',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                          backgroundColor: context.cs.tertiary.withValues(alpha: 0.1),
                                          labelStyle: const TextStyle(
                                            color: AppTheme.tertiary,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        )
                                      else if (a.batchName != null)
                                        Chip(
                                          label: Text(
                                            a.batchName!,
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                          backgroundColor: context.cs.primary.withValues(alpha: 0.1),
                                          labelStyle: const TextStyle(
                                            color: AppTheme.primary,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Alarming banner for high-severity announcements.
                        if (a.type == 'alert' || a.type == 'urgent')
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: context.cs.error.withValues(alpha: 0.12),
                              border: Border.all(
                                  color: context.cs.error.withValues(alpha: 0.5),
                                  width: 1.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber,
                                    color: AppTheme.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ALERT — ${a.typeLabel}',
                                    style: const TextStyle(
                                      color: AppTheme.error,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          a.body,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                (a.type == 'alert' || a.type == 'urgent')
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: a.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(a.icon,
                                      size: 12, color: a.color),
                                  const SizedBox(width: 6),
                                  Text(
                                    a.typeLabel.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: a.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('dd MMM yyyy, HH:mm')
                                  .format(a.publishedAt.toLocal()),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: context.cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

