enum RecurrenceKind { none, everyNDays, weekly }

/// How often a task should repeat after it is completed.
class Recurrence {
  const Recurrence({
    this.kind = RecurrenceKind.none,
    this.intervalDays = 5,
    this.weekday,
  });

  final RecurrenceKind kind;
  final int intervalDays;
  final int? weekday;

  bool get isEnabled => kind != RecurrenceKind.none;

  Recurrence copyWith({
    RecurrenceKind? kind,
    int? intervalDays,
    int? weekday,
    bool clearWeekday = false,
  }) {
    return Recurrence(
      kind: kind ?? this.kind,
      intervalDays: intervalDays ?? this.intervalDays,
      weekday: clearWeekday ? null : (weekday ?? this.weekday),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kind': kind.name,
      'intervalDays': intervalDays,
      'weekday': weekday,
    };
  }

  factory Recurrence.fromJson(Map<String, dynamic> json) {
    return Recurrence(
      kind: RecurrenceKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => RecurrenceKind.none,
      ),
      intervalDays: json['intervalDays'] as int? ?? 5,
      weekday: json['weekday'] as int?,
    );
  }

  /// Next due date after completing the current occurrence.
  DateTime nextDueAfter(DateTime from) {
    switch (kind) {
      case RecurrenceKind.none:
        return from;
      case RecurrenceKind.everyNDays:
        return from.add(Duration(days: intervalDays < 1 ? 1 : intervalDays));
      case RecurrenceKind.weekly:
        return _nextWeekday(from, weekday ?? from.weekday);
    }
  }

  DateTime _nextWeekday(DateTime from, int targetWeekday) {
    var cursor = from.add(const Duration(days: 1));
    while (cursor.weekday != targetWeekday) {
      cursor = cursor.add(const Duration(days: 1));
    }
    return DateTime(
      cursor.year,
      cursor.month,
      cursor.day,
      from.hour,
      from.minute,
    );
  }
}
