import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../providers/tasks_provider.dart';
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
  await notifier.toggleCompleted(task.id);
  if (!context.mounted) {
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(task.isCompleted ? 'Marked not done' : 'Marked done'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          notifier.restoreTask(task);
        },
      ),
    ),
  );
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
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: const Text('Due tomorrow'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          notifier.restoreTask(task);
        },
      ),
    ),
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
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(label),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          notifier.restoreTasks(previous);
        },
      ),
    ),
  );
}
