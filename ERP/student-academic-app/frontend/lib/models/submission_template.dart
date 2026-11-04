class SubmissionTemplate {
  final int id;
  final String type;
  final String title;
  final int version;
  final int fileSize;
  final String fileUrl;

  SubmissionTemplate({
    required this.id,
    required this.type,
    required this.title,
    required this.version,
    required this.fileSize,
    required this.fileUrl,
  });

  factory SubmissionTemplate.fromJson(Map<String, dynamic> json) {
    return SubmissionTemplate(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      version: json['version'] as int,
      fileSize: json['file_size'] as int,
      fileUrl: json['file_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'version': version,
      'file_size': fileSize,
      'file_url': fileUrl,
    };
  }

  SubmissionTemplate copyWith({int? version}) {
    return SubmissionTemplate(
      id: id,
      type: type,
      title: title,
      version: version ?? this.version,
      fileSize: fileSize,
      fileUrl: fileUrl,
    );
  }

  String get fileSizeMb => (fileSize / (1024 * 1024)).toStringAsFixed(2);

  @override
  String toString() => 'SubmissionTemplate(id: , type: , version: )';
}
