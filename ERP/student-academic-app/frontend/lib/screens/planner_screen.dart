import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../models/planner.dart';
import '../widgets/app_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  late Future<Map<String, dynamic>> _todayFuture;
  late Future<Map<String, dynamic>> _weekFuture;
  late Future<Map<String, dynamic>> _digestFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final weekStart = DateFormat('yyyy-MM-dd').format(
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
    );

    setState(() {
      _todayFuture = apiGetPlannerTasks(today);
      _weekFuture = apiGetPlannerWeek(weekStart);
      _digestFuture = apiDailyDigest();
    });
  }

  Future<void> _refresh() async {
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
      setState(() => _todayFuture = apiGetPlannerTasks(dateStr));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Planner'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Week'),
            Tab(text: 'Digest'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pick Date',
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskDialog,
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TasksTab(
            future: _todayFuture,
            date: _selectedDate,
            onRefresh: _loadAll,
          ),
          _WeekTab(future: _weekFuture, onRefresh: _loadAll),
          _DigestTab(future: _digestFuture, onRefresh: _loadAll),
        ],
      ),
    );
  }

  Future<void> _showCreateTaskDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int priority = 1;
    TimeOfDay? reminderTime;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: 1,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Low')),
                    DropdownMenuItem(value: 2, child: Text('Medium')),
                    DropdownMenuItem(value: 3, child: Text('High')),
                  ],
                  onChanged: (v) => setState(() => priority = v ?? 1),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.now(),
                          );
                          if (t != null) setState(() => reminderTime = t);
                        },
                        child: Text(
                          reminderTime == null
                              ? 'Set Reminder'
                              : reminderTime!.format(ctx),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                try {
                  await apiCreatePlannerTask({
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'priority': priority,
                    'scheduled_for': DateFormat('yyyy-MM-dd')
                        .format(DateTime.now()),
                  });
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(
                    ctx,
                  ).showSnackBar(const SnackBar(content: Text('Task created')));
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx)
                      .showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksTab extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final DateTime date;
  final Future<void> Function() onRefresh;

  const _TasksTab({
    required this.future,
    required this.date,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMM d').format(date);

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
        final tasks = (data['tasks'] as List)
            .map((e) => PlannerTask.fromJson(e))
            .toList();

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: context.cs.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks for $dateStr',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add a task',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: context.cs.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, i) {
              final t = tasks[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: t.isCompleted
                    ? context.cs.tertiary.withValues(alpha: 0.05)
                    : t.isOverdue
                    ? context.cs.error.withValues(alpha: 0.05)
                    : null,
                child: ListTile(
                  leading: Checkbox(
                    value: t.isCompleted,
                    onChanged: (_) async {
                      try {
                        await apiCompletePlannerTask(t.id);
                      } catch (e) {}
                    },
                  ),
                  title: Text(
                    t.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      decoration: t.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: context.cs.onSurfaceVariant,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (t.description != null && t.description!.isNotEmpty)
                        Text(t.description!),
                      Row(
                        children: [
                          if (t.hasTimetableLink) ...[
                            const Icon(Icons.schedule, size: 14),
                            const SizedBox(width: 4),
                            Text('${t.startTime ?? ''} - ${t.endTime ?? ''}'),
                            const SizedBox(width: 8),
                          ],
                          Chip(
                            label: Text(
                              t.priorityLabel,
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: t.priorityColor.withValues(
                              alpha: 0.1,
                            ),
                            labelStyle: TextStyle(
                              color: t.priorityColor,
                              fontSize: 10,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      if (t.dueAt != null)
                        Text(
                          'Due: ${DateFormat('MMM d, HH:mm').format(t.dueAt!.toLocal())}',
                          style: TextStyle(
                            color: t.isOverdue ? context.cs.error : context.cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'complete') {
                        await apiCompletePlannerTask(t.id);
                      } else if (value == 'carry') {
                        await apiCarryForwardPlannerTask(t.id);
                      } else if (value == 'delete') {
                        await apiDeletePlannerTask(t.id);
                      }
                    },
                    itemBuilder: (_) => [
                      if (!t.isCompleted)
                        const PopupMenuItem(
                          value: 'complete',
                          child: Text('Mark Complete'),
                        ),
                      if (!t.isCompleted)
                        const PopupMenuItem(
                          value: 'carry',
                          child: Text('Carry to Tomorrow'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                  onTap: () {},
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _WeekTab extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final Future<void> Function() onRefresh;

  const _WeekTab({required this.future, required this.onRefresh});

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
        final tasks = (data['tasks'] as List)
            .map((e) => PlannerTask.fromJson(e))
            .toList();

        if (tasks.isEmpty) {
          return const Center(child: Text('No tasks this week'));
        }

        final Map<String, List<PlannerTask>> grouped = {};
        for (final t in tasks) {
          final dateStr = DateFormat('yyyy-MM-dd').format(t.scheduledFor);
          grouped.putIfAbsent(dateStr, () => []).add(t);
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((entry) {
              final dateStr = entry.key;
              final dayTasks = entry.value;
              final date = DateTime.parse(dateStr);
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: Text(DateFormat('d').format(date)),
                  ),
                  title: Text(
                    DateFormat('EEEE, MMM d').format(date),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${dayTasks.length} task${dayTasks.length > 1 ? 's' : ''}',
                  ),
                  children: dayTasks
                      .map(
                        (t) => ListTile(
                          dense: true,
                          leading: Checkbox(
                            value: t.isCompleted,
                            onChanged: (_) => apiCompletePlannerTask(t.id),
                          ),
                          title: Text(
                            t.title,
                            style: TextStyle(
                              decoration: t.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: t.hasTimetableLink
                              ? Text('${t.startTime} - ${t.endTime}')
                              : null,
                          trailing: Chip(
                            label: Text(
                              t.priorityLabel,
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: t.priorityColor.withValues(
                              alpha: 0.1,
                            ),
                            labelStyle: TextStyle(color: t.priorityColor),
                          ),
                          onTap: () => apiCompletePlannerTask(t.id),
                        ),
                      )
                      .toList(),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _DigestTab extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final Future<void> Function() onRefresh;

  const _DigestTab({required this.future, required this.onRefresh});

  Widget _buildStatCards(BuildContext context, DailyDigest digest) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Total Tasks',
            value: digest.stats.totalTasks.toString(),
            icon: Icons.task_alt,
            color: context.cs.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Completed',
            value: digest.stats.completedTasks.toString(),
            icon: Icons.check_circle,
            color: context.cs.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards2(BuildContext context, DailyDigest digest) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Pending',
            value: digest.stats.pendingTasks.toString(),
            icon: Icons.pending,
            color: context.cs.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Overdue Assign.',
            value: digest.stats.overdueAssignments.toString(),
            icon: Icons.warning,
            color: context.cs.error,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildClasses(BuildContext context, DailyDigest digest) {
    if (digest.classes.isEmpty) return [];
    final List<Widget> widgets = [];
    widgets.add(
      Text('Today\'s Classes', style: Theme.of(context).textTheme.titleLarge),
    );
    widgets.add(const SizedBox(height: 8));
    for (final c in digest.classes) {
      widgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.class_),
            title: Text('${c.subjectCode} - ${c.subjectName}'),
            subtitle: Text('${c.timeRange} • Room: ${c.room ?? 'TBA'}'),
          ),
        ),
      );
    }
    widgets.add(const SizedBox(height: 16));
    return widgets;
  }

  List<Widget> _buildTasks(BuildContext context, DailyDigest digest) {
    if (digest.tasks.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No tasks for today'),
          ),
        ),
      ];
    }
    final List<Widget> widgets = [];
    for (final t in digest.tasks) {
      widgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Checkbox(
              value: t.isCompleted,
              onChanged: (_) async {
                try {
                  await apiCompletePlannerTask(t.id);
                } catch (e) {}
              },
            ),
            title: Text(
              t.title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                color: context.cs.onSurfaceVariant,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (t.description != null && t.description!.isNotEmpty)
                  Text(t.description!),
                Row(
                  children: [
                    if (t.hasTimetableLink) ...[
                      const Icon(Icons.schedule, size: 14),
                      const SizedBox(width: 4),
                      Text('${t.startTime ?? ''} - ${t.endTime ?? ''}'),
                      const SizedBox(width: 8),
                    ],
                    Chip(
                      label: Text(
                        t.priorityLabel,
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: t.priorityColor.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: t.priorityColor,
                        fontSize: 10,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (t.dueAt != null)
                  Text(
                    'Due: ${DateFormat('MMM d, HH:mm').format(t.dueAt!.toLocal())}',
                    style: TextStyle(
                      color: t.isOverdue ? context.cs.error : context.cs.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'complete') {
                  await apiCompletePlannerTask(t.id);
                } else if (value == 'carry') {
                  await apiCarryForwardPlannerTask(t.id);
                } else if (value == 'delete') {
                  await apiDeletePlannerTask(t.id);
                }
              },
              itemBuilder: (_) => [
                if (!t.isCompleted)
                  const PopupMenuItem(
                    value: 'complete',
                    child: Text('Mark Complete'),
                  ),
                if (!t.isCompleted)
                  const PopupMenuItem(
                    value: 'carry',
                    child: Text('Carry to Tomorrow'),
                  ),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
            onTap: () {},
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildOverdueAssignments(
    BuildContext context,
    DailyDigest digest,
  ) {
    if (digest.overdueAssignments.isEmpty) return [];
    final List<Widget> widgets = [];
    widgets.add(
      Text(
        'Overdue Assignments',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
    widgets.add(const SizedBox(height: 8));
    for (final a in digest.overdueAssignments) {
      widgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: context.cs.error.withValues(alpha: 0.05),
          child: ListTile(
            leading: Icon(Icons.warning, color: context.cs.error),
            title: Text(
              a.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${a.subjectCode} - Due: ${DateFormat('MMM d').format(a.dueAt)}',
            ),
            trailing: Text(
              'Overdue',
              style: TextStyle(color: context.cs.error, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }
    widgets.add(const SizedBox(height: 16));
    return widgets;
  }

  List<Widget> _buildUpcomingAssignments(
    BuildContext context,
    DailyDigest digest,
  ) {
    if (digest.upcomingAssignments.isEmpty) return [];
    final List<Widget> widgets = [];
    widgets.add(
      Text(
        'Upcoming Assignments',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
    widgets.add(const SizedBox(height: 8));
    for (final a in digest.upcomingAssignments) {
      widgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.assignment),
            title: Text(a.title),
            subtitle: Text(
              '${a.subjectCode} - Due: ${DateFormat('MMM d').format(a.dueAt)}',
            ),
            trailing: Chip(
              label: Text(
                a.statusDisplay,
                style: const TextStyle(fontSize: 11),
              ),
              backgroundColor: a.status == 'graded'
                  ? context.cs.primary.withValues(alpha: 0.1)
                  : context.cs.secondary.withValues(alpha: 0.1),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

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
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('No data available'));
        }
        final digest = DailyDigest.fromJson(data);

        final List<Widget> children = <Widget>[];

        // Stat cards
        children.add(_buildStatCards(context, digest));
        children.add(const SizedBox(height: 12));
        children.add(_buildStatCards2(context, digest));
        children.add(const SizedBox(height: 24));

        // Classes
        children.addAll(_buildClasses(context, digest));

        // Tasks
        children.add(
          Text(
            'Tasks for Today',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        );
        children.add(const SizedBox(height: 8));
        children.addAll(_buildTasks(context, digest));
        children.add(const SizedBox(height: 16));

        // Overdue assignments
        children.addAll(_buildOverdueAssignments(context, digest));

        // Upcoming assignments
        children.addAll(_buildUpcomingAssignments(context, digest));

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

