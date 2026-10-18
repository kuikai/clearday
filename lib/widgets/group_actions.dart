import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tasks_provider.dart';
import '../screens/paywall/paywall_screen.dart';
import 'group_name_dialog.dart';

Future<void> copyGroupAction(
  BuildContext context,
  WidgetRef ref,
  String groupId,
) async {
  final result = await ref.read(appDataProvider.notifier).copyGroup(groupId);
  if (!context.mounted) {
    return;
  }
  if (result == SaveTaskResult.blockedByGroupLimit ||
      result == SaveTaskResult.blockedByTaskLimit) {
    await showPaywall(context);
  }
}

Future<void> renameGroupAction(
  BuildContext context,
  WidgetRef ref,
  String groupId, {
  required String currentName,
  required String dialogTitle,
}) async {
  final name = await promptGroupName(
    context,
    title: dialogTitle,
    initial: currentName,
  );
  if (name == null) {
    return;
  }
  await ref.read(appDataProvider.notifier).renameGroup(groupId, name);
}

Future<bool> confirmClearCompleted(BuildContext context, int count) async {
  final label = count == 1 ? '1 completed task' : '$count completed tasks';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Clear completed tasks?'),
        content: Text('This removes $label from this group.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

Future<void> deleteGroupAction(
  BuildContext context,
  WidgetRef ref,
  String groupId, {
  required String name,
}) async {
  final confirmed = await confirmDeleteGroup(context, name);
  if (confirmed) {
    await ref.read(appDataProvider.notifier).deleteGroup(groupId);
  }
}
