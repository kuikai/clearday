import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/date_utils.dart';
import '../../models/app_data.dart';
import '../../models/task_group.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/group_actions.dart';
import '../../widgets/group_name_dialog.dart';
import '../../widgets/group_tile.dart';
import '../../widgets/limit_banner.dart';
import '../../widgets/reorderable_groups.dart';
import '../../widgets/section_header.dart';
import '../group/group_tasks_screen.dart';
import '../paywall/paywall_screen.dart';
import '../settings/settings_screen.dart';
import '../task_editor/task_editor_screen.dart';
import 'home_today_pane.dart';

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
  static const EdgeInsets _panePadding = EdgeInsets.fromLTRB(16, 8, 16, 160);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final groups = data.topLevelGroups;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ClearDay'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
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
                final today = HomeTodayPane(
                  now: now,
                  onAddDetailedTask: () => _addTask(context, ref),
                );
                final groupSlivers = _groupSlivers(
                  context,
                  ref,
                  groups: groups,
                  data: data,
                  now: now,
                );
                if (constraints.maxWidth >= _splitBreakpoint) {
                  return _splitBody(context, groupSlivers, today);
                }
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: _panePadding,
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          ...groupSlivers,
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          SliverToBoxAdapter(child: today),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _splitBody(
    BuildContext context,
    List<Widget> groupSlivers,
    Widget today,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: _panePadding,
                sliver: SliverMainAxisGroup(slivers: groupSlivers),
              ),
            ],
          ),
        ),
        VerticalDivider(
          width: 1,
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        Expanded(
          child: ListView(padding: _panePadding, children: [today]),
        ),
      ],
    );
  }

  List<Widget> _groupSlivers(
    BuildContext context,
    WidgetRef ref, {
    required List<TaskGroup> groups,
    required AppData data,
    required DateTime now,
  }) {
    final expanded = ref.watch(
      settingsProvider.select((settings) => settings.groupsExpanded),
    );
    final header = _GroupsHeader(
      count: groups.length,
      expanded: expanded,
      onToggle: () {
        ref.read(settingsProvider.notifier).setGroupsExpanded(!expanded);
      },
    );
    if (!expanded) {
      return [SliverToBoxAdapter(child: header)];
    }
    return reorderableGroupSlivers(
      header: header,
      itemCount: groups.length,
      onReorder: (oldIndex, newIndex) {
        ref
            .read(appDataProvider.notifier)
            .reorderSiblings(null, oldIndex, newIndex);
      },
      empty: EmptyState(
        title: 'No groups yet',
        message: 'Create House Work, Workout, or Work to organize tasks.',
        icon: Icons.folder_outlined,
        action: FilledButton.icon(
          onPressed: () => _addGroup(context, ref),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add group'),
        ),
      ),
      itemBuilder: (context, index) {
        return _groupTile(
          context,
          ref,
          data: data,
          now: now,
          group: groups[index],
          index: index,
          count: groups.length,
        );
      },
    );
  }

  Widget _groupTile(
    BuildContext context,
    WidgetRef ref, {
    required AppData data,
    required DateTime now,
    required TaskGroup group,
    required int index,
    required int count,
  }) {
    return GroupTile(
      key: ValueKey(group.id),
      group: group,
      reorderIndex: count > 1 ? index : null,
      activeCount: data.activeCountFor(group.id),
      overdueCount: data.overdueCountFor(group.id, now),
      dueTodayCount: data.dueTodayCountFor(group.id, now),
      onOpen: () => _openGroup(context, ref, group),
      onAddSubgroup: () => _addSubgroup(context, ref, group.id),
      onRename: () => _renameGroup(context, ref, group),
      onCopy: () => _copyGroup(context, ref, group),
      onDelete: () => _deleteGroup(context, ref, group),
    );
  }

  Future<void> _addTask(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(appDataProvider.notifier);
    if (!notifier.canAddTask) {
      await showPaywall(context, reason: PaywallReason.tasks);
      return;
    }

    var data = ref.read(appDataProvider);
    if (data.groups.isEmpty) {
      if (!notifier.canAddGroup) {
        await showPaywall(context, reason: PaywallReason.groups);
        return;
      }
      await notifier.addGroup(AppConstants.defaultGroupName);
      data = ref.read(appDataProvider);
    }

    final groupId = data.preferredGroupId;
    if (groupId == null) {
      return;
    }
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
    final reason = parentId == null
        ? PaywallReason.groups
        : PaywallReason.subgroups;
    final allowed = parentId == null
        ? notifier.canAddGroup
        : notifier.canAddSubgroup;
    if (!allowed) {
      await showPaywall(context, reason: reason);
      return;
    }

    final name = await promptGroupName(context, title: dialogTitle);
    if (name == null || name.trim().isEmpty) {
      return;
    }

    final result = await notifier.addGroup(name, parentId: parentId);
    if (result == SaveTaskResult.blockedByGroupLimit && context.mounted) {
      await showPaywall(context, reason: reason);
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
  ) {
    return renameGroupAction(
      context,
      ref,
      group.id,
      currentName: group.name,
      dialogTitle: 'Rename group',
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
    return deleteGroupAction(context, ref, group.id, name: group.name);
  }
}

class _GroupsHeader extends StatelessWidget {
  const _GroupsHeader({
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: SectionHeader(
          title: 'Groups',
          count: count,
          action: Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}
