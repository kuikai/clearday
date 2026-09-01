import 'package:intl/intl.dart';

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
