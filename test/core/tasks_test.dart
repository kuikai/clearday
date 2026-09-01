import 'package:clearday/core/constants/app_constants.dart';
import 'package:clearday/providers/tasks_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tasks', () {
    test('creates a task inside a group', () async {
      final container = await createTestContainer();
      final home = defaultHomeGroup(container);

      final result = await addNamedTask(
        container,
        title: 'Take out trash',
        groupId: home.id,
      );

      expect(result, SaveTaskResult.saved);
      final task = taskNamed(container, 'Take out trash');
      expect(task.groupId, home.id);
      expect(task.isCompleted, isFalse);
    });

    test('completes a task', () async {
      final container = await createTestContainer();
      await addNamedTask(container, title: 'Wipe counters');

      await appNotifier(container).toggleCompleted(
        taskNamed(container, 'Wipe counters').id,
      );

      final task = taskNamed(container, 'Wipe counters');
      expect(task.isCompleted, isTrue);
      expect(task.completedAt, isNotNull);
    });

    test('completed tasks do not count toward the active limit', () async {
      final container = await createTestContainer();
      await addNamedTask(container, title: 'Done chore');
      await appNotifier(container).toggleCompleted(
        taskNamed(container, 'Done chore').id,
      );

      expect(container.read(appDataProvider).activeTaskCount, 0);
    });

    test('deletes a task', () async {
      final container = await createTestContainer();
      await addNamedTask(container, title: 'Old chore');

      await appNotifier(container).deleteTask(
        taskNamed(container, 'Old chore').id,
      );

      expect(tasksOf(container), isEmpty);
    });

    test('free users cannot create more than 25 active tasks', () async {
      final container = await createTestContainer();
      final notifier = appNotifier(container);
      final homeId = defaultHomeGroup(container).id;

      for (var i = 0; i < AppConstants.freeActiveTaskLimit; i++) {
        final result = await addNamedTask(
          container,
          title: 'Task $i',
          groupId: homeId,
        );
        expect(result, SaveTaskResult.saved);
      }

      final blocked = await addNamedTask(container, title: 'One too many');

      expect(blocked, SaveTaskResult.blockedByTaskLimit);
      expect(
        container.read(appDataProvider).activeTaskCount,
        AppConstants.freeActiveTaskLimit,
      );
      expect(notifier.canAddTask, isFalse);
    });
  });
}
