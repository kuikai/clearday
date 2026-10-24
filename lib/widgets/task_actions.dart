import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../providers/tasks_provider.dart';
import '../screens/paywall/paywall_screen.dart';
import '../screens/task_editor/task_editor_screen.dart';

Future<void> openTaskEditor(BuildContext context, Task task) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TaskEditorScreen(task: task, isNew: false),
    ),
  );
}

Future<void> toggleTaskWithUndo(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final notifier = ref.read(appDataProvider.notifier);
  final result = await notifier.toggleCompleted(task.id);
  if (!context.mounted) {
    return;
  }
  if (result == SaveTaskResult.blockedByTaskLimit) {
    await showPaywall(context, reason: PaywallReason.tasks);
    return;
  }
  showUndoNotice(
    context,
    message: task.isCompleted ? 'Marked not done' : 'Marked done',
    onUndo: () => _restoreWithPaywall(context, notifier, [task]),
  );
}

Future<void> _restoreWithPaywall(
  BuildContext context,
  AppDataNotifier notifier,
  List<Task> snapshots,
) async {
  final result = await notifier.restoreTasks(snapshots);
  if (result == SaveTaskResult.blockedByTaskLimit && context.mounted) {
    await showPaywall(context, reason: PaywallReason.tasks);
  }
}

Future<void> moveTaskToTomorrowWithUndo(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final notifier = ref.read(appDataProvider.notifier);
  final changed = await notifier.moveDueToTomorrow(task.id);
  if (!changed || !context.mounted) {
    return;
  }
  showUndoNotice(
    context,
    message: 'Due tomorrow',
    onUndo: () => _restoreWithPaywall(context, notifier, [task]),
  );
}

Future<void> moveOverdueToTodayWithUndo(
  BuildContext context,
  WidgetRef ref, {
  String? groupId,
}) async {
  final notifier = ref.read(appDataProvider.notifier);
  final previous = await notifier.moveOverdueToToday(groupId: groupId);
  if (previous.isEmpty || !context.mounted) {
    return;
  }
  final label = previous.length == 1
      ? 'Moved to today'
      : '${previous.length} moved to today';
  showUndoNotice(
    context,
    message: label,
    onUndo: () => _restoreWithPaywall(context, notifier, previous),
  );
}

int _undoNoticeToken = 0;

/// Shows [message] under the app bar, with Undo, then clears it.
///
/// The page moves down with the notice, so task settings stay visible.
void showUndoNotice(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final token = ++_undoNoticeToken;
  messenger
    ..clearMaterialBanners()
    ..hideCurrentSnackBar();
  messenger.showMaterialBanner(
    _undoBanner(
      context,
      message: message,
      onUndo: () {
        _undoNoticeToken++;
        messenger.hideCurrentMaterialBanner();
        onUndo();
      },
    ),
  );
  Future<void>.delayed(const Duration(seconds: 4), () {
    if (token != _undoNoticeToken) {
      return;
    }
    messenger.hideCurrentMaterialBanner();
  });
}

MaterialBanner _undoBanner(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
}) {
  final scheme = Theme.of(context).colorScheme;
  return MaterialBanner(
    elevation: 0,
    backgroundColor: scheme.inverseSurface,
    surfaceTintColor: Colors.transparent,
    dividerColor: scheme.inverseSurface,
    padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 4, 8),
    contentTextStyle: TextStyle(color: scheme.onInverseSurface),
    content: Text(message),
    actions: [
      TextButton(
        style: TextButton.styleFrom(foregroundColor: scheme.inversePrimary),
        onPressed: onUndo,
        child: const Text('Undo'),
      ),
    ],
  );
}
