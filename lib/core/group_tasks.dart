import '../models/task.dart';
import 'date_utils.dart';

class TaskGroups {
  const TaskGroups({
    required this.overdue,
    required this.today,
    required this.upcoming,
    required this.noDate,
    required this.done,
  });

  final List<Task> overdue;
  final List<Task> today;
  final List<Task> upcoming;
  final List<Task> noDate;
  final List<Task> done;

  bool get isEmpty =>
      overdue.isEmpty &&
      today.isEmpty &&
      upcoming.isEmpty &&
      noDate.isEmpty &&
      done.isEmpty;
}

TaskGroups groupTasks(List<Task> tasks, DateTime now) {
  final overdue = <Task>[];
  final today = <Task>[];
  final upcoming = <Task>[];
  final noDate = <Task>[];
  final done = <Task>[];

  for (final task in tasks) {
    if (task.isCompleted) {
      done.add(task);
      continue;
    }
    final due = task.dueAt;
    if (due == null) {
      noDate.add(task);
    } else if (isBeforeToday(due, now)) {
      overdue.add(task);
    } else if (isSameDay(due, now)) {
      today.add(task);
    } else {
      upcoming.add(task);
    }
  }

  overdue.sort(_byDue);
  today.sort(_byDue);
  upcoming.sort(_byDue);
  noDate.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  done.sort(
    (a, b) => (b.completedAt ?? b.createdAt).compareTo(
      a.completedAt ?? a.createdAt,
    ),
  );

  return TaskGroups(
    overdue: overdue,
    today: today,
    upcoming: upcoming,
    noDate: noDate,
    done: done,
  );
}

int _byDue(Task a, Task b) {
  final aDue = a.dueAt;
  final bDue = b.dueAt;
  if (aDue == null && bDue == null) {
    return b.createdAt.compareTo(a.createdAt);
  }
  if (aDue == null) {
    return 1;
  }
  if (bDue == null) {
    return -1;
  }
  return aDue.compareTo(bDue);
}
