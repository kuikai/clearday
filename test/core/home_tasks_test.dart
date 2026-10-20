import 'package:clearday/core/date_utils.dart';
import 'package:clearday/models/app_data.dart';
import 'package:clearday/models/recurrence.dart';
import 'package:clearday/models/task.dart';
import 'package:clearday/models/task_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 17, 12);
  final home = TaskGroup(
    id: 'home',
    name: 'Home',
    createdAt: DateTime(2026, 8, 1),
  );

  Task task({
    required String id,
    DateTime? dueAt,
    bool completed = false,
    DateTime? createdAt,
    Recurrence recurrence = const Recurrence(),
  }) {
    return Task(
      id: id,
      groupId: home.id,
      title: id,
      createdAt: createdAt ?? DateTime(2026, 8, 1),
      dueAt: dueAt,
      isCompleted: completed,
      completedAt: completed ? DateTime(2026, 8, 17) : null,
      recurrence: recurrence,
    );
  }

  AppData dataWith(List<Task> tasks) {
    return AppData(
      groups: [home],
      tasks: tasks,
      selectedGroupId: home.id,
    );
  }

  group('clampToDateRange', () {
    test('keeps a date inside the range', () {
      expect(
        clampToDateRange(
          DateTime(2026, 8, 17, 18),
          firstDate: DateTime(2016, 1, 1),
          lastDate: DateTime(2036, 12, 31),
          now: now,
        ),
        DateTime(2026, 8, 17),
      );
    });

    test('clamps overdue dates older than firstDate so the picker cannot assert',
        () {
      expect(
        clampToDateRange(
          DateTime(2010, 1, 1),
          firstDate: DateTime(2016, 1, 1),
          lastDate: DateTime(2036, 12, 31),
          now: now,
        ),
        DateTime(2016, 1, 1),
      );
    });
  });

  group('isUpcomingWithinDays', () {
    test('includes tomorrow and the day after, not today or later', () {
      expect(isUpcomingWithinDays(DateTime(2026, 8, 17), now), isFalse);
      expect(isUpcomingWithinDays(DateTime(2026, 8, 18), now), isTrue);
      expect(isUpcomingWithinDays(DateTime(2026, 8, 19), now), isTrue);
      expect(isUpcomingWithinDays(DateTime(2026, 8, 20), now), isFalse);
      expect(isUpcomingWithinDays(DateTime(2026, 8, 16), now), isFalse);
    });
  });

  group('upcomingSoonTasks', () {
    test('lists incomplete tasks due after today, soonest first', () {
      final data = dataWith([
        task(id: 'overdue', dueAt: DateTime(2026, 8, 16)),
        task(id: 'today', dueAt: DateTime(2026, 8, 17, 18)),
        task(id: 'tomorrow', dueAt: DateTime(2026, 8, 18)),
        task(id: 'inTwo', dueAt: DateTime(2026, 8, 19, 9)),
        task(id: 'later', dueAt: DateTime(2026, 8, 20)),
        task(id: 'none'),
        task(
          id: 'doneSoon',
          dueAt: DateTime(2026, 8, 18),
          completed: true,
        ),
      ]);

      expect(
        data.upcomingSoonTasks(now).map((item) => item.id),
        ['tomorrow', 'inTwo', 'later'],
      );
    });

    test('sorts by due date then newest created first', () {
      final data = dataWith([
        task(
          id: 'laterSameDay',
          dueAt: DateTime(2026, 8, 18, 18),
          createdAt: DateTime(2026, 8, 2),
        ),
        task(
          id: 'earlierSameDay',
          dueAt: DateTime(2026, 8, 18, 9),
          createdAt: DateTime(2026, 8, 3),
        ),
        task(
          id: 'dayAfter',
          dueAt: DateTime(2026, 8, 19),
          createdAt: DateTime(2026, 8, 4),
        ),
      ]);

      expect(
        data.upcomingSoonTasks(now).map((item) => item.id),
        ['earlierSameDay', 'laterSameDay', 'dayAfter'],
      );
    });
  });

  group('upcoming window and later', () {
    test('splits tomorrow and the next day from everything after', () {
      final data = dataWith([
        task(id: 'tomorrow', dueAt: DateTime(2026, 8, 18)),
        task(id: 'inTwo', dueAt: DateTime(2026, 8, 19)),
        task(id: 'later', dueAt: DateTime(2026, 8, 20)),
        task(id: 'today', dueAt: DateTime(2026, 8, 17)),
      ]);

      expect(
        data.upcomingWindowTasks(now).map((item) => item.id),
        ['tomorrow', 'inTwo'],
      );
      expect(data.laterTasks(now).map((item) => item.id), ['later']);
    });

    test('keeps a finished repeat visible until its next date', () {
      const repeat = Recurrence(
        kind: RecurrenceKind.everyNDays,
        intervalDays: 5,
      );
      final data = dataWith([
        task(
          id: 'soon',
          dueAt: DateTime(2026, 8, 18),
          completed: true,
          recurrence: repeat,
        ),
        task(
          id: 'later',
          dueAt: DateTime(2026, 8, 22),
          completed: true,
          recurrence: repeat,
        ),
        task(
          id: 'doneOnce',
          dueAt: DateTime(2026, 8, 18),
          completed: true,
        ),
      ]);

      expect(data.upcomingWindowTasks(now).map((item) => item.id), ['soon']);
      expect(data.laterTasks(now).map((item) => item.id), ['later']);
    });
  });

  group('group order', () {
    test('moves a top-level group and keeps its subgroups with it', () {
      final createdAt = DateTime(2026, 8, 1);
      final data = AppData(
        groups: [
          TaskGroup(id: 'home', name: 'Home', createdAt: createdAt),
          TaskGroup(
            id: 'kitchen',
            name: 'Kitchen',
            createdAt: createdAt,
            parentId: 'home',
          ),
          TaskGroup(id: 'work', name: 'Work', createdAt: createdAt),
        ],
        tasks: const [],
        selectedGroupId: 'home',
      );

      final moved = data.withSiblingsReordered(null, 0, 1);

      expect(moved.topLevelGroups.map((group) => group.id), ['work', 'home']);
      expect(moved.subgroupsOf('home').map((group) => group.id), ['kitchen']);
      expect(
        moved.groups.map((group) => group.id),
        ['work', 'kitchen', 'home'],
      );
    });

    test('leaves the list alone when the drop does not change order', () {
      final createdAt = DateTime(2026, 8, 1);
      final data = AppData(
        groups: [
          TaskGroup(id: 'home', name: 'Home', createdAt: createdAt),
          TaskGroup(id: 'work', name: 'Work', createdAt: createdAt),
        ],
        tasks: const [],
        selectedGroupId: 'home',
      );

      expect(identical(data.withSiblingsReordered(null, 0, 0), data), isTrue);
    });
  });

  group('preferredGroupId', () {
    test('uses the selected group, then the first group', () {
      final createdAt = DateTime(2026, 8, 1);
      final data = AppData(
        groups: [
          TaskGroup(id: 'home', name: 'Home', createdAt: createdAt),
          TaskGroup(id: 'work', name: 'Work', createdAt: createdAt),
        ],
        tasks: const [],
        selectedGroupId: 'missing',
      );

      expect(data.preferredGroupId, 'home');
      expect(
        data.copyWith(selectedGroupId: 'work').preferredGroupId,
        'work',
      );
    });
  });
}
