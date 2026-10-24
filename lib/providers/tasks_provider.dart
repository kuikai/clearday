import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/date_utils.dart';
import '../core/task_schedule.dart';
import '../models/app_data.dart';
import '../models/recurrence.dart';
import '../models/task.dart';
import '../models/task_group.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';
import 'pro_provider.dart';
import 'settings_provider.dart';

export '../core/group_tasks.dart';

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
    if (!_storage.loadCorrupt) {
      _persist();
    }
    Future.microtask(_reactivateRecurringTasks);
    _syncReminders();
  }

  final StorageService _storage;
  final NotificationService _notifications;
  final Ref _ref;
  static const _uuid = Uuid();
  Future<void> _persistChain = Future<void>.value();
  Future<void> _reminderSync = Future<void>.value();

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
    final remaining = AppConstants.freeActiveTaskLimit - state.activeTaskCount;
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
          (group) =>
              group.id == groupId ? group.copyWith(name: trimmed) : group,
        )
        .toList();
    state = state.copyWith(groups: groups);
    await _persist();
  }

  /// Duplicates a group (and nested subgroups) plus its tasks as fresh copies.
  Future<SaveTaskResult> copyGroup(String groupId) async {
    final source = state.groupById(groupId);
    if (source == null) {
      return SaveTaskResult.saved;
    }

    final sourceIds = state.descendantGroupIds(groupId);
    final nestedSubgroupCount = sourceIds.length - 1;

    if (source.isTopLevel) {
      if (!canAddGroup) {
        return SaveTaskResult.blockedByGroupLimit;
      }
      if (!isPro &&
          state.subgroupCount + nestedSubgroupCount >
              AppConstants.freeSubgroupLimit) {
        return SaveTaskResult.blockedByGroupLimit;
      }
    } else {
      if (!isPro &&
          state.subgroupCount + sourceIds.length >
              AppConstants.freeSubgroupLimit) {
        return SaveTaskResult.blockedByGroupLimit;
      }
    }

    final tasksToCopy = state.tasks
        .where((task) => sourceIds.contains(task.groupId))
        .toList();
    if (!isPro &&
        state.activeTaskCount + tasksToCopy.length >
            AppConstants.freeActiveTaskLimit) {
      return SaveTaskResult.blockedByTaskLimit;
    }

    final now = DateTime.now();
    final idMap = <String, String>{for (final id in sourceIds) id: _uuid.v4()};

    final newGroups = <TaskGroup>[];
    final visited = <String>{};
    void addBranch(String oldId, String? mappedParentId) {
      if (!visited.add(oldId)) {
        return;
      }
      final old = state.groupById(oldId);
      if (old == null) {
        return;
      }
      final isRoot = oldId == groupId;
      newGroups.add(
        TaskGroup(
          id: idMap[oldId]!,
          name: isRoot ? '${old.name} (copy)' : old.name,
          createdAt: now,
          parentId: isRoot ? old.parentId : mappedParentId,
        ),
      );
      for (final child in state.subgroupsOf(oldId)) {
        addBranch(child.id, idMap[oldId]);
      }
    }

    addBranch(groupId, null);

    final newTasks = tasksToCopy.map((task) {
      final copied = Task(
        id: _uuid.v4(),
        groupId: idMap[task.groupId]!,
        title: task.title,
        notes: task.notes,
        dueAt: task.dueAt,
        dueHasTime: task.dueHasTime,
        reminderAt: task.reminderAt,
        isCompleted: false,
        recurrence: isPro ? task.recurrence : const Recurrence(),
        createdAt: now,
      );
      return _applyFreeReminderRules(copied);
    }).toList();

    state = state.copyWith(
      groups: [...state.groups, ...newGroups],
      tasks: [...state.tasks, ...newTasks],
      selectedGroupId: idMap[groupId],
    );
    await _persist();
    await _syncReminders();
    return SaveTaskResult.saved;
  }

  Future<void> deleteGroup(String groupId) async {
    final ids = state.descendantGroupIds(groupId);
    final groups = state.groups
        .where((group) => !ids.contains(group.id))
        .toList();
    final tasks = state.tasks
        .where((task) => !ids.contains(task.groupId))
        .toList();
    final selectedId = ids.contains(state.selectedGroupId)
        ? (groups.isNotEmpty ? groups.first.id : '')
        : state.selectedGroupId;
    state = AppData(groups: groups, tasks: tasks, selectedGroupId: selectedId);
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
    toSave = taskWithFirstRepeatDue(toSave, DateTime.now());

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

  Future<SaveTaskResult> toggleCompleted(String taskId) async {
    await _reactivateRecurringTasks();

    final index = state.tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) {
      return SaveTaskResult.saved;
    }

    final task = state.tasks[index];
    if (task.isCompleted) {
      if (_restoreExceedsActiveLimit([_reopened(task)])) {
        return SaveTaskResult.blockedByTaskLimit;
      }
      await _setCompleted(task, completed: false);
      return SaveTaskResult.saved;
    }

    if (isPro && task.recurrence.isEnabled) {
      await _completeRecurringTask(task);
      return SaveTaskResult.saved;
    }

    await _setCompleted(task, completed: true);
    return SaveTaskResult.saved;
  }

  Future<void> resyncReminders() async {
    await _reactivateRecurringTasks();
    await _syncReminders();
  }

  Future<void> deleteTask(String taskId) async {
    state = state.copyWith(
      tasks: state.tasks.where((task) => task.id != taskId).toList(),
    );
    await _persist();
    await _syncReminders();
  }

  Future<void> reorderSiblings(
    String? parentId,
    int oldIndex,
    int newIndex,
  ) async {
    final next = state.withSiblingsReordered(parentId, oldIndex, newIndex);
    if (identical(next, state)) return;
    state = next;
    await _persist();
  }

  Future<SaveTaskResult> restoreTask(Task task) => restoreTasks([task]);

  Future<SaveTaskResult> restoreTasks(List<Task> snapshots) async {
    if (snapshots.isEmpty) return SaveTaskResult.saved;
    if (_restoreExceedsActiveLimit(snapshots)) {
      return SaveTaskResult.blockedByTaskLimit;
    }
    final pending = {for (final task in snapshots) task.id: task};
    final tasks = [
      for (final task in state.tasks) pending.remove(task.id) ?? task,
      ...pending.values,
    ];
    state = state.copyWith(tasks: tasks);
    await _persist();
    await _syncReminders();
    return SaveTaskResult.saved;
  }

  Future<void> clearCompletedInGroup(String groupId) async {
    final now = DateTime.now();
    final tasks = [
      for (final task in state.tasks)
        if (task.groupId != groupId ||
            !task.isCompleted ||
            isWaitingToRepeat(task, now))
          task,
    ];
    if (tasks.length == state.tasks.length) return;
    state = state.copyWith(tasks: tasks);
    await _persist();
    await _syncReminders();
  }

  Future<bool> moveDueToTomorrow(String taskId) async {
    final index = state.tasks.indexWhere((task) => task.id == taskId);
    if (index < 0) return false;
    final moved = taskMovedToTomorrow(state.tasks[index], DateTime.now());
    if (moved == null) return false;
    final tasks = [...state.tasks];
    tasks[index] = _applyFreeReminderRules(moved);
    state = state.copyWith(tasks: tasks);
    await _persist();
    await _syncReminders();
    return true;
  }

  Future<List<Task>> moveOverdueToToday({String? groupId}) async {
    final plan = planOverdueMoveToToday(
      state.tasks,
      DateTime.now(),
      groupId: groupId,
    );
    if (plan.previous.isEmpty) return const [];
    state = state.copyWith(
      tasks: tasksWithReminderOnMoved(plan, _applyFreeReminderRules),
    );
    await _persist();
    await _syncReminders();
    return plan.previous;
  }

  Future<SaveTaskResult> quickAddTask({
    required String title,
    required String groupId,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty || state.groupById(groupId) == null) {
      return SaveTaskResult.saved;
    }
    if (!canAddTask) return SaveTaskResult.blockedByTaskLimit;
    state = state.copyWith(selectedGroupId: groupId);
    return upsertTask(
      newTaskDraft(
        groupId: groupId,
        dueAt: dateOnly(DateTime.now()),
      ).copyWith(title: trimmed),
      isNew: true,
    );
  }

  Task newTaskDraft({
    required String groupId,
    DateTime? dueAt,
    bool dueHasTime = false,
  }) {
    final now = DateTime.now();
    return Task(
      id: _uuid.v4(),
      groupId: groupId,
      title: '',
      createdAt: now,
      dueAt: dueAt,
      dueHasTime: dueHasTime,
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

  /// Completes a repeating task. The next due counts from today, and the task
  /// opens again when that day arrives.
  Future<void> _completeRecurringTask(Task task) async {
    final now = DateTime.now();
    final due = task.dueAt;
    final base = task.dueHasTime && due != null
        ? DateTime(now.year, now.month, now.day, due.hour, due.minute)
        : DateTime(now.year, now.month, now.day, 9);
    final nextDue = task.recurrence.nextDueAfter(base);
    final offset = task.dueAt != null && task.reminderAt != null
        ? task.dueAt!.difference(task.reminderAt!)
        : null;
    final nextReminder = offset == null
        ? defaultReminderFor(dueAt: nextDue, dueHasTime: task.dueHasTime)
        : nextDue.subtract(offset);

    final updated = task.copyWith(
      isCompleted: true,
      completedAt: now,
      dueAt: nextDue,
      dueHasTime: task.dueHasTime,
      reminderAt: nextReminder,
      clearReminderAt: nextReminder == null,
    );
    final tasks = state.tasks
        .map((item) => item.id == task.id ? updated : item)
        .toList();
    state = state.copyWith(tasks: tasks);
    await _persist();
    await _syncReminders();
  }

  /// When a done recurring task's next due date is today or past, open it again.
  Future<void> reactivateRecurringTasks() => _reactivateRecurringTasks();

  Future<void> _reactivateRecurringTasks() async {
    final now = DateTime.now();
    var changed = false;
    final tasks = state.tasks.map((task) {
      final next = prepareRecurringTask(task, now);
      if (!identical(next, task)) {
        changed = true;
      }
      return next;
    }).toList();

    if (!changed) {
      return;
    }
    state = state.copyWith(tasks: tasks);
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

  bool _restoreExceedsActiveLimit(List<Task> snapshots) {
    if (isPro) {
      return false;
    }
    final nextActive = activeCountAfterRestore(state.tasks, snapshots);
    return nextActive > state.activeTaskCount &&
        nextActive > AppConstants.freeActiveTaskLimit;
  }

  Task _reopened(Task task) {
    return task.copyWith(isCompleted: false, clearCompletedAt: true);
  }

  /// Queues [state] behind earlier saves so an older snapshot cannot finish last.
  Future<void> _persist() {
    final snapshot = state;
    _persistChain = _persistChain
        .then((_) => _storage.saveAppData(snapshot))
        .catchError((_) {});
    return _persistChain;
  }

  Future<void> _syncReminders() {
    _reminderSync = _reminderSync
        .then((_) async {
          if (!_ref.read(settingsProvider).notificationsEnabled) {
            await _notifications.syncTaskReminders(const []);
            return;
          }
          await _notifications.syncTaskReminders(state.tasks);
        })
        .catchError((_) {});
    return _reminderSync;
  }
}
