import 'package:clearday/models/recurrence.dart';
import 'package:clearday/providers/tasks_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Recurring tasks', () {
    test('Pro: completing a recurring task keeps one task done until next due',
        () async {
      final container = await createTestContainer(isPro: true);
      final due = DateTime.now().add(const Duration(days: 1));
      final dueDay = DateTime(due.year, due.month, due.day, 9);

      await addNamedTask(
        container,
        title: 'Water plants',
        dueAt: dueDay,
        dueHasTime: true,
        recurrence: const Recurrence(
          kind: RecurrenceKind.everyNDays,
          intervalDays: 5,
        ),
      );

      await appNotifier(container).toggleCompleted(
        taskNamed(container, 'Water plants').id,
      );

      final tasks = tasksOf(container);
      expect(tasks, hasLength(1));

      final task = tasks.single;
      expect(task.isCompleted, isTrue);
      expect(task.title, 'Water plants');
      expect(task.dueAt, dueDay.add(const Duration(days: 5)));
      expect(task.recurrence.kind, RecurrenceKind.everyNDays);
    });

    test('Pro: reactivation opens the same task when next due arrives',
        () async {
      final container = await createTestContainer(isPro: true);
      final due = DateTime(2026, 8, 17, 9);

      await addNamedTask(
        container,
        title: 'Water plants',
        dueAt: due,
        dueHasTime: true,
        recurrence: const Recurrence(
          kind: RecurrenceKind.everyNDays,
          intervalDays: 5,
        ),
      );

      final taskId = taskNamed(container, 'Water plants').id;
      await appNotifier(container).toggleCompleted(taskId);

      // Simulate that the next due day has arrived.
      final scheduled = taskNamed(container, 'Water plants');
      await appNotifier(container).upsertTask(
        scheduled.copyWith(
          dueAt: DateTime.now(),
          dueHasTime: true,
          isCompleted: true,
          completedAt: DateTime.now(),
        ),
        isNew: false,
      );

      await appNotifier(container).reactivateRecurringTasks();

      final reopened = taskNamed(container, 'Water plants');
      expect(reopened.isCompleted, isFalse);
      expect(tasksOf(container), hasLength(1));
    });

    test('Pro: overdue complete schedules next due from now, not old due',
        () async {
      final container = await createTestContainer(isPro: true);
      final overdueDue = DateTime(2026, 1, 1, 9);

      await addNamedTask(
        container,
        title: 'Water plants',
        dueAt: overdueDue,
        dueHasTime: true,
        recurrence: const Recurrence(
          kind: RecurrenceKind.everyNDays,
          intervalDays: 5,
        ),
      );

      await appNotifier(container).toggleCompleted(
        taskNamed(container, 'Water plants').id,
      );

      final task = taskNamed(container, 'Water plants');
      expect(task.isCompleted, isTrue);
      expect(task.dueAt!.isAfter(DateTime.now()), isTrue);
    });

    test('free: recurrence is stripped on save and stays a single done task',
        () async {
      final container = await createTestContainer();
      final due = DateTime(2026, 8, 17, 9);

      await addNamedTask(
        container,
        title: 'Water plants',
        dueAt: due,
        dueHasTime: true,
        recurrence: const Recurrence(
          kind: RecurrenceKind.everyNDays,
          intervalDays: 5,
        ),
      );

      expect(taskNamed(container, 'Water plants').recurrence.isEnabled, isFalse);

      await appNotifier(container).toggleCompleted(
        taskNamed(container, 'Water plants').id,
      );

      expect(tasksOf(container), hasLength(1));
      expect(tasksOf(container).single.isCompleted, isTrue);
    });
  });
}
