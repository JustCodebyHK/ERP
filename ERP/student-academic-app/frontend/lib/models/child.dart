class Child {
  final String id;
  final String name;
  final String email;
  final String rollNumber;
  final String relationship;
  final String? className;

  Child({
    required this.id,
    required this.name,
    required this.email,
    required this.rollNumber,
    required this.relationship,
    this.className,
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      rollNumber: json['roll_number'] as String,
      relationship: json['relationship'] as String,
      className: json['class_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'roll_number': rollNumber,
      'relationship': relationship,
      'class_name': className,
    };
  }

  @override
  String toString() => 'Child(id: $id, name: $name, relationship: $relationship)';
}
