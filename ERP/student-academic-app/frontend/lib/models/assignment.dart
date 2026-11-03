/// Assignment model from API
class Assignment {
  final String id;
  final String batchId;
  final String subjectId;
  final String title;
  final String? description;
  final DateTime dueAt;
  final int maxScore;
  final String? createdBy;
  final DateTime createdAt;
  final String? batchName;
  final String? subjectCode;
  final String? subjectName;
  final String? submissionId;
  final String? status;
  final DateTime? submittedAt;
  final int? score;
  final String? filePath;
  final int? received;
  final int? totalSubmissions;

  Assignment({
    required this.id,
    required this.batchId,
    required this.subjectId,
    required this.title,
    this.description,
    required this.dueAt,
    required this.maxScore,
    this.createdBy,
    required this.createdAt,
    this.batchName,
    this.subjectCode,
    this.subjectName,
    this.submissionId,
    this.status,
    this.submittedAt,
    this.score,
    this.filePath,
    this.received,
    this.totalSubmissions,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: json['id'] as String,
        batchId: json['batch_id'] as String,
        subjectId: json['subject_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        dueAt: DateTime.parse(json['due_at'] as String),
        maxScore: (json['max_score'] as num).toInt(),
        createdBy: json['created_by'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        batchName: json['batch_name'] as String?,
        subjectCode: json['subject_code'] as String?,
        subjectName: json['subject_name'] as String?,
        submissionId: json['submission_id'] as String?,
        status: json['status'] as String?,
        submittedAt: json['submitted_at'] != null
            ? DateTime.parse(json['submitted_at'] as String)
            : null,
        score: (json['score'] as num?)?.toInt(),
        filePath: json['file_path'] as String?,
        received: (json['received'] as num?)?.toInt(),
        totalSubmissions: (json['total_submissions'] as num?)?.toInt(),
      );

  bool get isPending => status == 'pending' || status == null;
  bool get isSubmitted => status == 'submitted';
  bool get isLate => status == 'late';
  bool get isGraded => status == 'graded';
  bool get isOverdue => isPending && dueAt.isBefore(DateTime.now());
  bool get isDueToday => isPending &&
      dueAt.year == DateTime.now().year &&
      dueAt.month == DateTime.now().month &&
      dueAt.day == DateTime.now().day;

  String get statusDisplay {
    if (isGraded) return 'Graded: $score/$maxScore';
    if (isLate) return 'Late';
    if (isSubmitted) return 'Submitted';
    if (isOverdue) return 'Overdue';
    if (isDueToday) return 'Due Today';
    return 'Pending';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'batch_id': batchId,
        'subject_id': subjectId,
        'title': title,
        'description': description,
        'due_at': dueAt.toIso8601String(),
        'max_score': maxScore,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'batch_name': batchName,
        'subject_code': subjectCode,
        'subject_name': subjectName,
        'submission_id': submissionId,
        'status': status,
        'submitted_at': submittedAt?.toIso8601String(),
        'score': score,
        'file_path': filePath,
      };
}

/// Submission model from API
class Submission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String status;
  final String? filePath;
  final String? originalName;
  final String? mimeType;
  final int? sizeBytes;
  final DateTime? submittedAt;
  final int? score;
  final String? gradedBy;
  final DateTime? gradedAt;
  final DateTime createdAt;
  final String? studentName;
  final String? studentEmail;

  Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.status,
    this.filePath,
    this.originalName,
    this.mimeType,
    this.sizeBytes,
    this.submittedAt,
    this.score,
    this.gradedBy,
    this.gradedAt,
    required this.createdAt,
    this.studentName,
    this.studentEmail,
  });

  factory Submission.fromJson(Map<String, dynamic> json) => Submission(
        id: json['id'] as String,
        assignmentId: json['assignment_id'] as String,
        studentId: json['student_id'] as String,
        status: json['status'] as String,
        filePath: json['file_path'] as String?,
        originalName: json['original_name'] as String?,
        mimeType: json['mime_type'] as String?,
        sizeBytes: (json['size_bytes'] as num?)?.toInt(),
        submittedAt: json['submitted_at'] != null
            ? DateTime.parse(json['submitted_at'] as String)
            : null,
        score: (json['score'] as num?)?.toInt(),
        gradedBy: json['graded_by'] as String?,
        gradedAt: json['graded_at'] != null
            ? DateTime.parse(json['graded_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        studentName: json['student_name'] as String?,
        studentEmail: json['student_email'] as String?,
      );

  String get formattedSize {
    if (sizeBytes == null) return '';
    if (sizeBytes! < 1024) return '$sizeBytes B';
    if (sizeBytes! < 1024 * 1024) return '${(sizeBytes! / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get statusDisplay {
    if (status == 'graded') return 'Graded';
    if (status == 'submitted') return 'Submitted';
    if (status == 'late') return 'Late';
    return 'Pending';
  }
}