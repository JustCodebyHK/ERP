class MarkDetail {
  final String subject;
  final int score;
  final int maxScore;
  final String? grade;
  final String title;
  final String name;
  final String type;

  MarkDetail({
    required this.subject,
    required this.score,
    required this.maxScore,
    this.grade,
    required this.title,
    required this.name,
    required this.type,
  });

  factory MarkDetail.fromJson(Map<String, dynamic> json) {
    return MarkDetail(
      subject: json['subject'] as String,
      score: json['score'] as int,
      maxScore: json['max_score'] as int,
      grade: json['grade'] as String?,
      title: json['title'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'score': score,
      'max_score': maxScore,
      'grade': grade,
      'title': title,
      'name': name,
      'type': type,
    };
  }

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0.0;

  bool get passed => percentage >= 50;

  @override
  String toString() => 'MarkDetail(subject: $subject, score: $score/$maxScore)';
}
