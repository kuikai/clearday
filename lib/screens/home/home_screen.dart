import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/date_utils.dart';
import '../../models/app_data.dart';
import '../../models/task.dart';
import '../../models/task_group.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/group_name_dialog.dart';
import '../../widgets/group_tile.dart';
import '../../widgets/limit_banner.dart';
import '../../widgets/section_header.dart';
import '../../widgets/task_tile.dart';
import '../group/group_tasks_screen.dart';
import '../paywall/paywall_screen.dart';
import '../settings/settings_screen.dart';
import '../task_editor/task_editor_screen.dart';

class _RecurringReactivator extends ConsumerStatefulWidget {
  const _RecurringReactivator();

  @override
  ConsumerState<_RecurringReactivator> createState() =>
      _RecurringReactivatorState();
}

class _RecurringReactivatorState extends ConsumerState<_RecurringReactivator>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reactivate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reactivate();
    }
  }

  void _reactivate() {
    ref.read(appDataProvider.notifier).reactivateRecurringTasks();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const double _splitBreakpoint = 720;
  static const EdgeInsets _panePadding =
      EdgeInsets.fromLTRB(16, 8, 16, 160);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final groups = data.topLevelGroups;
    final now = DateTime.now();
    final overdue = data.overdueTasks(now);
    final today = data.todaysTasks(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ClearDay'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'home_add_task',
            onPressed: () => _addTask(context, ref),
            tooltip: 'Add task for today',
            icon: const Icon(Icons.add_rounded),
            label: const Text('Task'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'home_add_group',
            onPressed: () => _addGroup(context, ref),
            tooltip: 'Add group',
            icon: const Icon(Icons.create_new_folder_outlined),
            label: const Text('Group'),
          ),
        ],
      ),
      body: Column(
        children: [
          const _RecurringReactivator(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: LimitBanner(),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final groupsChildren = _groupsChildren(
                  context,
                  ref,
                  groups: groups,
                  data: data,
                  now: now,
                );
                final todayChildren = _todayChildren(
                  context,
                  ref,
                  data: data,
                  overdue: overdue,
                  today: today,
                );

                if (constraints.maxWidth >= _splitBreakpoint) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView(
                          padding: _panePadding,
                          children: groupsChildren,
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.6),
                      ),
                      Expanded(
                        child: ListView(
                          padding: _panePadding,
                          children: todayChildren,
                        ),
                      ),
                    ],
                  );
                }

                return ListView(
                  padding: _panePadding,
                  children: [
                    ...groupsChildren,
                    const SizedBox(height: 8),
                    ...todayChildren,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _groupsChildren(
    BuildContext context,
    WidgetRef ref, {
    required List<TaskGroup> groups,
    required AppData data,
    required DateTime now,
  }) {
    return [
      SectionHeader(title: 'Groups', count: groups.length),
      if (groups.isEmpty)
        EmptyState(
          title: 'No groups yet',
          message: 'Create House Work, Workout, or Work to organize tasks.',
          icon: Icons.folder_outlined,
          action: FilledButton.icon(
            onPressed: () => _addGroup(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add group'),
          ),
        )
      else
        for (final group in groups)
          GroupTile(
            group: group,
            activeCount: data.activeCountFor(group.id),
            overdueCount: data.overdueCountFor(group.id, now),
            onOpen: () => _openGroup(context, ref, group),
            onAddSubgroup: () => _addSubgroup(context, ref, group.id),
            onRename: () => _renameGroup(context, ref, group),
            onCopy: () => _copyGroup(context, ref, group),
            onDelete: () => _deleteGroup(context, ref, group),
          ),
    ];
  }

  List<Widget> _todayChildren(
    BuildContext context,
    WidgetRef ref, {
    required AppData data,
    required List<Task> overdue,
    required List<Task> today,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final doneCount = today.where((task) => task.isCompleted).length;
    final isEmpty = overdue.isEmpty && today.isEmpty;

    return [
      SectionHeader(
        title: 'Today',
        progressLabel:
            today.isEmpty ? null : '$doneCount/${today.length} done',
      ),
      if (isEmpty)
        EmptyState(
          title: 'Nothing due today',
          message: 'Tap Task to add something for today — it shows up here.',
          icon: Icons.wb_sunny_outlined,
          action: FilledButton.icon(
            onPressed: () => _addTask(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add task'),
          ),
        )
      else ...[
        if (overdue.isNotEmpty)
          _HomeTaskSection(
            title: 'Overdue',
            tasks: overdue,
            data: data,
            accent: colorScheme.error,
          ),
        if (today.isNotEmpty)
          _HomeTaskSection(
            title: 'Due today',
            tasks: today,
            data: data,
          ),
      ],
    ];
  }

  Future<void> _addTask(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(appDataProvider.notifier);
    if (!notifier.canAddTask) {
      await showPaywall(context);
      return;
    }

    var data = ref.read(appDataProvider);
    if (data.groups.isEmpty) {
      if (!notifier.canAddGroup) {
        await showPaywall(context);
        return;
      }
      await notifier.addGroup(AppConstants.defaultGroupName);
      data = ref.read(appDataProvider);
    }

    // First top-level group — predictable home for Today tasks.
    final groupId = data.topLevelGroups.isNotEmpty
        ? data.topLevelGroups.first.id
        : data.groups.first.id;
    await notifier.selectGroup(groupId);
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskEditorScreen(
          task: notifier.newTaskDraft(
            groupId: groupId,
            dueAt: dateOnly(DateTime.now()),
          ),
          isNew: true,
        ),
      ),
    );
  }

  Future<void> _openGroup(
    BuildContext context,
    WidgetRef ref,
    TaskGroup group,
  ) async {
    await ref.read(appDataProvider.notifier).selectGroup(group.id);
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupTasksScreen(groupId: group.id),
      ),
    );
  }

  Future<void> _createGroup(
    BuildContext context,
    WidgetRef ref, {
    required String dialogTitle,
    String? parentId,
  }) async {
    final notifier = ref.read(appDataProvider.notifier);
    final allowed =
        parentId == null ? notifier.canAddGroup : notifier.canAddSubgroup;
    if (!allowed) {
      await showPaywall(context);
      return;
    }

    final name = await promptGroupName(context, title: dialogTitle);
    if (name == null || name.trim().isEmpty) {
      return;
    }

    final result = await notifier.addGroup(name, parentId: parentId);
    if (result == SaveTaskResult.blockedByGroupLimit && context.mounted) {
      await showPaywall(context);
      return;
    }
    if (!context.mounted) {
      return;
    }

    final group = ref.read(appDataProvider).selectedGroup;
    if (group != null) {
      await _openGroup(context, ref, group);
    }
  }

  Future<void> _addSubgroup(
    BuildContext context,
    WidgetRef ref,
    String parentId,
  ) {
    return _createGroup(
      context,
      ref,
      dialogTitle: 'New subgroup',
      parentId: parentId,
    );
  }

  Future<void> _addGroup(BuildContext context, WidgetRef ref) {
    return _createGroup(context, ref, dialogTitle: 'New group');
  }

  Future<void> _renameGroup(
    BuildContext context,
    WidgetRef ref,
    TaskGroup group,
  ) async {
    final name = await promptGroupName(
      context,
      title: 'Rename group',
      initial: group.name,
    );
    if (name == null) {
      return;
    }
    await ref.read(appDataProvider.notifier).renameGroup(group.id, name);
  }

  Future<void> _copyGroup(
    BuildContext context,
    WidgetRef ref,
    TaskGroup group,
  ) async {
    final result =
        await ref.read(appDataProvider.notifier).copyGroup(group.id);
    if (!context.mounted) {
      return;
    }
    if (result == SaveTaskResult.blockedByGroupLimit ||
        result == SaveTaskResult.blockedByTaskLimit) {
      await showPaywall(context);
    }
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
}

class _HomeTaskSection extends ConsumerWidget {
  const _HomeTaskSection({
    required this.title,
    required this.tasks,
    required this.data,
    this.accent,
  });

  final String title;
  final List<Task> tasks;
  final AppData data;
  final Color? accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            accent: accent,
          ),
          ...tasks.map((task) {
            return TaskTile(
              key: ValueKey(task.id),
              task: task,
              subtitle: data.groupPath(task.groupId),
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
