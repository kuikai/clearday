import 'dart:convert';

import '../models/app_data.dart';
import '../models/task.dart';
import 'date_utils.dart';

const todayWidgetPrefsKey = 'clearday_widget_tasks';
const todayWidgetHorizonDays = 7;
const todayWidgetTaskCap = 100;

class TodayWidgetTask {
  const TodayWidgetTask({
    required this.title,
    required this.dueMillis,
    required this.hasTime,
  });

  final String title;
  final int dueMillis;
  final bool hasTime;
}

/// Incomplete tasks the home widget can show through the next week.
///
/// Today is kept ahead of overdue so a long overdue list does not push
/// today's tasks out of [cap]. The widget re-checks the dates itself.
List<TodayWidgetTask> todayWidgetTasks(
  AppData data,
  DateTime now, {
  int cap = todayWidgetTaskCap,
}) {
  final today = <Task>[];
  final overdue = <Task>[];
  final soon = <Task>[];
  // Calendar days, so a daylight-saving change does not shorten the week.
  final start = dateOnly(now);
  final horizon = DateTime(
    start.year,
    start.month,
    start.day + todayWidgetHorizonDays,
  );
  for (final task in data.tasks) {
    _bucketTask(task, now, horizon, today, overdue, soon);
  }
  _sortByDue(today);
  _sortByDue(overdue);
  _sortByDue(soon);
  return [
    for (final task in [...today, ...overdue, ...soon].take(cap))
      TodayWidgetTask(
        title: task.title.trim().replaceAll(RegExp(r'\s+'), ' '),
        dueMillis: task.dueAt!.millisecondsSinceEpoch,
        hasTime: task.dueHasTime,
      ),
  ];
}

void _bucketTask(
  Task task,
  DateTime now,
  DateTime horizon,
  List<Task> today,
  List<Task> overdue,
  List<Task> soon,
) {
  final due = task.dueAt;
  if (task.isCompleted || due == null || task.title.trim().isEmpty) {
    return;
  }
  if (isBeforeToday(due, now)) {
    overdue.add(task);
    return;
  }
  if (isSameDay(due, now)) {
    today.add(task);
    return;
  }
  if (!dateOnly(due).isAfter(horizon)) {
    soon.add(task);
  }
}

void _sortByDue(List<Task> tasks) {
  tasks.sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
}

String encodeTodayWidgetTasks(List<TodayWidgetTask> tasks) {
  return jsonEncode([
    for (final task in tasks)
      {
        't': task.title,
        'd': task.dueMillis,
        'h': task.hasTime,
      },
  ]);
}
