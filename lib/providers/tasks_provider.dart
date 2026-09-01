import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/date_utils.dart';
import '../models/app_data.dart';
import '../models/recurrence.dart';
import '../models/task.dart';
import '../models/task_group.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';
import 'pro_provider.dart';
import 'settings_provider.dart';

enum SaveTaskResult { saved, blockedByTaskLimit, blockedByGroupLimit }

final appDataProvider = StateNotifierProvider<AppDataNotifier, AppData>((ref) {
  return AppDataNotifier(
    ref.watch(storageServiceProvider),
    ref.watch(notificationServiceProvider),
    ref,
  );
});

final selectedGroupProvider = Provider<TaskGroup?>((ref) {
  return ref.watch(appDataProvider).selectedGroup;
});

final groupsProvider = Provider<List<TaskGroup>>((ref) {
  return ref.watch(appDataProvider).groups;
});

class AppDataNotifier extends StateNotifier<AppData> {
  AppDataNotifier(this._storage, this._notifications, this._ref)
      : super(_storage.loadAppData()) {
    _persist();
    _syncReminders();
  }

  final StorageService _storage;
  final NotificationService _notifications;
  final Ref _ref;
  static const _uuid = Uuid();

  bool get isPro => _ref.read(proProvider).isPro;

  bool get canAddTask =>
      isPro || state.activeTaskCount < AppConstants.freeActiveTaskLimit;

  bool get canAddGroup =>
      isPro || state.topLevelGroupCount < AppConstants.freeGroupLimit;

  bool get canAddSubgroup =>
      isPro || state.subgroupCount < AppConstants.freeSubgroupLimit;

  int get remainingFreeTasks {
    if (isPro) {
      return AppConstants.freeActiveTaskLimit;
    }
    final remaining =
        AppConstants.freeActiveTaskLimit - state.activeTaskCount;
    return remaining < 0 ? 0 : remaining;
  }

  Future<void> selectGroup(String groupId) async {
    state = state.copyWith(selectedGroupId: groupId);
    await _persist();
  }

  Future<SaveTaskResult> addGroup(String name, {String? parentId}) async {
    if (parentId == null) {
      if (!canAddGroup) {
        return SaveTaskResult.blockedByGroupLimit;
      }
    } else {
      if (!canAddSubgroup) {
        return SaveTaskResult.blockedByGroupLimit;
      }
      final parent = state.groupById(parentId);
      if (parent == null) {
        return SaveTaskResult.blockedByGroupLimit;
      }
    }
    final group = TaskGroup(
      id: _uuid.v4(),
      name: name.trim().isEmpty ? 'Group' : name.trim(),
      createdAt: DateTime.now(),
      parentId: parentId,
    );
    state = state.copyWith(
      groups: [...state.groups, group],
      selectedGroupId: group.id,
    );
    await _persist();
    return SaveTaskResult.saved;
  }

  Future<void> renameGroup(String groupId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final groups = state.groups
        .map(
          (group) => group.id == groupId ? group.copyWith(name: trimmed) : group,
        )
        .toList();
    state = state.copyWith(groups: groups);
    await _persist();
  }

  Future<void> deleteGroup(String groupId) async {
    final ids = state.descendantGroupIds(groupId);
    final groups =
        state.groups.where((group) => !ids.contains(group.id)).toList();
    final tasks =
        state.tasks.where((task) => !ids.contains(task.groupId)).toList();
    final selectedId = ids.contains(state.selectedGroupId)
        ? (groups.isNotEmpty ? groups.first.id : '')
        : state.selectedGroupId;
    state = AppData(
      groups: groups,
      tasks: tasks,
      selectedGroupId: selectedId,
    );
    await _persist();
    await _syncReminders();
  }

  Future<SaveTaskResult> upsertTask(Task task, {required bool isNew}) async {
    if (isNew && !canAddTask) {
      return SaveTaskResult.blockedByTaskLimit;
    }

    var toSave = _applyFreeReminderRules(task);
    if (!isPro) {
      toSave = toSave.copyWith(recurrence: const Recurrence());
    }

    final tasks = [...state.tasks];
    final index = tasks.indexWhere((item) => item.id == toSave.id);
    if (index >= 0) {
      tasks[index] = toSave;
    } else {
      tasks.add(toSave);
    }

    state = state.copyWith(tasks: tasks);
    await _persist();
    await _maybeRequestNotifications(toSave);
    await _syncReminders();
    return SaveTaskResult.saved;
  }

