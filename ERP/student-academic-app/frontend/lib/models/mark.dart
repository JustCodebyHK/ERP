class Mark {
  final String title;
  final String code;
  final String name;
  final String type;
  final int score;
  final int maxScore;

  Mark({
    required this.title,
    required this.code,
    required this.name,
    required this.type,
    required this.score,
    required this.maxScore,
  });

  factory Mark.fromJson(Map<String, dynamic> json) {
    return Mark(
      title: json['title'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      score: json['score'] as int,
      maxScore: json['max_score'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'code': code,
      'name': name,
      'type': type,
      'score': score,
      'max_score': maxScore,
    };
  }

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0.0;

  @override
  String toString() => 'Mark(name: $name, score: $score/$maxScore)';
}
