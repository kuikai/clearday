import 'package:flutter/material.dart';

import '../core/date_utils.dart';
import '../models/task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onOpen,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
    );
  }
}
