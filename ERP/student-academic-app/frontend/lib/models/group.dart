class Group {
  final int id;
  final String name;
  final String inviteCode;
  final int creatorId;
  final int memberCount;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.creatorId,
    this.memberCount = 0,
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as int,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String,
      creatorId: json['creator_id'] as int,
      memberCount: json['member_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'invite_code': inviteCode,
      'creator_id': creatorId,
      'member_count': memberCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Group copyWith({int? memberCount}) {
    return Group(
      id: id,
      name: name,
      inviteCode: inviteCode,
      creatorId: creatorId,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'Group(id: , name: , members: )';
}
