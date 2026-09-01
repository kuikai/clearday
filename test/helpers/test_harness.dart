import 'package:clearday/models/recurrence.dart';
import 'package:clearday/models/task.dart';
import 'package:clearday/models/task_group.dart';
import 'package:clearday/providers/app_providers.dart';
import 'package:clearday/providers/pro_provider.dart';
import 'package:clearday/providers/tasks_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_notification_service.dart';
import 'fake_revenue_cat_service.dart';

/// Builds an isolated app container with fake prefs, notifications, and purchases.
Future<ProviderContainer> createTestContainer({
  bool isPro = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
      revenueCatServiceProvider.overrideWithValue(FakeRevenueCatService()),
    ],
  );
  addTearDown(container.dispose);

  if (isPro) {
    await container.read(proProvider.notifier).unlockProForTesting();
  }

  return container;
}

AppDataNotifier appNotifier(ProviderContainer container) {
  return container.read(appDataProvider.notifier);
}

List<TaskGroup> groupsOf(ProviderContainer container) {
  return container.read(appDataProvider).groups;
}

List<Task> tasksOf(ProviderContainer container) {
  return container.read(appDataProvider).tasks;
}

TaskGroup defaultHomeGroup(ProviderContainer container) {
  return groupsOf(container).first;
}

Future<TaskGroup> addNamedGroup(
  ProviderContainer container,
  String name, {
  String? parentId,
}) async {
  final result = await appNotifier(container).addGroup(
    name,
    parentId: parentId,
  );
  expect(result, SaveTaskResult.saved, reason: 'Expected "$name" to be created');
  return groupsOf(container).lastWhere((group) => group.name == name);
}

Future<SaveTaskResult> addNamedTask(
  ProviderContainer container, {
  required String title,
  String? groupId,
  Recurrence recurrence = const Recurrence(),
  DateTime? dueAt,
  bool dueHasTime = false,
}) {
  final notifier = appNotifier(container);
  final targetGroupId = groupId ?? defaultHomeGroup(container).id;
  final draft = notifier.newTaskDraft(groupId: targetGroupId);
  return notifier.upsertTask(
    draft.copyWith(
      title: title,
      recurrence: recurrence,
      dueAt: dueAt,
      dueHasTime: dueHasTime,
    ),
    isNew: true,
  );
}

Task taskNamed(ProviderContainer container, String title) {
  return tasksOf(container).firstWhere((task) => task.title == title);
}
