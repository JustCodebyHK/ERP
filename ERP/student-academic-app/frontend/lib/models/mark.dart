class Mark {
  final int id;
  final String subject;
  final int score;
  final int maxScore;
  final String? grade;

  Mark({
    required this.id,
    required this.subject,
    required this.score,
    required this.maxScore,
    this.grade,
  });

  factory Mark.fromJson(Map<String, dynamic> json) {
    return Mark(
      id: json['id'] as int,
      subject: json['subject'] as String,
      score: json['score'] as int,
      maxScore: json['max_score'] as int,
      grade: json['grade'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'score': score,
      'max_score': maxScore,
      'grade': grade,
    };
  }

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0.0;

  @override
  String toString() => 'Mark(subject: $subject, score: $score/$maxScore)';
}
