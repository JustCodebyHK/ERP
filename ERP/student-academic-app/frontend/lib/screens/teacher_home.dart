import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';
import '../auth_store.dart';
import '../services/group_message_watcher.dart';
import '../services/notification_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';
import 'teacher_notes.dart';
import 'teacher_assignments.dart';
import 'teacher_timetable.dart';
import 'teacher_announcements.dart';
import 'teacher_submission_kit.dart';
import 'teacher_groups.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  late Future<List<dynamic>> _futureClasses;
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _futureClasses = _load();
    _statsFuture = _loadStats();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    // Ask for the notification permission once (Android 13+).
    try {
      final granted = await NotificationService.hasPermission();
      if (!granted) {
        final prefs = await SharedPreferences.getInstance();
        final alreadyAsked = prefs.getBool('notif_permission_asked') ?? false;
        if (!alreadyAsked && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            await NotificationService.requestPermissionWithHelp(context);
            await prefs.setBool('notif_permission_asked', true);
          });
        }
      }
    } catch (_) {}
    // Watch group chats so new messages pop up as notifications.
    GroupMessageWatcher.instance.start();
  }

  @override
  void dispose() {
    GroupMessageWatcher.instance.stop();
    super.dispose();
  }

  Future<List<dynamic>> _load() async {
    final data = await apiGet('/api/academic/my-classes');
    return data['classes'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> _loadStats() async {
    try {
      final classesData = await apiGet('/api/academic/my-classes');
      final classes = classesData['classes'] as List<dynamic>;
      int totalStudents = 0;
      int totalSubjects = 0;
      for (final c in classes) {
        final batchId = c['batch_id'] as String;
        try {
          final batchData = await apiGet('/api/academic/batches/$batchId');
          final students = batchData['students'] as List<dynamic>? ?? [];
          totalStudents += students.length;
        } catch (_) {}
        totalSubjects++;
      }
      return {
        'classes': classes.length,
        'students': totalStudents,
        'subjects': totalSubjects,
      };
    } catch (_) {
      return {'classes': 0, 'students': 0, 'subjects': 0};
    }
  }

  Future<void> _logout() async {
    await AuthStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _refresh() {
    setState(() {
      _futureClasses = _load();
      _statsFuture = _loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        actions: [
          IconButton(
            tooltip: 'Study Groups',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TeacherGroupsScreen()),
            ),
            icon: const Icon(Icons.groups),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateClassDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Class'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureClasses,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(context);
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: context.cs.error),
                  const SizedBox(height: 16),
                  Text('Failed to load classes: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final classes = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _statsFuture,
              builder: (context, statsSnapshot) {
                final stats = statsSnapshot.data ?? {'classes': classes.length, 'students': 0, 'subjects': 0};
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(
                              title: 'Overview',
                              subtitle: 'Your teaching dashboard',
                              icon: Icons.dashboard_outlined,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: StatCard(
                                    label: 'Classes',
                                    value: stats['classes']?.toString() ?? '0',
                                    icon: Icons.class_,
                                    color: context.cs.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: StatCard(
                                    label: 'Students',
                                    value: stats['students']?.toString() ?? '0',
                                    icon: Icons.people,
                                    color: context.cs.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: StatCard(
                                    label: 'Subjects',
                                    value: stats['subjects']?.toString() ?? '0',
                                    icon: Icons.menu_book,
                                    color: context.cs.tertiary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: StatCard(
                                    label: 'This Week',
                                    value: '—',
                                    icon: Icons.schedule,
                                    color: context.cs.surfaceContainerHighest,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (classes.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.class_outlined,
                          title: 'No Classes Yet',
                          subtitle: 'Tap the + button to create your first class and start managing your students.',
                          action: FilledButton.icon(
                            onPressed: () => _showCreateClassDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Class'),
                          ),
                          iconColor: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        sliver: SliverList.separated(
                          itemCount: classes.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final c = classes[index] as Map<String, dynamic>;
                            return AnimatedListItem(
                              index: index,
                              child: ClassCard(
                                batchName: c['batch_name'] as String? ?? '',
                                subjectCode: c['subject_code'] as String? ?? '',
                                subjectName: c['subject_name'] as String? ?? '',
                                subjectId: c['subject_id'] as String? ?? '',
                                batchId: c['batch_id'] as String? ?? '',
                                color: _getClassColor(context, index),
                                onTap: () => _showClassOptions(context, c),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingShimmer(height: 28, borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: LoadingShimmer(height: 100, borderRadius: BorderRadius.circular(16))),
                    const SizedBox(width: 12),
                    Expanded(child: LoadingShimmer(height: 100, borderRadius: BorderRadius.circular(16))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: LoadingShimmer(height: 100, borderRadius: BorderRadius.circular(16))),
                    const SizedBox(width: 12),
                    Expanded(child: LoadingShimmer(height: 100, borderRadius: BorderRadius.circular(16))),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList.separated(
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => LoadingShimmer(height: 88, borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Color _getClassColor(BuildContext context, int index) {
    final cs = Theme.of(context).colorScheme;
    final colors = [
      cs.primary,
      cs.secondary,
      cs.tertiary,
      cs.error,
      cs.primary.withValues(alpha: 0.8),
      cs.secondary.withValues(alpha: 0.8),
      cs.tertiary.withValues(alpha: 0.8),
      cs.error.withValues(alpha: 0.8),
    ];
    return colors[index % colors.length];
  }

  void _showClassOptions(BuildContext context, Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: context.cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['batch_name'] as String? ?? '',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${c['subject_code']} - ${c['subject_name']}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildActionTile(
                      context,
                      Icons.description_outlined,
                      'Notes',
                      'Manage subject notes',
                      context.cs.primary,
                      () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TeacherNotesScreen(
                            subjectId: c['subject_id'] as String,
                            subjectCode: c['subject_code'] as String,
                            subjectName: c['subject_name'] as String,
                          ),
                        ));
                      },
                    ),
                    _buildActionTile(
                      context,
                      Icons.assignment_outlined,
                      'Assignments',
                      'Create and grade assignments',
                      context.cs.secondary,
                      () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TeacherAssignmentsScreen(
                            batchId: c['batch_id'] as String,
                            batchName: c['batch_name'] as String,
                            subjectId: c['subject_id'] as String,
                            subjectCode: c['subject_code'] as String,
                            subjectName: c['subject_name'] as String,
                          ),
                        ));
                      },
                    ),
                    _buildActionTile(
                      context,
                      Icons.schedule_outlined,
                      'Timetable',
                      'Manage class schedule',
                      context.cs.tertiary,
                      () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TeacherTimetableScreen(
                            batchId: c['batch_id'] as String,
                            batchName: c['batch_name'] as String,
                            subjectId: c['subject_id'] as String,
                            subjectCode: c['subject_code'] as String,
                            subjectName: c['subject_name'] as String,
                          ),
                        ));
                      },
                    ),
                    _buildActionTile(
                      context,
                      Icons.campaign_outlined,
                      'Announcements',
                      'Post class announcements',
                      context.cs.tertiary,
                      () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TeacherAnnouncementsScreen(
                            batchId: c['batch_id'] as String,
                            batchName: c['batch_name'] as String,
                          ),
                        ));
                      },
                    ),
                    _buildActionTile(
                      context,
                      Icons.insert_drive_file_outlined,
                      'Submission Kit',
                      'Manage submission templates',
                      context.cs.error,
                      () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TeacherSubmissionKitScreen()),
                        );
                      },
                    ),
                    _buildActionTile(
                      context,
                      Icons.groups_outlined,
                      'Study Groups',
                      'Manage study groups for this class',
                      context.cs.tertiary,
                      () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TeacherGroupsScreen()),
                        );
                      },
                    ),
                    _buildActionTile(
                      context,
                      Icons.group_add_outlined,
                      'Create Study Group',
                      'Create a new group for this class',
                      context.cs.secondary,
                      () {
                        Navigator.pop(context);
                        _showCreateGroupDialog(context, c);
                      },
                    ),
                    const Divider(),
                    _buildActionTile(
                      context,
                      Icons.delete_outline,
                      'Delete Class',
                      'Permanently delete this class',
                      context.cs.error,
                      () async {
                        Navigator.pop(context);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Class'),
                            content: Text('Are you sure you want to delete "${c['batch_name']}"? This action cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(backgroundColor: context.cs.error),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await apiDelete('/api/academic/batches/${c['batch_id']}');
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Class deleted successfully')),
                            );
                            _refresh();
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(color: context.cs.onSurfaceVariant)),
      trailing: Icon(Icons.chevron_right, color: context.cs.onSurfaceVariant),
      onTap: onTap,
    );
  }

  void _showCreateGroupDialog(BuildContext context, Map<String, dynamic> c) {
    final nameCtrl = TextEditingController(text: '${c['subject_name']} Study Group');
    final descCtrl = TextEditingController();
    String type = 'group';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create Study Group'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Group Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: 'group',
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'group', child: Text('Group (Chat)')),
                    DropdownMenuItem(value: 'channel', child: Text('Channel (Broadcast)')),
                  ],
                  onChanged: (v) => setState(() => type = v ?? 'group'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                try {
                  await apiCreateGroup({
                    'name': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'type': type,
                  });
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Group created successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateClassDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final List<Map<String, String>> subjects = [];
    final List<Map<String, TextEditingController>> subjectControllers = [];

    void addSubject() {
      final codeCtrl = TextEditingController();
      final nameCtrl = TextEditingController();
      subjects.add({'code': '', 'name': ''});
      subjectControllers.add({'code': codeCtrl, 'name': nameCtrl});
    }

    addSubject();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create New Class'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Class Name *', hintText: 'e.g., BSc IT - Sem 3 (2026)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Text('Add Subjects', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Column(
                  children: [
                    ...subjects.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controllers = subjectControllers[index];
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controllers['code'],
                                  decoration: const InputDecoration(labelText: 'Subject Code *', hintText: 'e.g., IT301'),
                                  onChanged: (v) => setState(() => subjects[index]['code'] = v.toUpperCase()),
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: controllers['name'],
                                  decoration: const InputDecoration(labelText: 'Subject Name *', hintText: 'e.g., Computer Networks'),
                                  onChanged: (v) => setState(() => subjects[index]['name'] = v),
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.delete, color: context.cs.error),
                                onPressed: () => setState(() {
                                  subjectControllers[index]['code']?.dispose();
                                  subjectControllers[index]['name']?.dispose();
                                  subjects.removeAt(index);
                                  subjectControllers.removeAt(index);
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => setState(() {
                        final codeCtrl = TextEditingController();
                        final nameCtrl = TextEditingController();
                        subjects.add({'code': '', 'name': ''});
                        subjectControllers.add({'code': codeCtrl, 'name': nameCtrl});
                      }),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Subject'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                if (subjects.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please add at least one subject')),
                  );
                  return;
                }
                if (subjects.any((s) => (s['code'] ?? '').trim().isEmpty || (s['name'] ?? '').trim().isEmpty)) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please fill in all subject codes and names')),
                  );
                  return;
                }
                try {
                  final subjectsPayload = subjects.map((s) => {
                    'code': (s['code'] ?? '').trim().toUpperCase(),
                    'name': (s['name'] ?? '').trim(),
                  }).toList();

                  await apiCreateBatch({
                    'name': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'subjects': subjectsPayload,
                  });
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Class created successfully')),
                  );
                  _refresh();
                } catch (e) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              },
              child: const Text('Create Class'),
            ),
          ],
        ),
      ),
    );
  }
}

class ClassCard extends StatelessWidget {
  final String batchName;
  final String subjectCode;
  final String subjectName;
  final String subjectId;
  final String batchId;
  final Color color;
  final VoidCallback onTap;

  const ClassCard({
    super.key,
    required this.batchName,
    required this.subjectCode,
    required this.subjectName,
    required this.subjectId,
    required this.batchId,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.8), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    subjectCode.isNotEmpty ? subjectCode[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: context.cs.onPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batchName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$subjectCode - $subjectName',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.class_outlined, size: 14,
                            color: context.cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          'Class',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.cs.onSurfaceVariant),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.menu_book_outlined, size: 14,
                            color: context.cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          'Subject',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}