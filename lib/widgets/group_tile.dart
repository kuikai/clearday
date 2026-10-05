import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/task_group.dart';

class GroupTile extends StatelessWidget {
  const GroupTile({
    super.key,
    required this.group,
    required this.activeCount,
    required this.overdueCount,
    required this.dueTodayCount,
    required this.onOpen,
    required this.onRename,
    required this.onCopy,
    required this.onDelete,
    this.onAddSubgroup,
    this.isSubgroup = false,
  });

  final TaskGroup group;
  final int activeCount;
  final int overdueCount;
  final int dueTodayCount;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback? onAddSubgroup;
  final bool isSubgroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = _GroupStatus.fromCounts(
      overdueCount: overdueCount,
      dueTodayCount: dueTodayCount,
      colorScheme: colorScheme,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: status.border),
        ),
        child: InkWell(
          onTap: onOpen,
          onLongPress: onRename,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: status.iconBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isSubgroup
                        ? Icons.folder_copy_outlined
                        : Icons.folder_outlined,
                    color: status.iconForeground,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: status.titleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaChip(
                            label: activeCount == 1
                                ? '1 active task'
                                : '$activeCount active tasks',
                          ),
                          if (status.isOverdue)
                            _MetaChip(
                              label: overdueCount == 1
                                  ? '1 overdue'
                                  : '$overdueCount overdue',
                              kind: _ChipKind.overdue,
                            ),
                          if (status.isDueToday)
                            _MetaChip(
                              label: dueTodayCount == 1
                                  ? '1 due today'
                                  : '$dueTodayCount due today',
                              kind: _ChipKind.dueToday,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Group options',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'subgroup':
                        onAddSubgroup?.call();
                      case 'rename':
                        onRename();
                      case 'copy':
                        onCopy();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onAddSubgroup != null)
                      const PopupMenuItem(
                        value: 'subgroup',
                        child: Text('Add subgroup'),
                      ),
                    const PopupMenuItem(
                      value: 'rename',
                      child: Text('Rename'),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Text('Copy'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupStatus {
  const _GroupStatus({
    required this.border,
    required this.iconBackground,
    required this.iconForeground,
    required this.titleColor,
    required this.isOverdue,
    required this.isDueToday,
  });

  final Color border;
  final Color iconBackground;
  final Color iconForeground;
  final Color? titleColor;
  final bool isOverdue;
  final bool isDueToday;

  factory _GroupStatus.fromCounts({
    required int overdueCount,
    required int dueTodayCount,
    required ColorScheme colorScheme,
  }) {
    if (overdueCount > 0) {
      return _GroupStatus(
        border: colorScheme.error.withValues(alpha: 0.55),
        iconBackground: colorScheme.errorContainer.withValues(alpha: 0.85),
        iconForeground: colorScheme.onErrorContainer,
        titleColor: colorScheme.error,
        isOverdue: true,
        isDueToday: false,
      );
    }
    if (dueTodayCount > 0) {
      return _GroupStatus(
        border: AppColors.dueToday.withValues(alpha: 0.55),
        iconBackground: AppColors.dueTodayContainer,
        iconForeground: AppColors.onDueTodayContainer,
        titleColor: AppColors.dueToday,
        isOverdue: false,
        isDueToday: true,
      );
    }
    return _GroupStatus(
      border: colorScheme.outlineVariant.withValues(alpha: 0.9),
      iconBackground: colorScheme.primaryContainer.withValues(alpha: 0.7),
      iconForeground: colorScheme.onPrimaryContainer,
      titleColor: null,
      isOverdue: false,
      isDueToday: false,
    );
  }
}

enum _ChipKind { normal, overdue, dueToday }

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    this.kind = _ChipKind.normal,
  });

  final String label;
  final _ChipKind kind;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (kind) {
      _ChipKind.overdue => (
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
        ),
      _ChipKind.dueToday => (
          AppColors.dueTodayContainer,
          AppColors.onDueTodayContainer,
        ),
      _ChipKind.normal => (
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          colorScheme.onSurface.withValues(alpha: 0.7),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
