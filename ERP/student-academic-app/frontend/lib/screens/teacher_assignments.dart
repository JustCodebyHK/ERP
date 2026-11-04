import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../models/assignment.dart';
import '../models/submission.dart';
import '../widgets/app_theme.dart';

class TeacherAssignmentsScreen extends StatefulWidget {
  final String batchId;
  final String batchName;
  final String subjectId;
  final String subjectCode;
  final String subjectName;

  const TeacherAssignmentsScreen({
    super.key,
    required this.batchId,
    required this.batchName,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
  });

  @override
  State<TeacherAssignmentsScreen> createState() => _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  late Future<List<Assignment>> _future;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Assignment>> _load() async {
    final data = await apiListAssignments(widget.batchId, widget.subjectId);
    return (data['assignments'] as List)
        .map((e) => Assignment.fromJson(e))
        .toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
  }

  Future<void> _showCreateDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay dueTime = TimeOfDay(hour: 23, minute: 59);
    int maxScore = 100;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create Assignment'),
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (d != null) setState(() => dueDate = d);
                        },
                        child: Text(DateFormat('MMM d, yyyy').format(dueDate)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: dueTime,
                          );
                          if (t != null) setState(() => dueTime = t);
                        },
                        child: Text(dueTime.format(ctx)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max Score', hintText: '100'),
                  onChanged: (v) => maxScore = int.tryParse(v) ?? 100,
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
              onPressed: _creating
                  ? null
                  : () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      final dueAt = DateTime(
                        dueDate.year,
                        dueDate.month,
                        dueDate.day,
                        dueTime.hour,
                        dueTime.minute,
                      );
                      setState(() => _creating = true);
                      try {
                        await apiCreateAssignment({
                          'batch_id': widget.batchId,
                          'subject_id': widget.subjectId,
                          'title': titleCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'due_at': dueAt.toIso8601String(),
                          'max_score': maxScore,
                        });
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Assignment created')),
                        );
                        _refresh();
                      } catch (e) {
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Failed: $e')),
                        );
                      } finally {
                        if (mounted) setState(() => _creating = false);
                      }
                    },
              child: _creating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subjectCode} - Assignments'),
        actions: [
          IconButton(
            tooltip: 'Create Assignment',
            onPressed: _creating ? null : _showCreateDialog,
            icon: _creating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Assignment>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load: ${snapshot.error}'));
          }
          final assignments = snapshot.data!;
          if (assignments.isEmpty) {
            return const Center(child: Text('No assignments yet. Tap + to create one.'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: assignments.length,
              itemBuilder: (context, i) {
                final a = assignments[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: const Icon(Icons.assignment_outlined),
                    title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Due: ${DateFormat('MMM d, yyyy HH:mm').format(a.dueAt.toLocal())}'),
                        Text('Received: ${a.received ?? 0} / ${a.totalSubmissions ?? 0}'),
                      ],
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () => _navigateToSubmissions(context, a),
                      child: const Text('Submissions'),
                    ),
                    onTap: () => _navigateToSubmissions(context, a),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _navigateToSubmissions(BuildContext context, Assignment a) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeacherSubmissionsScreen(
          assignment: a,
          batchName: widget.batchName,
          subjectCode: widget.subjectCode,
        ),
      ),
    );
  }
}

class TeacherSubmissionsScreen extends StatefulWidget {
  final Assignment assignment;
  final String batchName;
  final String subjectCode;

  const TeacherSubmissionsScreen({
    super.key,
    required this.assignment,
    required this.batchName,
    required this.subjectCode,
  });

  @override
  State<TeacherSubmissionsScreen> createState() => _TeacherSubmissionsScreenState();
}

class _TeacherSubmissionsScreenState extends State<TeacherSubmissionsScreen> {
  late Future<List<Submission>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Submission>> _load() async {
    final data = await apiAssignmentSubmissions(widget.assignment.id);
    return (data['submissions'] as List).map((e) => Submission.fromJson(e)).toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
  }

  Future<void> _showGradeDialog(Submission s) async {
    final scoreCtrl = TextEditingController(text: s.score?.toString() ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Grade ${s.studentName ?? s.studentId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Assignment: ${widget.assignment.title}'),
            const SizedBox(height: 12),
            TextField(
              controller: scoreCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Score (max ${widget.assignment.maxScore})',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final score = int.tryParse(scoreCtrl.text);
              if (score == null) return;
              final maxScore = widget.assignment.maxScore;
              if (score < 0 || (maxScore != null && score > maxScore)) return;
              try {
                await apiGradeSubmission(widget.assignment.id, s.studentId, score!);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Graded successfully')),
                );
                _refresh();
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Failed: $e')),
                );
              }
            },
            child: const Text('Save Grade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subjectCode} - ${widget.assignment.title}'),
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<Submission>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load: ${snapshot.error}'));
          }
          final submissions = snapshot.data!;
          if (submissions.isEmpty) {
            return const Center(child: Text('No submissions yet'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: submissions.length,
              itemBuilder: (context, i) {
                final s = submissions[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(s.studentName?[0] ?? '?')),
                    title: Text(s.studentName ?? 'Unknown'),
                    subtitle: Text(s.studentEmail ?? ''),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(
                          label: Text(s.statusDisplay),
                          backgroundColor: s.status == 'graded'
                              ? context.cs.primary.withValues(alpha: 0.1)
                              : s.status == 'submitted'
                                  ? context.cs.tertiary.withValues(alpha: 0.1)
                                  : s.status == 'late'
                                      ? context.cs.error.withValues(alpha: 0.1)
                                      : context.cs.secondary.withValues(alpha: 0.1),
                        ),
                        if (s.score != null)
                          Text('Score: ${s.score}/${widget.assignment.maxScore}',
                              style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    onTap: () => _showGradeDialog(s),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
