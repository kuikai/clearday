import 'package:clearday/models/recurrence.dart';
import 'package:clearday/providers/tasks_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Recurring tasks', () {
    test('Pro: completing a recurring task creates the next occurrence', () async {
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

      await appNotifier(container).toggleCompleted(
        taskNamed(container, 'Water plants').id,
      );

      final tasks = tasksOf(container);
      expect(tasks, hasLength(2));

      final completed = tasks.singleWhere((task) => task.isCompleted);
      final next = tasks.singleWhere((task) => !task.isCompleted);

      expect(completed.title, 'Water plants');
      expect(next.title, 'Water plants');
      expect(next.recurrence.kind, RecurrenceKind.everyNDays);
      expect(next.dueAt, DateTime(2026, 8, 22, 9));
      expect(next.groupId, completed.groupId);
    });

    test('free: recurrence is stripped on save and no next task is spawned',
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
