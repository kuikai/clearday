import 'package:clearday/core/constants/app_constants.dart';
import 'package:clearday/providers/pro_provider.dart';
import 'package:clearday/providers/tasks_provider.dart';
import 'package:clearday/services/revenue_cat_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pro status', () {
    test('starts as free and enforces group and task limits', () async {
      final container = await createTestContainer();
      final notifier = appNotifier(container);

      expect(container.read(proProvider).isPro, isFalse);
      expect(notifier.canAddGroup, isTrue);

      await addNamedGroup(container, 'Workout');
      expect(notifier.canAddGroup, isFalse);
      expect(
        await notifier.addGroup('Work'),
        SaveTaskResult.blockedByGroupLimit,
      );
    });

    test('purchase is unavailable when RevenueCat is not configured', () async {
      final container = await createTestContainer();

      final result = await container.read(proProvider.notifier).purchasePro();

      expect(result, isA<PurchaseActionFailure>());
      expect(container.read(proProvider).isPro, isFalse);
    });

    test('Pro allows more than 2 groups', () async {
      final container = await createTestContainer(isPro: true);
      final notifier = appNotifier(container);

      expect(container.read(proProvider).isPro, isTrue);

      await addNamedGroup(container, 'Workout');
      final third = await notifier.addGroup('Work');

      expect(third, SaveTaskResult.saved);
      expect(groupsOf(container).length, greaterThan(AppConstants.freeGroupLimit));
    });

    test('Pro allows more than 25 active tasks', () async {
      final container = await createTestContainer(isPro: true);
      final homeId = defaultHomeGroup(container).id;

      for (var i = 0; i < AppConstants.freeActiveTaskLimit; i++) {
        await addNamedTask(container, title: 'Task $i', groupId: homeId);
      }

      final extra = await addNamedTask(
        container,
        title: 'Pro extra task',
        groupId: homeId,
      );

      expect(extra, SaveTaskResult.saved);
      expect(
        container.read(appDataProvider).activeTaskCount,
        AppConstants.freeActiveTaskLimit + 1,
      );
    });

    test('resetting Pro restores free limits', () async {
      final container = await createTestContainer(isPro: true);
      await addNamedGroup(container, 'Workout');
      await addNamedGroup(container, 'Work');

      await container.read(proProvider.notifier).resetProForTesting();

      expect(container.read(proProvider).isPro, isFalse);
      expect(appNotifier(container).canAddGroup, isFalse);
    });
  });
}
