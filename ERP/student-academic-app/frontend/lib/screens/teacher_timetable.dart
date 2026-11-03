import 'package:flutter/material.dart';

import '../api.dart';
import '../models/timetable.dart';

class TeacherTimetableScreen extends StatefulWidget {
  final String batchId;
  final String batchName;
  final String subjectId;
  final String subjectCode;
  final String subjectName;

  const TeacherTimetableScreen({
    super.key,
    required this.batchId,
    required this.batchName,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
  });

  @override
  State<TeacherTimetableScreen> createState() => _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState extends State<TeacherTimetableScreen> {
  late Future<List<TimetableEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<TimetableEntry>> _load() async {
    final data = await apiListTimetable(widget.batchId, widget.subjectId);
    return (data['entries'] as List).map((e) => TimetableEntry.fromJson(e)).toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
  }

  Future<void> _showEntryDialog({TimetableEntry? entry}) async {
    final dayCtrl = TextEditingController(text: entry?.dayOfWeek.toString() ?? '1');
    final startCtrl = TextEditingController(text: entry?.startTime ?? '09:00');
    final endCtrl = TextEditingController(text: entry?.endTime ?? '10:30');
    final roomCtrl = TextEditingController(text: entry?.room ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(entry == null ? 'Add Timetable Entry' : 'Edit Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: entry?.dayOfWeek ?? 1,
                decoration: const InputDecoration(labelText: 'Day'),
                items: List.generate(7, (i) => DropdownMenuItem(
                  value: i,
                  child: Text(TimetableEntry.days[i]),
                )),
                onChanged: (v) => dayCtrl.text = (v ?? 1).toString(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: startCtrl,
                decoration: const InputDecoration(
                  labelText: 'Start Time (HH:MM)',
                  hintText: '09:00',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endCtrl,
                decoration: const InputDecoration(
                  labelText: 'End Time (HH:MM)',
                  hintText: '10:30',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Room (optional)',
                  hintText: 'Room 101',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final day = int.tryParse(dayCtrl.text) ?? 1;
              final start = startCtrl.text.trim();
              final end = endCtrl.text.trim();
              if (start.isEmpty || end.isEmpty) return;

              try {
                if (entry == null) {
                  await apiCreateTimetableEntry({
                    'batch_id': widget.batchId,
                    'subject_id': widget.subjectId,
                    'day_of_week': day,
                    'start_time': start,
                    'end_time': end,
                    'room': roomCtrl.text.trim(),
                  });
                } else {
                  await apiUpdateTimetableEntry(entry.id, {
                    'day_of_week': day,
                    'start_time': start,
                    'end_time': end,
                    'room': roomCtrl.text.trim(),
                  });
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(entry == null ? 'Entry added' : 'Entry updated')),
                );
                _refresh();
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Failed: $e')),
                );
              }
            },
            child: Text(entry == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(TimetableEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Delete ${TimetableEntry.days[entry.dayOfWeek]} ${entry.timeRange}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await apiDeleteTimetableEntry(entry.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subjectCode} - Timetable'),
        actions: [
          IconButton(
            tooltip: 'Add Entry',
            onPressed: () => _showEntryDialog(),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<TimetableEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load: ${snapshot.error}'));
          }
          final entries = snapshot.data!;
          if (entries.isEmpty) {
            return const Center(child: Text('No timetable entries. Tap + to add.'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final e = entries[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text('${e.dayOfWeek + 1}'),
                    ),
                    title: Text(TimetableEntry.days[e.dayOfWeek],
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.timeRange),
                        Text('Room: ${e.displayRoom}'),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _showEntryDialog(entry: e);
                        if (value == 'delete') _deleteEntry(e);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    onTap: () => _showEntryDialog(entry: e),
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
