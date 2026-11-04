class Parent {
  final int id;
  final String name;
  final String email;
  final String phone;
  final List<int> childrenIds;

  Parent({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.childrenIds = const [],
  });

  factory Parent.fromJson(Map<String, dynamic> json) {
    return Parent(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      childrenIds: (json['children_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'children_ids': childrenIds,
    };
  }

  Parent copyWith({List<int>? childrenIds}) {
    return Parent(
      id: id,
      name: name,
      email: email,
      phone: phone,
      childrenIds: childrenIds ?? this.childrenIds,
    );
  }

  int get childrenCount => childrenIds.length;

  @override
  String toString() => 'Parent(id: $id, name: $name, children: $childrenCount)';
}
