import 'package:clearday/core/date_utils.dart';
import 'package:clearday/core/task_schedule.dart';
import 'package:clearday/models/recurrence.dart';
import 'package:clearday/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 17, 12);

  Task task({
    String id = '1',
    String groupId = 'home',
    DateTime? dueAt,
    bool dueHasTime = false,
    DateTime? reminderAt,
    bool completed = false,
  }) {
    return Task(
      id: id,
      groupId: groupId,
      title: 'Call',
      createdAt: DateTime(2026, 8, 1),
      dueAt: dueAt,
      dueHasTime: dueHasTime,
      reminderAt: reminderAt,
      isCompleted: completed,
    );
  }

  test('keeps the clock time and the reminder gap', () {
    final due = DateTime(2026, 8, 15, 15, 30);
    final moved = taskMovedToTomorrow(
      task(
        dueAt: due,
        dueHasTime: true,
        reminderAt: due.subtract(const Duration(hours: 1)),
      ),
      now,
    );

    expect(moved, isNotNull);
    expect(moved!.dueAt, DateTime(2026, 8, 18, 15, 30));
    expect(moved.dueHasTime, isTrue);
    expect(moved.reminderAt, DateTime(2026, 8, 18, 14, 30));
  });

  test('puts a task with no date on tomorrow', () {
    final moved = taskMovedToTomorrow(task(), now);

    expect(moved!.dueAt, DateTime(2026, 8, 18));
    expect(moved.dueHasTime, isFalse);
    expect(moved.reminderAt, isNull);
  });

  test('leaves a task that is already due tomorrow', () {
    expect(
      taskMovedToTomorrow(task(dueAt: DateTime(2026, 8, 18, 9)), now),
      isNull,
    );
    expect(
      taskMovedToTomorrow(
        task(dueAt: DateTime(2026, 8, 18, 15, 30), dueHasTime: true),
        now,
      ),
      isNull,
    );
  });

  test('leaves a completed task', () {
    expect(
      taskMovedToTomorrow(
        task(dueAt: DateTime(2026, 8, 16), completed: true),
        now,
      ),
      isNull,
    );
  });

  test('moves overdue tasks to today and can limit that to one group', () {
    final overdue = DateTime(2026, 8, 15, 15, 30);
    final tasks = [
      task(
        id: 'old',
        dueAt: overdue,
        dueHasTime: true,
        reminderAt: overdue.subtract(const Duration(hours: 1)),
      ),
      task(id: 'today', dueAt: DateTime(2026, 8, 17)),
      task(id: 'work', groupId: 'work', dueAt: DateTime(2026, 8, 10)),
    ];

    final all = planOverdueMoveToToday(tasks, now);
    expect(all.previous.map((item) => item.id), ['old', 'work']);
    final movedOld = all.tasks.firstWhere((item) => item.id == 'old');
    expect(movedOld.dueAt, DateTime(2026, 8, 17, 15, 30));
    expect(movedOld.reminderAt, DateTime(2026, 8, 17, 14, 30));
    expect(
      all.tasks.firstWhere((item) => item.id == 'today').dueAt,
      DateTime(2026, 8, 17),
    );

    final homeOnly = planOverdueMoveToToday(tasks, now, groupId: 'home');
    expect(homeOnly.previous.map((item) => item.id), ['old']);
    expect(
      homeOnly.tasks.firstWhere((item) => item.id == 'work').dueAt,
      DateTime(2026, 8, 10),
    );
  });

  test('an undated repeat gets today as its first due date', () {
    const repeat = Recurrence(
      kind: RecurrenceKind.everyNDays,
      intervalDays: 5,
    );
    final prepared = prepareRecurringTask(
      task().copyWith(recurrence: repeat),
      now,
    );

    expect(prepared.dueAt, dateOnly(now));
    expect(prepared.dueHasTime, isFalse);
    expect(prepared.isCompleted, isFalse);
  });

  test('a finished repeat stays done until its next date', () {
    const repeat = Recurrence(
      kind: RecurrenceKind.weekly,
      weekdays: [DateTime.monday],
    );
    final waiting = task(
      dueAt: DateTime(2026, 8, 24),
      completed: true,
    ).copyWith(recurrence: repeat);

    expect(isWaitingToRepeat(waiting, now), isTrue);
    expect(identical(prepareRecurringTask(waiting, now), waiting), isTrue);
  });

  test('a finished repeat reopens when its next date is today', () {
    const repeat = Recurrence(
      kind: RecurrenceKind.everyNDays,
      intervalDays: 3,
    );
    final prepared = prepareRecurringTask(
      task(
        dueAt: DateTime(2026, 8, 17, 9),
        completed: true,
      ).copyWith(recurrence: repeat),
      now,
    );

    expect(prepared.isCompleted, isFalse);
    expect(prepared.completedAt, isNull);
  });
}