  Future<void> toggleCompleted(String taskId) async {
    final index = state.tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) {
      return;
    }

    final task = state.tasks[index];
    if (task.isCompleted) {
      await _setCompleted(task, completed: false);
      return;
    }

    await _setCompleted(task, completed: true);
    if (isPro && task.recurrence.isEnabled) {
      await _spawnNextOccurrence(task);
    }
  }

  Future<void> resyncReminders() async {
    await _syncReminders();
  }

  Future<void> deleteTask(String taskId) async {
    state = state.copyWith(
      tasks: state.tasks.where((task) => task.id != taskId).toList(),
    );
    await _persist();
    await _syncReminders();
  }

  DateTime? defaultReminderFor({
    required DateTime? dueAt,
    required bool dueHasTime,
  }) {
    if (dueAt == null) {
      return null;
    }
    if (dueHasTime) {
      return dueAt;
    }
    return DateTime(
      dueAt.year,
      dueAt.month,
      dueAt.day,
      AppConstants.defaultReminderHour,
    );
  }

  Task newTaskDraft({required String groupId}) {
    final now = DateTime.now();
    return Task(
      id: _uuid.v4(),
      groupId: groupId,
      title: '',
      createdAt: now,
    );
  }

  Future<void> _setCompleted(Task task, {required bool completed}) async {
    final updated = task.copyWith(
      isCompleted: completed,
      completedAt: completed ? DateTime.now() : null,
      clearCompletedAt: !completed,
    );
    final tasks = state.tasks
        .map((item) => item.id == task.id ? updated : item)
        .toList();
    state = state.copyWith(tasks: tasks);
    await _persist();
    await _syncReminders();
  }

  Future<void> _spawnNextOccurrence(Task completed) async {
    final base = completed.dueAt ?? DateTime.now();
    final nextDue = completed.recurrence.nextDueAfter(base);
    final offset = completed.dueAt != null && completed.reminderAt != null
        ? completed.dueAt!.difference(completed.reminderAt!)
        : null;
    final nextReminder = offset == null
        ? defaultReminderFor(
            dueAt: nextDue,
            dueHasTime: completed.dueHasTime,
          )
        : nextDue.subtract(offset);

    final next = Task(
      id: _uuid.v4(),
      groupId: completed.groupId,
      title: completed.title,
      notes: completed.notes,
      dueAt: nextDue,
      dueHasTime: completed.dueHasTime,
      reminderAt: nextReminder,
      recurrence: completed.recurrence,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(tasks: [...state.tasks, next]);
    await _persist();
    await _syncReminders();
  }

  Task _applyFreeReminderRules(Task task) {
    if (isPro) {
      return task;
    }
    return task.copyWith(
      reminderAt: defaultReminderFor(
        dueAt: task.dueAt,
        dueHasTime: task.dueHasTime,
      ),
      clearReminderAt: task.dueAt == null,
    );
  }

  Future<void> _maybeRequestNotifications(Task task) async {
    if (task.reminderAt == null) {
      return;
    }
    if (!_ref.read(settingsProvider).notificationsEnabled) {
      return;
    }
    await _notifications.requestPermission();
  }

  Future<void> _persist() async {
    await _storage.saveAppData(state);
  }

  Future<void> _syncReminders() async {
    if (!_ref.read(settingsProvider).notificationsEnabled) {
      await _notifications.syncTaskReminders(const []);
      return;
    }
    await _notifications.syncTaskReminders(state.tasks);
  }
}

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

  int byDue(Task a, Task b) {
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

  overdue.sort(byDue);
  today.sort(byDue);
  upcoming.sort(byDue);
  noDate.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  done.sort((a, b) => (b.completedAt ?? b.createdAt)
      .compareTo(a.completedAt ?? a.createdAt));

  return TaskGroups(
    overdue: overdue,
    today: today,
    upcoming: upcoming,
    noDate: noDate,
    done: done,
  );
}
