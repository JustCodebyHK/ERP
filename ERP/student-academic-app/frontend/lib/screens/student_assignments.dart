import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../models/assignment.dart';
import '../widgets/app_theme.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  State<StudentAssignmentsScreen> createState() => _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _future = apiMyAssignmentsCached();
  }

  Future<void> _refresh() async {
    setState(() => _future = apiMyAssignmentsCached());
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
        title: const Text('My Assignments'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Due Today'),
            Tab(text: 'Overdue'),
            Tab(text: 'Completed'),
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load assignments: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          final upcoming = (data['upcoming'] as List)
              .map((e) => Assignment.fromJson(e))
              .toList();
          final dueToday = (data['dueToday'] as List)
              .map((e) => Assignment.fromJson(e))
              .toList();
          final overdue = (data['overdue'] as List)
              .map((e) => Assignment.fromJson(e))
              .toList();
          final completed = (data['completed'] as List)
              .map((e) => Assignment.fromJson(e))
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _AssignmentList(assignments: upcoming, emptyMessage: 'No upcoming assignments'),
              _AssignmentList(assignments: dueToday, emptyMessage: 'Nothing due today'),
              _OverdueTab(assignments: overdue),
              _AssignmentList(assignments: completed, emptyMessage: 'No completed assignments'),
            ],
          );
        },
      ),
    );
  }
}

class _AssignmentList extends StatelessWidget {
  final List<Assignment> assignments;
  final String emptyMessage;

  const _AssignmentList({
    required this.assignments,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: assignments.length,
        itemBuilder: (context, i) {
          final a = assignments[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: _statusIcon(context, a),
              title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (a.subjectCode != null)
                    Text('${a.subjectCode} - ${a.subjectName ?? ''}'),
                  Text('Due: ${DateFormat('MMM d, yyyy HH:mm').format(a.dueAt.toLocal())}'),
                  Text('Status: ${a.statusDisplay}',
                      style: TextStyle(
                        color: a.isOverdue || a.isLate
                            ? context.cs.error
                            : a.isSubmitted || a.isGraded
                                ? context.cs.tertiary
                                : context.cs.secondary,
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ),
              trailing: a.isPending
                  ? FilledButton.tonal(
                      onPressed: () => _navigateToDetail(context, a),
                      child: const Text('Submit'),
                    )
                  : a.isGraded
                      ? Text('Score: ${a.score}/${a.maxScore}',
                          style: const TextStyle(fontWeight: FontWeight.bold))
                      : Icon(Icons.check_circle, color: context.cs.tertiary),
              onTap: () => _navigateToDetail(context, a),
            ),
          );
        },
      ),
    );
  }

  Widget _statusIcon(BuildContext context, Assignment a) {
    final cs = context.cs;
    if (a.isGraded) return Icon(Icons.grade, color: cs.primary, size: 32);
    if (a.isSubmitted) return Icon(Icons.check_circle, color: cs.tertiary, size: 32);
    if (a.isLate) return Icon(Icons.warning, color: cs.error, size: 32);
    if (a.isOverdue) return Icon(Icons.error, color: cs.error, size: 32);
    if (a.isDueToday) return Icon(Icons.today, color: cs.secondary, size: 32);
    return Icon(Icons.pending, color: cs.secondary, size: 32);
  }

  void _navigateToDetail(BuildContext context, Assignment a) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StudentAssignmentDetailScreen(assignment: a)),
    );
  }
}

class _OverdueTab extends StatelessWidget {
  final List<Assignment> assignments;

