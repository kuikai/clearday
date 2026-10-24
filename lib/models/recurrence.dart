enum RecurrenceKind { none, everyNDays, weekly }

/// How often a task should repeat after it is completed.
class Recurrence {
  const Recurrence({
    this.kind = RecurrenceKind.none,
    this.intervalDays = 5,
    this.weekdays = const [],
  });

  final RecurrenceKind kind;
  final int intervalDays;

  /// Weekdays this task repeats on. 1 = Monday … 7 = Sunday.
  final List<int> weekdays;

  bool get isEnabled => kind != RecurrenceKind.none;

  /// Selected weekdays in Monday-to-Sunday order, with invalid values dropped.
  List<int> get selectedWeekdays {
    final days = <int>{
      for (final day in weekdays)
        if (day >= DateTime.monday && day <= DateTime.sunday) day,
    }.toList()..sort();
    return days;
  }

  Recurrence copyWith({
    RecurrenceKind? kind,
    int? intervalDays,
    List<int>? weekdays,
    bool clearWeekdays = false,
  }) {
    return Recurrence(
      kind: kind ?? this.kind,
      intervalDays: intervalDays ?? this.intervalDays,
      weekdays: clearWeekdays ? const [] : (weekdays ?? this.weekdays),
    );
  }

  /// Adds or removes [weekday]. The last selected day stays selected.
  Recurrence toggleWeekday(int weekday) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      return this;
    }
    final days = selectedWeekdays.toSet();
    if (days.contains(weekday)) {
      if (days.length <= 1) {
        return this;
      }
      days.remove(weekday);
    } else {
      days.add(weekday);
    }
    final next = days.toList()..sort();
    return copyWith(weekdays: next);
  }

  Map<String, dynamic> toJson() {
    return {
      'kind': kind.name,
      'intervalDays': intervalDays,
      'weekdays': selectedWeekdays,
    };
  }

  factory Recurrence.fromJson(Map<String, dynamic> json) {
    return Recurrence(
      kind: RecurrenceKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => RecurrenceKind.none,
      ),
      intervalDays: _intervalDaysFromJson(json['intervalDays']),
      weekdays: _weekdaysFromJson(json),
    );
  }

  /// Next due date after completing the current occurrence.
  DateTime nextDueAfter(DateTime from) {
    switch (kind) {
      case RecurrenceKind.none:
        return from;
      case RecurrenceKind.everyNDays:
        // Calendar days keep 9:00 at 9:00 when daylight saving changes.
        return _atSameTime(
          DateTime(
            from.year,
            from.month,
            from.day + _clampedIntervalDays(intervalDays),
          ),
          from,
        );
      case RecurrenceKind.weekly:
        return _nextSelectedWeekday(from);
    }
  }

  /// First selected weekday after [from], keeping the same time of day.
  /// Starts tomorrow so finishing a task does not schedule that same day again.
  DateTime _nextSelectedWeekday(DateTime from) {
    final targets = selectedWeekdays;
    if (targets.isEmpty) {
      return _atSameTime(from.add(const Duration(days: 7)), from);
    }
    var cursor = from.add(const Duration(days: 1));
    for (var step = 0; step < 7; step++) {
      if (targets.contains(cursor.weekday)) {
        return _atSameTime(cursor, from);
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return _atSameTime(from.add(const Duration(days: 7)), from);
  }

  DateTime _atSameTime(DateTime day, DateTime from) {
    return DateTime(day.year, day.month, day.day, from.hour, from.minute);
  }
}

const int _minIntervalDays = 1;
const int _maxIntervalDays = 3650;

int _clampedIntervalDays(int days) {
  if (days < _minIntervalDays) {
    return _minIntervalDays;
  }
  if (days > _maxIntervalDays) {
    return _maxIntervalDays;
  }
  return days;
}

int _intervalDaysFromJson(Object? value) {
  if (value is int) {
    return _clampedIntervalDays(value);
  }
  if (value is num) {
    return _clampedIntervalDays(value.toInt());
  }
  return 5;
}

List<int> _weekdaysFromJson(Map<String, dynamic> json) {
  final rawDays = json['weekdays'];
  if (rawDays is List && rawDays.isNotEmpty) {
    return [
      for (final day in rawDays)
        if (day is int) day else if (day is num) day.toInt(),
    ];
  }
  // Older saves stored a single weekday.
  final legacy = json['weekday'];
  if (legacy is int) {
    return [legacy];
  }
  if (legacy is num) {
    return [legacy.toInt()];
  }
  return const [];
}
