import '../core/date_utils.dart';
import 'task.dart';
import 'task_group.dart';

/// Local snapshot of groups, tasks, and the last opened group.
class AppData {
  const AppData({
    required this.groups,
    required this.tasks,
    required this.selectedGroupId,
  });

  final List<TaskGroup> groups;
  final List<Task> tasks;
  final String selectedGroupId;

  int get activeTaskCount =>
      tasks.where((task) => !task.isCompleted).length;

  TaskGroup? get selectedGroup {
    for (final group in groups) {
      if (group.id == selectedGroupId) {
        return group;
      }
    }
    return groups.isEmpty ? null : groups.first;
  }

  /// Last opened group, or the first group when that id is gone.
  String? get preferredGroupId {
    if (groupById(selectedGroupId) != null) {
      return selectedGroupId;
    }
    if (topLevelGroups.isNotEmpty) {
      return topLevelGroups.first.id;
    }
    if (groups.isEmpty) {
      return null;
    }
    return groups.first.id;
  }

  int get topLevelGroupCount => topLevelGroups.length;

  int get subgroupCount =>
      groups.where((group) => !group.isTopLevel).length;

  List<TaskGroup> get topLevelGroups {
    return groups.where((group) => group.isTopLevel).toList();
  }

  List<TaskGroup> subgroupsOf(String groupId) {
    return groups.where((group) => group.parentId == groupId).toList();
  }

  Set<String> descendantGroupIds(String groupId) {
    final ids = <String>{groupId};
    var grew = true;
    while (grew) {
      grew = false;
      for (final group in groups) {
        final parentId = group.parentId;
        if (parentId != null && ids.contains(parentId) && ids.add(group.id)) {
          grew = true;
        }
      }
    }
    return ids;
  }

  String groupPath(String groupId) {
    final names = <String>[];
    var current = groupById(groupId);
    final seen = <String>{};
    while (current != null && seen.add(current.id)) {
      names.add(current.name);
      final parentId = current.parentId;
      current = parentId == null ? null : groupById(parentId);
    }
    return names.reversed.join(' · ');
  }

  List<TaskGroup> groupsForPicker() {
    final result = <TaskGroup>[];
    final seen = <String>{};
    void addBranch(String? parentId) {
      final children =
          parentId == null ? topLevelGroups : subgroupsOf(parentId);
      for (final child in children) {
        if (!seen.add(child.id)) {
          continue;
        }
        result.add(child);
        addBranch(child.id);
      }
    }

    addBranch(null);
    return result;
  }

  TaskGroup? groupById(String groupId) {
    for (final group in groups) {
      if (group.id == groupId) {
        return group;
      }
    }
    return null;
  }

  List<Task> tasksForGroup(String groupId) {
    return tasks.where((task) => task.groupId == groupId).toList();
  }

  int activeCountFor(String groupId) {
    final ids = descendantGroupIds(groupId);
    return tasks
        .where((task) => ids.contains(task.groupId) && !task.isCompleted)
        .length;
  }

  int overdueCountFor(String groupId, DateTime now) {
    final ids = descendantGroupIds(groupId);
    return tasks.where((task) {
      final due = task.dueAt;
      return ids.contains(task.groupId) &&
          !task.isCompleted &&
          due != null &&
          isBeforeToday(due, now);
    }).length;
  }

  int dueTodayCountFor(String groupId, DateTime now) {
    final ids = descendantGroupIds(groupId);
    return tasks.where((task) {
      final due = task.dueAt;
      return ids.contains(task.groupId) &&
          !task.isCompleted &&
          due != null &&
          isSameDay(due, now);
    }).length;
  }

