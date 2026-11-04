import 'package:flutter/material.dart';

import '../api.dart';
import '../models/growth.dart';
import '../models/growth_index.dart';
import '../models/component_detail.dart';
import '../models/attendance_detail.dart';
import '../models/mark_detail.dart';
import '../widgets/app_theme.dart';

class GrowthScreen extends StatefulWidget {
  const GrowthScreen({super.key});

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = apiMyGrowth();
  }

  Future<void> _refresh() async {
    setState(() => _future = apiMyGrowth());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Growth Index'),
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
            return Center(child: Text('Failed to load: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          final growth = GrowthIndex.fromJson(data);

          if (growth.growthIndex == null) {
            return const Center(
              child: Text(
                'No data available yet. Complete some assignments, attend classes, and get grades to see your growth index.',
              ),
            );
          }

          final attendance = ComponentDetail.fromJson(
            growth.components['attendance'],
          );
          final marks = ComponentDetail.fromJson(growth.components['marks']);
          final assignments = ComponentDetail.fromJson(
            growth.components['assignments'],
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Growth Index Card
                  Card(
                    elevation: 4,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Overall Growth Index',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: context.cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            growth.growthIndex.toString(),
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  color: context.cs.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getGrowthLabel(growth.growthIndex!),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: context.cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Component Cards
                  Text(
                    'Components',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _ComponentCard(
                    title: 'Attendance',
                    icon: Icons.verified,
                    score: attendance.score,
                    weight: attendance.weight,
                    color: context.cs.tertiary,
                    onTap: () => _showAttendanceDetails(attendance),
                  ),
                  const SizedBox(height: 12),
                  _ComponentCard(
                    title: 'Marks',
                    icon: Icons.grade,
                    score: marks.score,
                    weight: marks.weight,
                    color: context.cs.primary,
                    onTap: () => _showMarksDetails(marks),
                  ),
                  const SizedBox(height: 12),
                  _ComponentCard(
                    title: 'Assignment Discipline',
                    icon: Icons.assignment_turned_in,
                    score: assignments.score,
                    weight: assignments.weight,
                    color: context.cs.secondary,
                    onTap: () => _showAssignmentsDetails(assignments),
                  ),
                  const SizedBox(height: 24),

                  // Weight explanation
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How it works',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _WeightRow(
                            label: 'Attendance',
                            weight: 0.35,
                            color: context.cs.tertiary,
                          ),
                          _WeightRow(
                            label: 'Marks',
                            weight: 0.45,
                            color: context.cs.primary,
                          ),
                          _WeightRow(
                            label: 'Assignment Discipline',
                            weight: 0.20,
                            color: context.cs.secondary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Growth Index = (Attendance × 35%) + (Marks × 45%) + (Assignments × 20%)',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: context.cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getGrowthLabel(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 60) return 'Fair';
    return 'Needs Improvement';
  }

  void _showAttendanceDetails(ComponentDetail component) {
    final details = component.details.cast<Map<String, dynamic>>();
    final items = details.map((d) => AttendanceDetail.fromJson(d)).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Attendance by Subject',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final a = items[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: a.statusColor.withValues(alpha: 0.1),
                        child: Text(
                          '${a.percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: a.statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text('${a.subject} - ${a.name}'),
                      subtitle: Text('${a.attended}/${a.total} lectures'),
                      trailing: Text(
                        a.percentageDisplay,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: a.statusColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMarksDetails(ComponentDetail component) {
    final details = component.details.cast<Map<String, dynamic>>();
    final items = details.map((d) => MarkDetail.fromJson(d)).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Marks by Subject',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final m = items[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: m.passed
                            ? context.cs.tertiary.withValues(alpha: 0.1)
                            : context.cs.error.withValues(alpha: 0.1),
                        child: Text(
                          '${m.percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: m.passed ? context.cs.tertiary : context.cs.error,
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
                          Text('${m.subject} - ${m.name}'),
                          Text(
                            'Type: ${m.type} • Score: ${m.score}/${m.maxScore}',
                          ),
                        ],
                      ),
                      trailing: Chip(
                        label: Text('${m.percentage.toStringAsFixed(1)}%'),
                        backgroundColor: m.passed
                            ? context.cs.tertiary.withValues(alpha: 0.1)
                            : context.cs.error.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color: m.passed ? context.cs.tertiary : context.cs.error,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignmentsDetails(ComponentDetail component) {
    final details = component.details as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.7,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Assignment Discipline',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  _DetailRow(
                    label: 'Total Assignments',
                    value: details['totalAssignments']?.toString() ?? '0',
                  ),
                  _DetailRow(
                    label: 'Submitted On Time',
                    value: details['submittedOnTime']?.toString() ?? '0',
                    color: context.cs.tertiary,
                  ),
                  _DetailRow(
                    label: 'Submitted Late',
                    value: details['submittedLate']?.toString() ?? '0',
                    color: context.cs.error,
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

class _ComponentCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? score;
  final double weight;
  final Color color;
  final VoidCallback onTap;

  const _ComponentCard({
    required this.title,
    required this.icon,
    required this.score,
    required this.weight,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Weight: ${(weight * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    score != null ? '$score%' : 'N/A',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: score != null
                          ? (score! >= 90
                                ? context.cs.tertiary
                                : score! >= 75
                                ? context.cs.secondary
                                : context.cs.error)
                          : context.cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Weight: ${(weight * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightRow extends StatelessWidget {
  final String label;
  final double weight;
  final Color color;

  const _WeightRow({
    required this.label,
    required this.weight,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            '${(weight * 100).toInt()}%',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _DetailRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