  const _OverdueTab({required this.assignments});

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: context.cs.tertiary.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text('All caught up!', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('No overdue assignments', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary header
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cs.errorContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.cs.error.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: context.cs.error, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${assignments.length} Overdue Assignment${assignments.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.cs.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submit as soon as possible to avoid further penalties',
                      style: TextStyle(fontSize: 13, color: context.cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () {},
                style: FilledButton.styleFrom(backgroundColor: context.cs.error.withValues(alpha: 0.2)),
                child: const Text('Submit All'),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: assignments.length,
            itemBuilder: (context, i) {
              final a = assignments[i];
              final daysOverdue = DateTime.now().difference(a.dueAt).inDays;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                color: context.cs.errorContainer,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: context.cs.error.withValues(alpha: 0.2),
                    child: Text('${i + 1}', style: TextStyle(color: context.cs.error, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (a.subjectCode != null)
                        Text('${a.subjectCode} - ${a.subjectName ?? ''}'),
                      Text('Due: ${DateFormat('MMM d, yyyy HH:mm').format(a.dueAt.toLocal())}'),
                      Row(
                        children: [
                          Chip(
                            label: Text('$daysOverdue day${daysOverdue > 1 ? 's' : ''} overdue',
                                style: TextStyle(fontSize: 11, color: context.cs.error)),
                            backgroundColor: context.cs.error.withValues(alpha: 0.2),
                            labelStyle: TextStyle(color: context.cs.error),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: FilledButton(
                    onPressed: () => _navigateToDetail(context, a),
                    style: FilledButton.styleFrom(backgroundColor: context.cs.error),
                    child: const Text('Submit Now'),
                  ),
                  onTap: () => _navigateToDetail(context, a),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToDetail(BuildContext context, Assignment a) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StudentAssignmentDetailScreen(assignment: a)),
    );
  }
}

class StudentAssignmentDetailScreen extends StatefulWidget {
  final Assignment assignment;

  const StudentAssignmentDetailScreen({super.key, required this.assignment});

  @override
  State<StudentAssignmentDetailScreen> createState() =>
      _StudentAssignmentDetailScreenState();
}

class _StudentAssignmentDetailScreenState
    extends State<StudentAssignmentDetailScreen> {
  late Assignment _assignment;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _assignment = widget.assignment;
  }

  Future<void> _pickAndSubmit() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null) return;

    final pickedFile = result.files.single;
    setState(() => _submitting = true);
    try {
      final mimeType = _getMimeType(pickedFile.name);
      if (pickedFile.path != null) {
        final file = File(pickedFile.path!);
        await apiSubmitAssignment(_assignment.id, file, pickedFile.name, mimeType: mimeType);
      } else if (pickedFile.bytes != null) {
        await apiSubmitAssignmentBytes(_assignment.id, pickedFile.bytes!, pickedFile.name, mimeType: mimeType);
      } else {
        throw Exception('Unable to read file');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment submitted successfully')),
      );
      // Create new Assignment with updated status (since status is final)
      setState(() {
        _assignment = Assignment.fromJson({
          ...widget.assignment.toJson(),
          'status': 'submitted',
          'submitted_at': DateTime.now().toIso8601String(),
        });
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _assignment;
    return Scaffold(
      appBar: AppBar(title: Text(a.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(a.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('${a.subjectCode ?? ''} - ${a.subjectName ?? ''}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Description',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(a.description ?? 'No description provided'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: context.cs.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text('Due: ${DateFormat('MMMM d, yyyy \'at\' HH:mm').format(a.dueAt.toLocal())}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.assignment_outlined, size: 18, color: context.cs.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text('Max Score: ${a.maxScore}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(a.isOverdue || a.isLate
                            ? Icons.error
                            : a.isSubmitted || a.isGraded
                                ? Icons.check_circle
                                : Icons.pending,
                            size: 18,
                            color: a.isOverdue || a.isLate
                                ? context.cs.error
                                : a.isSubmitted || a.isGraded
                                    ? context.cs.tertiary
                                    : context.cs.secondary),
                        const SizedBox(width: 8),
                        Text('Status: ${a.statusDisplay}',
                            style: TextStyle(
                              color: a.isOverdue || a.isLate
                                  ? context.cs.error
                                  : a.isSubmitted || a.isGraded
                                      ? context.cs.tertiary
                                      : context.cs.secondary,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                    if (a.score != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.grade, size: 18, color: context.cs.primary),
                          const SizedBox(width: 8),
                          Text('Score: ${a.score}/${a.maxScore}'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (a.isPending) ...[
              FilledButton.icon(
                onPressed: _submitting ? null : _pickAndSubmit,
                icon: _submitting
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_upload),
                label: Text(_submitting ? 'Submitting...' : 'Submit Assignment'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ] else if (a.isSubmitted || a.isLate) ...[
              FilledButton.icon(
                onPressed: _pickAndSubmit,
                icon: const Icon(Icons.refresh),
                label: const Text('Resubmit'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.lock),
                label: const Text('Graded - No further submissions'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}