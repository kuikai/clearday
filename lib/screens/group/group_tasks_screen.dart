import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_data.dart';
import '../../models/task.dart';
import '../../models/task_group.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/group_actions.dart';
import '../../widgets/group_name_dialog.dart';
import '../../widgets/group_tile.dart';
import '../../widgets/reorderable_groups.dart';
import '../../widgets/section_header.dart';
import '../../widgets/task_actions.dart';
import '../../widgets/task_tile.dart';
import '../paywall/paywall_screen.dart';
import '../task_editor/task_editor_screen.dart';

class GroupTasksScreen extends ConsumerWidget {
  const GroupTasksScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final group = data.groupById(groupId);
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group')),
        body: const EmptyState(
          title: 'Group not found',
          message: 'This group was deleted.',
          icon: Icons.folder_off_outlined,
        ),
      );
    }

    final subgroups = data.subgroupsOf(groupId);
    final taskGroups = groupTasks(data.tasksForGroup(groupId), DateTime.now());
    final now = DateTime.now();
    final isEmpty = subgroups.isEmpty && taskGroups.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            tooltip: 'Rename group',
            onPressed: () => _renameGroup(context, ref, group),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Copy group',
            onPressed: () => _copyGroup(context, ref, group),
            icon: const Icon(Icons.copy_outlined),
          ),
          IconButton(
            tooltip: 'Add subgroup',
            onPressed: () => _addSubgroup(context, ref),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'group_add_task',
        onPressed: () => _addTask(context, ref),
        tooltip: 'Add task',
        icon: const Icon(Icons.add_rounded),
        label: const Text('Task'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverMainAxisGroup(
              slivers: [
                if (isEmpty)
                  SliverToBoxAdapter(child: _emptyGroup(context, ref, group)),
                if (subgroups.isNotEmpty)
                  ..._subgroupSlivers(context, ref, data, subgroups, now),
                if (!isEmpty)
                  SliverToBoxAdapter(child: _addSubgroupButton(context, ref)),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _TaskSection(
                        title: 'Overdue',
                        tasks: taskGroups.overdue,
                        accent: Theme.of(context).colorScheme.error,
                        onMoveToToday: () => moveOverdueToTodayWithUndo(
                          context,
                          ref,
                          groupId: groupId,
                        ),
                      ),
                      _TaskSection(title: 'Today', tasks: taskGroups.today),
                      _TaskSection(
                        title: 'Upcoming',
                        tasks: taskGroups.upcoming,
                      ),
                      _TaskSection(title: 'No date', tasks: taskGroups.noDate),
                      _TaskSection(
                        title: 'Done',
                        tasks: taskGroups.done,
                        onClear: () => _clearCompleted(
                          context,
                          ref,
                          taskGroups.done.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyGroup(BuildContext context, WidgetRef ref, TaskGroup group) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: EmptyState(
        title: 'Nothing in ${group.name} yet',
        message: 'Add a task, or nest a subgroup like Kitchen.',
        icon: Icons.check_circle_outline_rounded,
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: () => _addTask(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add task'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _addSubgroup(context, ref),
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Add subgroup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addSubgroupButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: OutlinedButton.icon(
        onPressed: () => _addSubgroup(context, ref),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('Add subgroup'),
      ),
    );
  }

  List<Widget> _subgroupSlivers(
    BuildContext context,
    WidgetRef ref,
    AppData data,
    List<TaskGroup> subgroups,
    DateTime now,
  ) {
    return reorderableGroupSlivers(
      header: SectionHeader(title: 'Subgroups', count: subgroups.length),
      itemCount: subgroups.length,
      onReorder: (oldIndex, newIndex) {
        ref.read(appDataProvider.notifier).reorderSiblings(
              groupId,
              oldIndex,
              newIndex,
            );
      },
      itemBuilder: (context, index) {
        final subgroup = subgroups[index];
        return GroupTile(
          key: ValueKey(subgroup.id),
          group: subgroup,
          isSubgroup: true,
          reorderIndex: subgroups.length > 1 ? index : null,
          activeCount: data.activeCountFor(subgroup.id),
          overdueCount: data.overdueCountFor(subgroup.id, now),
          dueTodayCount: data.dueTodayCountFor(subgroup.id, now),
          onOpen: () => _openGroup(context, ref, subgroup),
          onAddSubgroup: () => _addSubgroupUnder(context, ref, subgroup.id),
          onRename: () => _renameGroup(context, ref, subgroup),
          onCopy: () => _copyGroup(context, ref, subgroup),
          onDelete: () => _deleteGroup(context, ref, subgroup),
        );
      },
    );
  }

  Future<void> _clearCompleted(
    BuildContext context,
    WidgetRef ref,
    int count,
  ) async {
    if (count == 0) {
      return;
    }
    final confirmed = await confirmClearCompleted(context, count);
    if (!confirmed) {
      return;
    }
    await ref.read(appDataProvider.notifier).clearCompletedInGroup(groupId);
  }

  Future<void> _openGroup(
    BuildContext context,
    WidgetRef ref,
    TaskGroup group,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupTasksScreen(groupId: group.id),
      ),
    );
  }

  Future<void> _addSubgroup(BuildContext context, WidgetRef ref) {
    return _addSubgroupUnder(context, ref, groupId);
  }

  Future<void> _addSubgroupUnder(
    BuildContext context,
    WidgetRef ref,
    String parentId,
  ) async {
    final notifier = ref.read(appDataProvider.notifier);
    if (!notifier.canAddSubgroup) {
      await showPaywall(context);
      return;
    }
    final name = await promptGroupName(context, title: 'New subgroup');
    if (name == null || name.trim().isEmpty) {
      return;
    }
    final result = await notifier.addGroup(name, parentId: parentId);
    if (result == SaveTaskResult.blockedByGroupLimit && context.mounted) {
      await showPaywall(context);
    }
  }

  Future<void> _renameGroup(
    BuildContext context,
    WidgetRef ref,
    TaskGroup group,
  ) {
    return renameGroupAction(
      context,
      ref,
      group.id,
      currentName: group.name,
      dialogTitle: group.isTopLevel ? 'Rename group' : 'Rename subgroup',
    );
  }

  Future<void> _copyGroup(
    BuildContext context,
    WidgetRef ref,
    TaskGroup group,
  ) {
    return copyGroupAction(context, ref, group.id);
  }

  Future<void> _deleteGroup(
    BuildContext context,
    WidgetRef ref,
    TaskGroup group,
  ) {
    return deleteGroupAction(
      context,
      ref,
      group.id,
      name: group.name,
    );
  }

  Future<void> _addTask(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(appDataProvider.notifier);
    if (!notifier.canAddTask) {
      await showPaywall(context);
      return;
    }
    await notifier.selectGroup(groupId);
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskEditorScreen(
          task: notifier.newTaskDraft(groupId: groupId),
          isNew: true,
        ),
      ),
    );
  }
}

class _TaskSection extends ConsumerWidget {
  const _TaskSection({
    required this.title,
    required this.tasks,
    this.accent,
    this.onClear,
    this.onMoveToToday,
  });

  final String title;
  final List<Task> tasks;
  final Color? accent;
  final VoidCallback? onClear;
  final VoidCallback? onMoveToToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            count: tasks.length,
            accent: accent,
            action: onClear != null
                ? TextButton(
                    onPressed: onClear,
                    child: const Text('Clear'),
                  )
                : onMoveToToday == null
                    ? null
                    : TextButton(
                        onPressed: onMoveToToday,
                        child: const Text('Today'),
                      ),
          ),
          for (final task in tasks)
            TaskTile(
              key: ValueKey(task.id),
              task: task,
              onToggle: () => toggleTaskWithUndo(context, ref, task),
              onMoveToTomorrow: () =>
                  moveTaskToTomorrowWithUndo(context, ref, task),
              onOpen: () => openTaskEditor(context, task),
            ),
        ],
      ),
    );
  }
}
