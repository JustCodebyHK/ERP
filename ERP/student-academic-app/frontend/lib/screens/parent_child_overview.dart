import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../models/parent.dart';
import '../widgets/app_theme.dart';

class ParentChildOverviewScreen extends StatefulWidget {
  final Child child;

  const ParentChildOverviewScreen({super.key, required this.child});

  @override
  State<ParentChildOverviewScreen> createState() =>
      _ParentChildOverviewScreenState();
}

class _ParentChildOverviewScreenState extends State<ParentChildOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _overviewFuture;
  late Future<Map<String, dynamic>> _attendanceFuture;
  late Future<Map<String, dynamic>> _marksFuture;
  late Future<Map<String, dynamic>> _assignmentsFuture;
  late Future<Map<String, dynamic>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _overviewFuture = apiChildOverview(widget.child.id);
      _attendanceFuture = apiChildAttendance(widget.child.id);
      _marksFuture = apiChildMarks(widget.child.id);
      _assignmentsFuture = apiChildAssignments(widget.child.id);
      _announcementsFuture = apiChildAnnouncements(widget.child.id);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.child.name} (${widget.child.relationship})'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Attendance'),
            Tab(text: 'Marks'),
            Tab(text: 'Assignments'),
            Tab(text: 'Announcements'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(future: _overviewFuture, child: widget.child),
          _AttendanceTab(future: _attendanceFuture),
          _MarksTab(future: _marksFuture),
          _AssignmentsTab(future: _assignmentsFuture),
          _AnnouncementsTab(future: _announcementsFuture),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final Child child;

  const _OverviewTab({required this.future, required this.child});

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
        final attendance = (data['attendance'] as List)
            .map((e) => AttendanceSummary.fromJson(e))
            .toList();
        final marks = (data['marks'] as List)
            .map((e) => Mark.fromJson(e))
            .toList();
        final assignments = (data['assignments'] as List)
            .map((e) => ParentAssignmentSummary.fromJson(e))
            .toList();

        // Find lowest attendance
        final lowAttendance = attendance.isNotEmpty
            ? attendance.reduce((a, b) => a.percentage < b.percentage ? a : b)
            : null;

        // Find lowest mark
        final lowMark = marks.isNotEmpty
            ? marks.reduce((a, b) => a.percentage < b.percentage ? a : b)
            : null;

        return RefreshIndicator(
          onRefresh: () async {},
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Child info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          child: Text(
                            child.name[0],
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                child.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              Text(
                                child.email,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Chip(
                                label: Text(child.relationship),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Alerts
                if (lowAttendance != null && lowAttendance.percentage < 75) ...[
                  _AlertCard(
                    icon: Icons.warning_amber,
                    color: context.cs.secondary,
                    title: 'Low Attendance Alert',
                    message:
                        '${child.name} has ${lowAttendance.percentage.toStringAsFixed(1)}% in ${lowAttendance.name}',
                  ),
                  const SizedBox(height: 12),
                ],
                if (lowMark != null && lowMark.percentage < 60) ...[
                  _AlertCard(
                    icon: Icons.grade,
                    color: context.cs.error,
                    title: 'Low Grade Alert',
                    message:
                        '${child.name} scored ${lowMark.percentage.toStringAsFixed(1)}% in ${lowMark.name} (${lowMark.title})',
                  ),
                  const SizedBox(height: 12),
                ],

                // Quick stats
                Text(
                  'Quick Stats',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Subjects',
                        value: attendance.length.toString(),
                        icon: Icons.menu_book,
                        color: context.cs.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Avg Attendance',
                        value: attendance.isEmpty
                            ? 'N/A'
                            : '${(attendance.map((a) => a.percentage).reduce((a, b) => a + b) / attendance.length).toStringAsFixed(1)}%',
                        icon: Icons.verified,
                        color: context.cs.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Avg Marks',
                        value: marks.isEmpty
                            ? 'N/A'
                            : '${(marks.map((m) => m.percentage).reduce((a, b) => a + b) / marks.length).toStringAsFixed(1)}%',
                        icon: Icons.grade,
                        color: context.cs.tertiary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Assignments',
                        value: assignments.length.toString(),
                        icon: Icons.assignment,
                        color: context.cs.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Attendance summary
                if (attendance.isNotEmpty) ...[
                  Text(
                    'Attendance by Subject',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ...attendance.map(
                    (a) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: a.percentage >= 75
                              ? context.cs.tertiary.withValues(alpha: 0.1)
                              : context.cs.secondary.withValues(alpha: 0.1),
                          child: Icon(
                            a.percentage >= 75
                                ? Icons.check_circle
                                : Icons.warning,
                            color: a.percentage >= 75
                                ? context.cs.tertiary
                                : context.cs.secondary,
                          ),
                        ),
                        title: Text('${a.code} - ${a.name}'),
                        subtitle: Text(
                          '${a.attended}/${a.totalLectures} lectures',
                        ),
                        trailing: Text(
                          '${a.percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: a.percentage >= 75
                                ? context.cs.tertiary
                                : context.cs.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _AlertCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(color: color.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
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

class _AttendanceTab extends StatelessWidget {
  final Future<Map<String, dynamic>> future;

  const _AttendanceTab({required this.future});

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
        final items = (data['attendance'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        if (items.isEmpty) {
          return const Center(child: Text('No attendance records'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final a = items[i];
            final present = a['present'] as bool? ?? false;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  present ? Icons.check_circle : Icons.cancel,
                  color: present ? context.cs.tertiary : context.cs.error,
                ),
                title: Text(a['subject_name'] as String? ?? 'Unknown'),
                subtitle: Text(
                  '${a['code']} • ${DateFormat('MMM d, yyyy').format(DateTime.parse(a['date'] as String))}',
                ),
                trailing: Icon(
                  present ? Icons.check_circle : Icons.cancel,
                  color: present ? context.cs.tertiary : context.cs.error,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MarksTab extends StatelessWidget {
  final Future<Map<String, dynamic>> future;

  const _MarksTab({required this.future});

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
        final items = (data['marks'] as List)
            .map((e) => Mark.fromJson(e))
            .toList();

        if (items.isEmpty) {
          return const Center(child: Text('No marks available'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final m = items[i];
            final passed = m.percentage >= 60;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: passed
                      ? context.cs.tertiary.withValues(alpha: 0.1)
                      : context.cs.error.withValues(alpha: 0.1),
                  child: Text(
                    '${m.percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: passed ? context.cs.tertiary : context.cs.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  m.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${m.code} - ${m.name}'),
                    Text('Type: ${m.type} • Score: ${m.score}/${m.maxScore}'),
                  ],
                ),
                trailing: Chip(
                  label: Text('${m.percentage.toStringAsFixed(1)}%'),
                  backgroundColor: passed
                      ? context.cs.tertiary.withValues(alpha: 0.1)
                      : context.cs.error.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: passed ? context.cs.tertiary : context.cs.error,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AssignmentsTab extends StatelessWidget {
  final Future<Map<String, dynamic>> future;

  const _AssignmentsTab({required this.future});

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
        final items = (data['assignments'] as List)
            .map((e) => ParentAssignmentSummary.fromJson(e))
            .toList();

        if (items.isEmpty) {
          return const Center(child: Text('No assignments'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final a = items[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: a.isGraded
                      ? context.cs.primary.withValues(alpha: 0.1)
                      : a.isSubmitted
                      ? context.cs.tertiary.withValues(alpha: 0.1)
                      : context.cs.secondary.withValues(alpha: 0.1),
                  child: Icon(
                    a.isGraded
                        ? Icons.grade
                        : a.isSubmitted
                        ? Icons.check_circle
                        : Icons.pending,
                    color: a.isGraded
                        ? context.cs.primary
                        : a.isSubmitted
                        ? context.cs.tertiary
                        : context.cs.secondary,
                  ),
                ),
                title: Text(
                  a.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${a.subjectCode} - ${a.subjectName}'),
                    Text(
                      'Due: ${DateFormat('MMM d, yyyy HH:mm').format(a.dueAt.toLocal())}',
                    ),
                    Text(
                      'Status: ${a.statusDisplay}',
                      style: TextStyle(
                        color: a.isOverdue || a.isLate
                            ? context.cs.error
                            : a.isSubmitted || a.isGraded
                            ? context.cs.tertiary
                            : context.cs.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                trailing: a.isGraded
                    ? Text(
                        'Score: ${a.score}/${a.maxScore}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      },
    );
  }
}

class _AnnouncementsTab extends StatelessWidget {
  final Future<Map<String, dynamic>> future;

  const _AnnouncementsTab({required this.future});

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
        final items = (data['announcements'] as List)
            .map((e) => ParentAnnouncement.fromJson(e))
            .toList();

        if (items.isEmpty) {
          return const Center(child: Text('No announcements'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final a = items[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
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
                                  if (a.batchName != null) ...[
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text(
                                        a.batchName!,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: context.cs.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      labelStyle: TextStyle(
                                        color: context.cs.primary,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(a.body),
                    const SizedBox(height: 8),
                    Text(
                      'Posted ${DateFormat('MMM d, yyyy \'at\' HH:mm').format(a.publishedAt.toLocal())}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: context.cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

