import 'package:clearday/core/constants/app_constants.dart';
import 'package:clearday/providers/tasks_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Groups', () {
    test('seeds a default Home group on first launch', () async {
      final container = await createTestContainer();

      final groups = groupsOf(container);
      expect(groups, hasLength(1));
      expect(groups.first.name, AppConstants.defaultGroupName);
    });

    test('creates a group', () async {
      final container = await createTestContainer();

      final workout = await addNamedGroup(container, 'Workout');

      expect(groupsOf(container), hasLength(2));
      expect(workout.name, 'Workout');
      expect(workout.isTopLevel, isTrue);
    });

    test('renames a group', () async {
      final container = await createTestContainer();
      final home = defaultHomeGroup(container);

      await appNotifier(container).renameGroup(home.id, 'House Work');

      expect(groupsOf(container).single.name, 'House Work');
    });

    test('does not rename a group to a blank name', () async {
      final container = await createTestContainer();
      final home = defaultHomeGroup(container);

      await appNotifier(container).renameGroup(home.id, '   ');

      expect(groupsOf(container).single.name, AppConstants.defaultGroupName);
    });

    test('deletes a group and its tasks', () async {
      final container = await createTestContainer();
      final home = defaultHomeGroup(container);
      final workout = await addNamedGroup(container, 'Workout');
      await addNamedTask(container, title: 'Vacuum', groupId: home.id);
      await addNamedTask(container, title: 'Run', groupId: workout.id);

      await appNotifier(container).deleteGroup(workout.id);

      expect(groupsOf(container).map((group) => group.name), ['Home']);
      expect(tasksOf(container).map((task) => task.title), ['Vacuum']);
    });

    test('deleting a parent group also deletes its subgroups', () async {
      final container = await createTestContainer();
      final home = defaultHomeGroup(container);
      await addNamedGroup(container, 'Kitchen', parentId: home.id);

      await appNotifier(container).deleteGroup(home.id);

      expect(groupsOf(container), isEmpty);
    });

    test('free users cannot create more than 2 top-level groups', () async {
      final container = await createTestContainer();
      await addNamedGroup(container, 'Workout');

      final result = await appNotifier(container).addGroup('Work');

      expect(result, SaveTaskResult.blockedByGroupLimit);
      expect(
        container.read(appDataProvider).topLevelGroupCount,
        AppConstants.freeGroupLimit,
      );
    });

    test('free users can add a subgroup under Kitchen', () async {
      final container = await createTestContainer();
      final home = defaultHomeGroup(container);
      final kitchen = await addNamedGroup(
        container,
        'Kitchen',
        parentId: home.id,
      );

      final result = await appNotifier(container).addGroup(
        'Sink',
        parentId: kitchen.id,
      );

      expect(result, SaveTaskResult.saved);
      expect(
        container.read(appDataProvider).subgroupsOf(kitchen.id).single.name,
        'Sink',
      );
    });

    test('free users can add up to 3 subgroups', () async {
      final container = await createTestContainer();
      final home = defaultHomeGroup(container);

      for (var i = 0; i < AppConstants.freeSubgroupLimit; i++) {
        final result = await appNotifier(container).addGroup(
          'Room $i',
          parentId: home.id,
        );
        expect(result, SaveTaskResult.saved);
      }

      final blocked = await appNotifier(container).addGroup(
        'One more',
        parentId: home.id,
      );
      expect(blocked, SaveTaskResult.blockedByGroupLimit);
      expect(
        container.read(appDataProvider).subgroupCount,
        AppConstants.freeSubgroupLimit,
      );
    });
  });
}
