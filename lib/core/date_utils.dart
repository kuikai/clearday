import 'package:intl/intl.dart';

import 'constants/app_constants.dart';

DateTime dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool isBeforeToday(DateTime value, DateTime now) {
  return dateOnly(value).isBefore(dateOnly(now));
}

bool isAfterToday(DateTime value, DateTime now) {
  return dateOnly(value).isAfter(dateOnly(now));
}

/// True when [value] is after today and on or before [now] plus [days].
/// With [days] 2, that is tomorrow and the day after tomorrow.
bool isUpcomingWithinDays(DateTime value, DateTime now, {int days = 2}) {
  final dueDay = dateOnly(value);
  final today = dateOnly(now);
  final lastDay = today.add(Duration(days: days));
  return dueDay.isAfter(today) && !dueDay.isAfter(lastDay);
}

/// Date-only value guaranteed to sit between [firstDate] and [lastDate].
/// [showDatePicker] asserts if [initialDate] is outside that range.
DateTime clampToDateRange(
  DateTime? preferred, {
  required DateTime firstDate,
  required DateTime lastDate,
  required DateTime now,
}) {
  var initial = dateOnly(preferred ?? now);
  final first = dateOnly(firstDate);
  final last = dateOnly(lastDate);
  if (initial.isBefore(first)) {
    return first;
  }
  if (initial.isAfter(last)) {
    return last;
  }
  return initial;
}

String formatDueLabel(DateTime dueAt, {required bool hasTime}) {
  final date = DateFormat.MMMd().format(dueAt);
  if (!hasTime) {
    return date;
  }
  return '$date · ${DateFormat.jm().format(dueAt)}';
}

String formatReminderLabel(DateTime reminderAt) {
  return '${DateFormat.MMMd().format(reminderAt)} · '
      '${DateFormat.jm().format(reminderAt)}';
}

DateTime? defaultReminderFor({
  required DateTime? dueAt,
  required bool dueHasTime,
}) {
  if (dueAt == null) {
    return null;
  }
  if (dueHasTime) {
    return dueAt;
  }
  return DateTime(
    dueAt.year,
    dueAt.month,
    dueAt.day,
    AppConstants.defaultReminderHour,
  );
}
