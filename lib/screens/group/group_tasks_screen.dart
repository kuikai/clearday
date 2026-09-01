import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../models/task_group.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/group_name_dialog.dart';
import '../../widgets/group_tile.dart';
import '../../widgets/section_header.dart';
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
            tooltip: 'Add subgroup',
            onPressed: () => _addSubgroup(context, ref),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTask(context, ref),
        tooltip: 'Add task',
        icon: const Icon(Icons.add_rounded),
        label: const Text('Task'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (isEmpty)
            Padding(
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
            ),
          if (subgroups.isNotEmpty) ...[
            SectionHeader(
              title: 'Subgroups',
              count: subgroups.length,
            ),
            for (final subgroup in subgroups)
              GroupTile(
                group: subgroup,
                isSubgroup: true,
                activeCount: data.activeCountFor(subgroup.id),
                overdueCount: data.overdueCountFor(subgroup.id, now),
                onOpen: () => _openGroup(context, ref, subgroup),
                onAddSubgroup: () =>
                    _addSubgroupUnder(context, ref, subgroup.id),
                onRename: () => _renameGroup(context, ref, subgroup),
                onDelete: () => _deleteGroup(context, ref, subgroup),
              ),
          ],
          if (!isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: OutlinedButton.icon(
                onPressed: () => _addSubgroup(context, ref),
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('Add subgroup'),
              ),
            ),
          _TaskSection(
            title: 'Overdue',
            tasks: taskGroups.overdue,
            accent: Theme.of(context).colorScheme.error,
          ),
          _TaskSection(title: 'Today', tasks: taskGroups.today),
          _TaskSection(title: 'Upcoming', tasks: taskGroups.upcoming),
          _TaskSection(title: 'No date', tasks: taskGroups.noDate),
          _TaskSection(title: 'Done', tasks: taskGroups.done),
        ],
      ),
    );
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
  ) async {
    final name = await promptGroupName(
      context,
      title: 'Rename subgroup',
      initial: group.name,
    );
    if (name == null) {
      return;
    }
    await ref.read(appDataProvider.notifier).renameGroup(group.id, name);
  }

  Future<void> _deleteGroup(
    BuildContext context,
    WidgetRef ref,
    TaskGroup group,
  ) async {
    final confirmed = await confirmDeleteGroup(context, group.name);
    if (confirmed) {
      await ref.read(appDataProvider.notifier).deleteGroup(group.id);
    }
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
  });

  final String title;
  final List<Task> tasks;
  final Color? accent;

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
          ),
          ...tasks.map((task) {
            return TaskTile(
              key: ValueKey(task.id),
              task: task,
              onToggle: () {
                ref.read(appDataProvider.notifier).toggleCompleted(task.id);
              },
              onOpen: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TaskEditorScreen(
                      task: task,
                      isNew: false,
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
