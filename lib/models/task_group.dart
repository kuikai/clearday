class TaskGroup {
  const TaskGroup({
    required this.id,
    required this.name,
    required this.createdAt,
    this.parentId,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String? parentId;

  bool get isTopLevel => parentId == null;

  TaskGroup copyWith({
    String? name,
    String? parentId,
    bool clearParentId = false,
  }) {
    return TaskGroup(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'parentId': parentId,
    };
  }

  factory TaskGroup.fromJson(Map<String, dynamic> json) {
    return TaskGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      parentId: json['parentId'] as String?,
    );
  }
}
