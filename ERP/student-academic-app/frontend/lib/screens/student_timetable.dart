import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api.dart';
import '../models/timetable.dart';
import '../widgets/app_theme.dart';

class StudentTimetableScreen extends StatefulWidget {
  const StudentTimetableScreen({super.key});

  @override
  State<StudentTimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<StudentTimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _weeklyFuture;
  late Future<Map<String, dynamic>> _todayFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _weeklyFuture = apiMyTimetableCached();
    _todayFuture = apiTodayTimetableCached();
  }

  Future<void> _refresh() async {
    setState(() {
      _weeklyFuture = apiMyTimetableCached();
      _todayFuture = apiTodayTimetableCached();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Timetable'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Today ($today)'),
            const Tab(text: 'Weekly'),
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
          _TodayView(future: _todayFuture),
          _WeeklyView(future: _weeklyFuture),
        ],
      ),
    );
  }
}

class _TodayView extends StatelessWidget {
  final Future<Map<String, dynamic>> future;

  const _TodayView({required this.future});

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
        final entries = (data['entries'] as List)
            .map((e) => TimetableEntry.fromJson(e))
            .toList();
        final day = data['day'] as String? ?? DateFormat('EEEE').format(DateTime.now());

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 64, color: context.cs.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('No classes today ($day)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Enjoy your free day!', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final e = entries[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: Text(e.subjectName ?? e.subjectCode ?? 'Class',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.timeRange),
                    if (e.batchName != null) Text(e.batchName!),
                    Text('Room: ${e.displayRoom}'),
                  ],
                ),
                trailing: Icon(Icons.schedule, color: Theme.of(context).colorScheme.primary),
              ),
            );
          },
        );
      },
    );
  }
}

class _WeeklyView extends StatelessWidget {
  final Future<Map<String, dynamic>> future;

  const _WeeklyView({required this.future});

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
        final timetable = data['timetable'] as Map<String, dynamic>;
        final days = data['days'] as List<String>;

        bool hasAny = timetable.values.any((list) => (list as List).isNotEmpty);

        if (!hasAny) {
          return const Center(child: Text('No timetable entries yet'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(7, (i) {
              final dayEntries = (timetable['$i'] as List? ?? [])
                  .map((e) => TimetableEntry.fromJson(e))
                  .toList();
              if (dayEntries.isEmpty) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text('${i + 1}'),
                  ),
                  title: Text(days[i], style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${dayEntries.length} class${dayEntries.length > 1 ? 'es' : ''}'),
                  children: dayEntries.map((e) => ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text(e.subjectName ?? e.subjectCode ?? 'Class'),
                    subtitle: Text('${e.timeRange} • Room: ${e.displayRoom}'),
                    trailing: Text(e.batchName ?? ''),
                    dense: true,
                  )).toList(),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
