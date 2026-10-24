import 'package:clearday/core/constants/app_constants.dart';
import 'package:clearday/core/date_utils.dart';
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

      await appNotifier(
        container,
      ).toggleCompleted(taskNamed(container, 'Wipe counters').id);

      final task = taskNamed(container, 'Wipe counters');
      expect(task.isCompleted, isTrue);
      expect(task.completedAt, isNotNull);
    });

    test('completed tasks do not count toward the active limit', () async {
      final container = await createTestContainer();
      await addNamedTask(container, title: 'Done chore');
      await appNotifier(
        container,
      ).toggleCompleted(taskNamed(container, 'Done chore').id);

      expect(container.read(appDataProvider).activeTaskCount, 0);
    });

    test('deletes a task', () async {
      final container = await createTestContainer();
      await addNamedTask(container, title: 'Old chore');

      await appNotifier(
        container,
      ).deleteTask(taskNamed(container, 'Old chore').id);

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

    test(
      'free users cannot reopen a done task when 25 are already active',
      () async {
        final container = await createTestContainer();
        final notifier = appNotifier(container);
        final homeId = defaultHomeGroup(container).id;

        await addNamedTask(container, title: 'Finished', groupId: homeId);
        final finished = taskNamed(container, 'Finished');
        await notifier.toggleCompleted(finished.id);

        for (var i = 0; i < AppConstants.freeActiveTaskLimit; i++) {
          final result = await addNamedTask(
            container,
            title: 'Task $i',
            groupId: homeId,
          );
          expect(result, SaveTaskResult.saved);
        }

        final blocked = await notifier.toggleCompleted(finished.id);
        final undone = await notifier.restoreTask(finished);

        expect(blocked, SaveTaskResult.blockedByTaskLimit);
        expect(undone, SaveTaskResult.blockedByTaskLimit);
        expect(taskNamed(container, 'Finished').isCompleted, isTrue);
        expect(
          container.read(appDataProvider).activeTaskCount,
          AppConstants.freeActiveTaskLimit,
        );
      },
    );

    test('quick add saves a trimmed task due today in that group', () async {
      final container = await createTestContainer();
      final home = defaultHomeGroup(container);
      final workout = await addNamedGroup(container, 'Workout');

      final result = await appNotifier(
        container,
      ).quickAddTask(title: '  Run  ', groupId: workout.id);

      expect(result, SaveTaskResult.saved);
      final task = taskNamed(container, 'Run');
      final now = DateTime.now();
      expect(task.groupId, workout.id);
      expect(task.dueAt, DateTime(now.year, now.month, now.day));
      expect(task.reminderAt?.hour, AppConstants.defaultReminderHour);
      expect(container.read(appDataProvider).selectedGroupId, workout.id);
      expect(home.id, isNot(workout.id));
    });

    test('quick add ignores a blank title', () async {
      final container = await createTestContainer();
      final home = defaultHomeGroup(container);

      final result = await appNotifier(
        container,
      ).quickAddTask(title: '   ', groupId: home.id);

      expect(result, SaveTaskResult.saved);
      expect(tasksOf(container), isEmpty);
    });

    test('undo puts a completed task back', () async {
      final container = await createTestContainer();
      await addNamedTask(container, title: 'Wipe counters');
      final before = taskNamed(container, 'Wipe counters');

      await appNotifier(container).toggleCompleted(before.id);
      await appNotifier(container).restoreTask(before);

      final task = taskNamed(container, 'Wipe counters');
      expect(task.isCompleted, isFalse);
      expect(task.completedAt, isNull);
    });

    test('clear completed removes done tasks in that group only', () async {
      final container = await createTestContainer();
      final home = defaultHomeGroup(container);
      final workout = await addNamedGroup(container, 'Workout');
      await addNamedTask(container, title: 'Vacuum', groupId: home.id);
      await addNamedTask(container, title: 'Mop', groupId: home.id);
      await addNamedTask(container, title: 'Run', groupId: workout.id);
      await appNotifier(
        container,
      ).toggleCompleted(taskNamed(container, 'Vacuum').id);
      await appNotifier(
        container,
      ).toggleCompleted(taskNamed(container, 'Run').id);

      await appNotifier(container).clearCompletedInGroup(home.id);

      expect(tasksOf(container).map((task) => task.title), ['Mop', 'Run']);
    });

    test(
      'move to tomorrow saves and undo restores the previous due date',
      () async {
        final container = await createTestContainer();
        await addNamedTask(
          container,
          title: 'Bins',
          dueAt: DateTime(2026, 1, 1),
        );
        final before = taskNamed(container, 'Bins');

        final changed = await appNotifier(
          container,
        ).moveDueToTomorrow(before.id);

        expect(changed, isTrue);
        final moved = taskNamed(container, 'Bins');
        final tomorrow = dateOnly(DateTime.now()).add(const Duration(days: 1));
        expect(dateOnly(moved.dueAt!), tomorrow);
        expect(moved.dueHasTime, isFalse);
        expect(moved.reminderAt?.hour, AppConstants.defaultReminderHour);

        await appNotifier(container).restoreTask(before);
        expect(taskNamed(container, 'Bins').dueAt, before.dueAt);
      },
    );

    test(
      'move to tomorrow does nothing when it is already due tomorrow',
      () async {
        final container = await createTestContainer();
        final tomorrow = dateOnly(DateTime.now()).add(const Duration(days: 1));
        await addNamedTask(container, title: 'Bins', dueAt: tomorrow);
        final before = taskNamed(container, 'Bins');

        final changed = await appNotifier(
          container,
        ).moveDueToTomorrow(before.id);

        expect(changed, isFalse);
        expect(taskNamed(container, 'Bins').dueAt, before.dueAt);
      },
    );

    test('moves overdue tasks to today and undo restores them', () async {
      final container = await createTestContainer();
      final home = defaultHomeGroup(container);
      final workout = await addNamedGroup(container, 'Workout');
      final today = dateOnly(DateTime.now());
      await addNamedTask(
        container,
        title: 'Old',
        groupId: home.id,
        dueAt: DateTime(2026, 1, 1, 15, 30),
        dueHasTime: true,
      );
      await addNamedTask(
        container,
        title: 'Run',
        groupId: workout.id,
        dueAt: DateTime(2026, 1, 2),
      );
      await addNamedTask(
        container,
        title: 'Already today',
        groupId: home.id,
        dueAt: today,
      );

      final previous = await appNotifier(
        container,
      ).moveOverdueToToday(groupId: home.id);

      expect(previous.map((task) => task.title), ['Old']);
      final moved = taskNamed(container, 'Old');
      expect(dateOnly(moved.dueAt!), today);
      expect(moved.dueAt!.hour, 15);
      expect(moved.dueAt!.minute, 30);
      expect(moved.reminderAt, moved.dueAt);
      expect(taskNamed(container, 'Run').dueAt, DateTime(2026, 1, 2));

      await appNotifier(container).restoreTasks(previous);
      expect(taskNamed(container, 'Old').dueAt, DateTime(2026, 1, 1, 15, 30));
    });
  });
}
