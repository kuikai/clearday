import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task_group.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/group_name_dialog.dart';
import '../../widgets/group_tile.dart';
import '../../widgets/limit_banner.dart';
import '../group/group_tasks_screen.dart';
import '../paywall/paywall_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addGroup(context, ref),
        tooltip: 'Add group',
        icon: const Icon(Icons.add_rounded),
        label: const Text('Group'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: LimitBanner(),
          ),
          Expanded(
            child: groups.isEmpty
                ? EmptyState(
                    title: 'Start with a group',
                    message: 'Create House Work, Workout, or Work, '
                        'then add tasks inside it.',
                    icon: Icons.folder_outlined,
                    action: FilledButton.icon(
                      onPressed: () => _addGroup(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add group'),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: [
                      for (final group in groups)
                        GroupTile(
                          group: group,
                          activeCount: data.activeCountFor(group.id),
                          overdueCount: data.overdueCountFor(group.id, now),
                          onOpen: () => _openGroup(context, ref, group),
                          onAddSubgroup: () =>
                              _addSubgroup(context, ref, group.id),
                          onRename: () => _renameGroup(context, ref, group),
                          onDelete: () => _deleteGroup(context, ref, group),
                        ),
                    ],
                  ),
          ),
        ],
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

  Future<void> _addSubgroup(
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

  Future<void> _addGroup(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(appDataProvider.notifier);
    if (!notifier.canAddGroup) {
      await showPaywall(context);
      return;
    }
    final name = await promptGroupName(context, title: 'New group');
    if (name == null || name.trim().isEmpty) {
      return;
    }
    final result = await notifier.addGroup(name);
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
