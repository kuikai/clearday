import 'recurrence.dart';

class Task {
  const Task({
    required this.id,
    required this.groupId,
    required this.title,
    required this.createdAt,
    this.notes = '',
    this.dueAt,
    this.dueHasTime = false,
    this.reminderAt,
    this.isCompleted = false,
    this.completedAt,
    this.recurrence = const Recurrence(),
  });

  final String id;
  final String groupId;
  final String title;
  final String notes;
  final DateTime? dueAt;
  final bool dueHasTime;
  final DateTime? reminderAt;
  final bool isCompleted;
  final DateTime? completedAt;
  final Recurrence recurrence;
  final DateTime createdAt;

  Task copyWith({
    String? groupId,
    String? title,
    String? notes,
    DateTime? dueAt,
    bool? dueHasTime,
    DateTime? reminderAt,
    bool? isCompleted,
    DateTime? completedAt,
    Recurrence? recurrence,
    bool clearDueAt = false,
    bool clearReminderAt = false,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      dueHasTime: dueHasTime ?? this.dueHasTime,
      reminderAt: clearReminderAt ? null : (reminderAt ?? this.reminderAt),
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      recurrence: recurrence ?? this.recurrence,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'listId': groupId,
      'title': title,
      'notes': notes,
      'dueAt': dueAt?.toIso8601String(),
      'dueHasTime': dueHasTime,
      'reminderAt': reminderAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'recurrence': recurrence.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      groupId: (json['groupId'] as String?) ?? (json['listId'] as String),
      title: json['title'] as String,
      notes: json['notes'] as String? ?? '',
      dueAt: _parseDate(json['dueAt']),
      dueHasTime: json['dueHasTime'] as bool? ?? false,
      reminderAt: _parseDate(json['reminderAt']),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: _parseDate(json['completedAt']),
      recurrence: json['recurrence'] is Map<String, dynamic>
          ? Recurrence.fromJson(json['recurrence'] as Map<String, dynamic>)
          : const Recurrence(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    return null;
  }
}
