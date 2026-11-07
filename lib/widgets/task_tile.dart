import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/date_utils.dart';
import '../core/motion.dart';
import '../models/task.dart';
import 'task_swipe.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onMoveToTomorrow,
    required this.onOpen,
    this.subtitle,
  });

  final Task task;
  final Future<void> Function() onToggle;
  final Future<void> Function() onMoveToTomorrow;
  final VoidCallback onOpen;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final completed = task.isCompleted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TaskSwipe(
        allowTomorrow: !completed,
        markingDone: !completed,
        onTomorrow: () {
          onMoveToTomorrow();
        },
        onDone: () {
          onToggle();
        },
        child: _TaskCard(
          task: task,
          subtitle: subtitle,
          onToggle: onToggle,
          onOpen: onOpen,
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.subtitle,
    required this.onToggle,
    required this.onOpen,
  });

  final Task task;
  final String? subtitle;
  final Future<void> Function() onToggle;
  final VoidCallback onOpen;

  bool get _overdue {
    final due = task.dueAt;
    if (task.isCompleted || due == null) {
      return false;
    }
    return isBeforeToday(due, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final overdue = _overdue;
    final completed = task.isCompleted;

    return AnimatedOpacity(
      duration: Motion.short,
      curve: Motion.ease,
      opacity: completed ? 0.62 : 1,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: overdue
                ? colorScheme.error.withValues(alpha: 0.5)
                : colorScheme.outlineVariant.withValues(alpha: 0.9),
          ),
        ),
        child: InkWell(
          onTap: onOpen,
          child: Stack(
            children: [
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: Motion.short,
                  width: 4,
                  color: overdue ? colorScheme.error : Colors.transparent,
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: _TaskRow(
                  task: task,
                  subtitle: subtitle,
                  overdue: overdue,
                  completed: completed,
                  onToggle: onToggle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.subtitle,
    required this.overdue,
    required this.completed,
    required this.onToggle,
  });

  final Task task;
  final String? subtitle;
  final bool overdue;
  final bool completed;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 48,
          height: 56,
          child: Center(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              scale: completed ? 0.92 : 1,
              child: Checkbox(
                value: completed,
                onChanged: (_) {
                  HapticFeedback.selectionClick();
                  onToggle();
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: _TaskText(
            task: task,
            subtitle: subtitle,
            overdue: overdue,
            completed: completed,
          ),
        ),
        if (task.recurrence.isEnabled)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.repeat_rounded,
              size: 18,
              color: colorScheme.primary.withValues(alpha: 0.85),
            ),
          ),
      ],
    );
  }
}

class _TaskText extends StatelessWidget {
  const _TaskText({
    required this.task,
    required this.subtitle,
    required this.overdue,
    required this.completed,
  });

  final Task task;
  final String? subtitle;
  final bool overdue;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final note = task.notes.trim().replaceAll(RegExp(r'\s+'), ' ');
    final due = task.dueAt;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedDefaultTextStyle(
            duration: Motion.short,
            curve: Motion.ease,
            style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
              fontWeight: FontWeight.w600,
              decoration: completed
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: completed
                  ? colorScheme.onSurface.withValues(alpha: 0.45)
                  : colorScheme.onSurface,
            ),
            child: Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ],
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
          if (due != null) ...[
            const SizedBox(height: 4),
            Text(
              formatDueLabel(due, hasTime: task.dueHasTime),
              style: theme.textTheme.bodySmall?.copyWith(
                color: overdue
                    ? colorScheme.error
                    : colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight: overdue ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
