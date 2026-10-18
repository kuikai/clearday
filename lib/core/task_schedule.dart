import '../models/task.dart';
import 'date_utils.dart';

/// A copy of [task] due the day after [now], or null when it should stay put.
///
/// A clock time is kept when the task already has one. A reminder keeps the
/// same gap before the due time.
Task? taskMovedToTomorrow(Task task, DateTime now) {
  return _movedToDay(task, dateOnly(now).add(const Duration(days: 1)));
}

/// A copy of [task] due on [now]'s calendar day, or null when it should stay put.
Task? taskMovedToToday(Task task, DateTime now) {
  return _movedToDay(task, dateOnly(now));
}

/// Incomplete overdue tasks moved onto today. [groupId] limits the move to
/// one group.
OverdueMovePlan planOverdueMoveToToday(
  List<Task> tasks,
  DateTime now, {
  String? groupId,
}) {
  final previous = <Task>[];
  final next = <Task>[];
  for (final task in tasks) {
    if (!_isOverdueInGroup(task, now, groupId)) {
      next.add(task);
      continue;
    }
    final moved = taskMovedToToday(task, now);
    if (moved == null) {
      next.add(task);
      continue;
    }
    previous.add(task);
    next.add(moved);
  }
  return OverdueMovePlan(previous: previous, tasks: next);
}

List<Task> tasksWithReminderOnMoved(
  OverdueMovePlan plan,
  Task Function(Task task) applyReminder,
) {
  final movedIds = {for (final task in plan.previous) task.id};
  return [
    for (final task in plan.tasks)
      if (movedIds.contains(task.id)) applyReminder(task) else task,
  ];
}

class OverdueMovePlan {
  const OverdueMovePlan({required this.previous, required this.tasks});

  final List<Task> previous;
  final List<Task> tasks;
}

Task? _movedToDay(Task task, DateTime day) {
  if (task.isCompleted) {
    return null;
  }
  final hasTime = task.dueAt != null && task.dueHasTime;
  final nextDue = _dueOnDay(day, task.dueAt, hasTime);
  if (_alreadyDueThen(task, nextDue, hasTime)) {
    return null;
  }
  final reminder = _reminderAtSameGap(task, nextDue);
  return task.copyWith(
    dueAt: nextDue,
    dueHasTime: hasTime,
    reminderAt: reminder,
    clearReminderAt: reminder == null,
  );
}

DateTime _dueOnDay(DateTime day, DateTime? dueAt, bool hasTime) {
  final date = dateOnly(day);
  if (!hasTime || dueAt == null) {
    return date;
  }
  return DateTime(date.year, date.month, date.day, dueAt.hour, dueAt.minute);
}

bool _isOverdueInGroup(Task task, DateTime now, String? groupId) {
  final due = task.dueAt;
  if (task.isCompleted || due == null || !isBeforeToday(due, now)) {
    return false;
  }
  return groupId == null || task.groupId == groupId;
}

bool _alreadyDueThen(Task task, DateTime nextDue, bool hasTime) {
  final due = task.dueAt;
  if (due == null || !isSameDay(due, nextDue)) {
    return false;
  }
  if (!hasTime) {
    return true;
  }
  return due.hour == nextDue.hour && due.minute == nextDue.minute;
}

DateTime? _reminderAtSameGap(Task task, DateTime nextDue) {
  final due = task.dueAt;
  final reminder = task.reminderAt;
  if (due == null || reminder == null) {
    return null;
  }
  return nextDue.subtract(due.difference(reminder));
}
