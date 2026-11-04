class Assignment {
  final int id;
  final String title;
  final String description;
  final int subjectId;
  final DateTime dueDate;
  final String status;
  final String? fileUrl;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectId,
    required this.dueDate,
    this.status = 'pending',
    this.fileUrl,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      subjectId: json['subject_id'] as int,
      dueDate: DateTime.parse(json['due_date'] as String),
      status: json['status'] as String? ?? 'pending',
      fileUrl: json['file_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject_id': subjectId,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'file_url': fileUrl,
    };
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status != 'submitted';

  Assignment copyWith({String? status, String? fileUrl}) {
    return Assignment(
      id: id,
      title: title,
      description: description,
      subjectId: subjectId,
      dueDate: dueDate,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
    );
  }

  @override
  String toString() => 'Assignment(id: , title: , status: )';
}
