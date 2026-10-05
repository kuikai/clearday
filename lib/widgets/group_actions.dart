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
