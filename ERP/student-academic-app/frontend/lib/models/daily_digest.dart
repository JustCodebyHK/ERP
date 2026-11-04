class DailyDigest {
  final String date;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final List<PlannerTask> tasks;
  final List<dynamic> classes;

  DailyDigest({
    required this.date,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.tasks,
    required this.classes,
  });

  factory DailyDigest.fromJson(Map<String, dynamic> json) {
    return DailyDigest(
      date: json['date'] as String,
      totalTasks: json['total_tasks'] as int,
      completedTasks: json['completed_tasks'] as int,
      pendingTasks: json['pending_tasks'] as int,
      tasks: (json['tasks'] as List)
          .map((e) => PlannerTask.fromJson(e as Map<String, dynamic>))
          .toList(),
      classes: json['classes'] as List?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'total_tasks': totalTasks,
      'completed_tasks': completedTasks,
      'pending_tasks': pendingTasks,
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'classes': classes,
    };
  }

  double get completionRate => totalTasks > 0 ? completedTasks / totalTasks : 0.0;

  @override
  String toString() => 'DailyDigest(date: $date, tasks: $totalTasks, completed: $completedTasks)';
}
