import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_data.dart';
import '../../models/task.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/quick_add_bar.dart';
import '../../widgets/section_header.dart';
import '../../widgets/smooth_section.dart';
import '../../widgets/task_actions.dart';
import '../../widgets/task_tile.dart';

class HomeTodayPane extends ConsumerWidget {
  const HomeTodayPane({
    super.key,
    required this.now,
    required this.onAddDetailedTask,
  });

  final DateTime now;
  final VoidCallback onAddDetailedTask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider);
    final overdue = data.overdueTasks(now);
    final today = data.todaysTasks(now);
    final upcoming = data.upcomingWindowTasks(now);
    final later = data.laterTasks(now);
    final doneCount = today.where((task) => task.isCompleted).length;
    final isEmpty =
        overdue.isEmpty && today.isEmpty && upcoming.isEmpty && later.isEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Today',
          progressLabel: today.isEmpty
              ? null
              : '$doneCount/${today.length} done',
        ),
        const QuickAddBar(),
        if (isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 28, left: 20),
            child: EmptyState(
              title: 'Nothing due today',
              message: 'Add a task for today — it shows up here.',
              icon: Icons.wb_sunny_outlined,
              action: FilledButton.icon(
                onPressed: onAddDetailedTask,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add task'),
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeTaskSection(
                title: 'Overdue',
                tasks: overdue,
                data: data,
                accent: colorScheme.error,
                action: TextButton(
                  onPressed: () => moveOverdueToTodayWithUndo(context, ref),
                  child: const Text('Today'),
                ),
              ),
              _HomeTaskSection(title: 'Due today', tasks: today, data: data),
              _HomeTaskSection(
                title: 'Upcoming',
                tasks: upcoming,
                data: data,
                emptyMessage: 'Tomorrow and the next day show up here.',
              ),
              _LaterSection(tasks: later, data: data),
            ],
          ),
      ],
    );
  }
}

class _HomeTaskSection extends ConsumerWidget {
  const _HomeTaskSection({
    required this.title,
    required this.tasks,
    required this.data,
    this.accent,
    this.emptyMessage,
    this.action,
  });

  final String title;
  final List<Task> tasks;
  final AppData data;
  final Color? accent;
  final String? emptyMessage;
  final Widget? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = tasks.isEmpty && emptyMessage == null;
    final theme = Theme.of(context);
    return SmoothSection(
      child: hidden
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: title,
                    count: tasks.isEmpty ? null : tasks.length,
                    accent: accent,
                    action: action,
                  ),
                  if (tasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 8, 12),
                      child: Text(
                        emptyMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final task in tasks)
                      _homeTaskTile(context, ref, data, task),
                ],
              ),
            ),
    );
  }
}

class _LaterSection extends ConsumerStatefulWidget {
  const _LaterSection({required this.tasks, required this.data});

  final List<Task> tasks;
  final AppData data;

  @override
  ConsumerState<_LaterSection> createState() => _LaterSectionState();
}

class _LaterSectionState extends ConsumerState<_LaterSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return SmoothSection(
      child: widget.tasks.isEmpty
          ? const SizedBox(width: double.infinity)
          : _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            borderRadius: BorderRadius.circular(12),
            child: SectionHeader(
              title: 'Later',
              count: widget.tasks.length,
              action: ExpandChevron(expanded: _expanded),
            ),
          ),
        ),
        if (_expanded)
          for (final task in widget.tasks)
            _homeTaskTile(context, ref, widget.data, task),
      ],
    );
  }
}

Widget _homeTaskTile(
  BuildContext context,
  WidgetRef ref,
  AppData data,
  Task task,
) {
  return TaskTile(
    key: ValueKey(task.id),
    task: task,
    subtitle: data.groupPath(task.groupId),
    onToggle: () => toggleTaskWithUndo(context, ref, task),
    onMoveToTomorrow: () => moveTaskToTomorrowWithUndo(context, ref, task),
    onOpen: () => openTaskEditor(context, task),
  );
}
