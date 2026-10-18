import 'package:flutter/material.dart';

import '../core/date_utils.dart';
import '../models/task.dart';

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

  bool get _isOverdue {
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
    final overdue = _isOverdue;
    final due = task.dueAt;
    final completed = task.isCompleted;

    final note = task.notes.trim().replaceAll(RegExp(r'\s+'), ' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('swipe-${task.id}'),
        direction: completed
            ? DismissDirection.endToStart
            : DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await onMoveToTomorrow();
          } else {
            await onToggle();
          }
          return false;
        },
        background: const _SwipeBackground.tomorrow(),
        secondaryBackground: _SwipeBackground.done(markingDone: !completed),
        child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
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
            child: IntrinsicHeight(
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 4,
                    color: overdue ? colorScheme.error : Colors.transparent,
                  ),
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
                          onChanged: (_) => onToggle(),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            style: (theme.textTheme.titleMedium ??
                                    const TextStyle())
                                .copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: completed
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: completed
                                  ? colorScheme.onSurface
                                      .withValues(alpha: 0.45)
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
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.62),
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
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.45),
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
                                    : colorScheme.onSurface
                                        .withValues(alpha: 0.55),
                                fontWeight:
                                    overdue ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
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
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground.tomorrow()
      : tomorrow = true,
        markingDone = false;

  const _SwipeBackground.done({required this.markingDone}) : tomorrow = false;

  final bool tomorrow;
  final bool markingDone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = tomorrow
        ? colorScheme.secondaryContainer
        : markingDone
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest;
    final foreground = tomorrow
        ? colorScheme.onSecondaryContainer
        : markingDone
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface;
    final icon = tomorrow
        ? Icons.event_rounded
        : markingDone
            ? Icons.check_rounded
            : Icons.undo_rounded;

    return Container(
      alignment: tomorrow
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      padding: EdgeInsetsDirectional.only(
        start: tomorrow ? 20 : 0,
        end: tomorrow ? 0 : 20,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: foreground),
    );
  }
}
