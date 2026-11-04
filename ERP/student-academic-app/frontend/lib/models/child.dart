class Child {
  final int id;
  final String name;
  final String email;
  final String rollNumber;
  final int? classId;
  final String? className;

  Child({
    required this.id,
    required this.name,
    required this.email,
    required this.rollNumber,
    this.classId,
    this.className,
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      rollNumber: json['roll_number'] as String,
      classId: json['class_id'] as int?,
      className: json['class_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'roll_number': rollNumber,
      'class_id': classId,
      'class_name': className,
    };
  }

  @override
  String toString() => 'Child(id: $id, name: $name, roll: $rollNumber)';
}