  /// Tasks due today across every group (includes completed, so they stay visible).
  List<Task> todaysTasks(DateTime now) {
    final result = tasks.where((task) {
      final due = task.dueAt;
      return due != null && isSameDay(due, now);
    }).toList();
    result.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      final dueCmp = a.dueAt!.compareTo(b.dueAt!);
      if (dueCmp != 0) {
        return dueCmp;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return result;
  }

  /// Incomplete tasks past due across every group.
  List<Task> overdueTasks(DateTime now) {
    final result = tasks.where((task) {
      final due = task.dueAt;
      return !task.isCompleted && due != null && isBeforeToday(due, now);
    }).toList();
    result.sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    return result;
  }

  /// Incomplete tasks due after today, soonest first.
  List<Task> upcomingSoonTasks(DateTime now) {
    return _incompleteDue(now, (due) => isAfterToday(due, now));
  }

  /// Incomplete tasks due tomorrow or the day after, soonest first.
  List<Task> upcomingWindowTasks(DateTime now) {
    return _incompleteDue(now, (due) => isUpcomingWithinDays(due, now));
  }

  /// Incomplete tasks due after the two-day upcoming window, soonest first.
  List<Task> laterTasks(DateTime now) {
    return _incompleteDue(
      now,
      (due) => isAfterToday(due, now) && !isUpcomingWithinDays(due, now),
    );
  }

  /// Reorders groups that share [parentId]. Null [parentId] reorders top-level
  /// groups. [newIndex] is where the group lands after it is removed.
  AppData withSiblingsReordered(String? parentId, int oldIndex, int newIndex) {
    final siblings = parentId == null ? topLevelGroups : subgroupsOf(parentId);
    final reordered = _moveListItem(siblings, oldIndex, newIndex);
    if (reordered == null) {
      return this;
    }
    var cursor = 0;
    return copyWith(
      groups: [
        for (final group in groups)
          if (_isSibling(group, parentId)) reordered[cursor++] else group,
      ],
    );
  }

  List<Task> _incompleteDue(
    DateTime now,
    bool Function(DateTime due) include,
  ) {
    final result = <Task>[
      for (final task in tasks)
        if (!task.isCompleted && task.dueAt != null && include(task.dueAt!))
          task,
    ];
    result.sort(_byDueThenNewest);
    return result;
  }

  static int _byDueThenNewest(Task a, Task b) {
    final dueCompare = a.dueAt!.compareTo(b.dueAt!);
    if (dueCompare != 0) {
      return dueCompare;
    }
    return b.createdAt.compareTo(a.createdAt);
  }

  static bool _isSibling(TaskGroup group, String? parentId) {
    if (parentId == null) {
      return group.isTopLevel;
    }
    return group.parentId == parentId;
  }

  AppData copyWith({
    List<TaskGroup>? groups,
    List<Task>? tasks,
    String? selectedGroupId,
  }) {
    return AppData(
      groups: groups ?? this.groups,
      tasks: tasks ?? this.tasks,
      selectedGroupId: selectedGroupId ?? this.selectedGroupId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groups': groups.map((group) => group.toJson()).toList(),
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'selectedGroupId': selectedGroupId,
    };
  }

  factory AppData.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'] as List<dynamic>? ??
        json['lists'] as List<dynamic>? ??
        [];
    final groups = _parseGroups(rawGroups);
    final tasks = _parseTasks(json['tasks'] as List<dynamic>? ?? []);

    return AppData(
      groups: groups,
      tasks: tasks,
      selectedGroupId: json['selectedGroupId'] as String? ??
          json['selectedListId'] as String? ??
          (groups.isNotEmpty ? groups.first.id : ''),
    );
  }

  static List<TaskGroup> _parseGroups(List<dynamic> rawGroups) {
    final groups = <TaskGroup>[];
    for (final item in rawGroups) {
      if (item is! Map) {
        continue;
      }
      try {
        groups.add(TaskGroup.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {}
    }
    return _sanitizeGroupParents(groups);
  }

  static List<Task> _parseTasks(List<dynamic> rawTasks) {
    final tasks = <Task>[];
    for (final item in rawTasks) {
      if (item is! Map) {
        continue;
      }
      try {
        tasks.add(Task.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {}
    }
    return tasks;
  }

  /// Drops self-parents and links to groups that are not in the save.
  static List<TaskGroup> _sanitizeGroupParents(List<TaskGroup> groups) {
    final ids = {for (final group in groups) group.id};
    return [
      for (final group in groups)
        if (group.parentId == null)
          group
        else if (group.parentId == group.id || !ids.contains(group.parentId))
          group.copyWith(clearParentId: true)
        else
          group,
    ];
  }
}

/// Moves [oldIndex] to [newIndex]. [newIndex] is the index after the item
/// has been removed. Returns null when the order would not change.
List<T>? _moveListItem<T>(List<T> items, int oldIndex, int newIndex) {
  if (oldIndex < 0 || oldIndex >= items.length) {
    return null;
  }
  if (newIndex < 0 || newIndex >= items.length || newIndex == oldIndex) {
    return null;
  }
  final next = [...items];
  final moved = next.removeAt(oldIndex);
  next.insert(newIndex, moved);
  return next;
}
