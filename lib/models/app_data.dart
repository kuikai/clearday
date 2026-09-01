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
    void addBranch(String? parentId) {
      final children =
          parentId == null ? topLevelGroups : subgroupsOf(parentId);
      for (final child in children) {
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
    final groups = rawGroups
        .map(
          (item) => TaskGroup.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    final tasks = (json['tasks'] as List<dynamic>? ?? [])
        .map((item) => Task.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    return AppData(
      groups: groups,
      tasks: tasks,
      selectedGroupId: json['selectedGroupId'] as String? ??
          json['selectedListId'] as String? ??
          (groups.isNotEmpty ? groups.first.id : ''),
    );
  }
}
