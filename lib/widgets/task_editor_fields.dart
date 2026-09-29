import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../models/recurrence.dart';
import 'pro_badge.dart';

class EditorSectionCard extends StatelessWidget {
  const EditorSectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class EditorDateRow extends StatelessWidget {
  const EditorDateRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      onTap: onTap,
      trailing: onClear == null
          ? const Icon(Icons.chevron_right_rounded)
          : IconButton(
              tooltip: 'Clear',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            ),
      subtitleTextStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
      ),
    );
  }
}

class RecurrenceCard extends StatelessWidget {
  const RecurrenceCard({
    super.key,
    required this.recurrence,
    required this.enabled,
    required this.onChanged,
    required this.onLockedTap,
  });

  final Recurrence recurrence;
  final bool enabled;
  final ValueChanged<Recurrence> onChanged;
  final VoidCallback onLockedTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? null : onLockedTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.repeat_rounded,
                    size: 20,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Repeat',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  if (!enabled) const ProBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                enabled
                    ? _helperText(recurrence)
                    : 'Unlock Pro to repeat chores automatically.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Opacity(
                opacity: enabled ? 1 : 0.58,
                child: IgnorePointer(
                  ignoring: !enabled,
                  child: _RepeatControls(
                    recurrence: recurrence,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _helperText(Recurrence recurrence) {
    switch (recurrence.kind) {
      case RecurrenceKind.none:
        return 'One-time task. It stays done when you finish it.';
      case RecurrenceKind.everyNDays:
        final days = recurrence.intervalDays < 1 ? 1 : recurrence.intervalDays;
        return days == 1
            ? 'After you finish it, it comes back tomorrow.'
            : 'After you finish it, it comes back in $days days.';
      case RecurrenceKind.weekly:
        return 'After you finish it, it comes back next '
            '${_weekdayWord(recurrence.weekday ?? DateTime.now().weekday)}.';
    }
  }

  String _weekdayWord(int weekday) {
    const labels = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return labels[weekday - 1];
  }
}

class _RepeatControls extends StatelessWidget {
  const _RepeatControls({
    required this.recurrence,
    required this.onChanged,
  });

  final Recurrence recurrence;
  final ValueChanged<Recurrence> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Off'),
              selected: recurrence.kind == RecurrenceKind.none,
              onSelected: (_) => onChanged(const Recurrence()),
            ),
            ChoiceChip(
              label: const Text('Every few days'),
              selected: recurrence.kind == RecurrenceKind.everyNDays,
              onSelected: (_) => onChanged(
                recurrence.copyWith(
                  kind: RecurrenceKind.everyNDays,
                  intervalDays: recurrence.intervalDays < 1
                      ? AppConstants.defaultEveryNDays
                      : recurrence.intervalDays,
                  clearWeekday: true,
                ),
              ),
            ),
            ChoiceChip(
              label: const Text('Weekly'),
              selected: recurrence.kind == RecurrenceKind.weekly,
              onSelected: (_) => onChanged(
                recurrence.copyWith(
                  kind: RecurrenceKind.weekly,
                  weekday: recurrence.weekday ?? DateTime.now().weekday,
                ),
              ),
            ),
          ],
        ),
        if (recurrence.kind == RecurrenceKind.everyNDays) ...[
          const SizedBox(height: 16),
          Text(
            'How often?',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: recurrence.intervalDays > 1
                    ? () => onChanged(
                          recurrence.copyWith(
                            intervalDays: recurrence.intervalDays - 1,
                          ),
                        )
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Text(
                  recurrence.intervalDays == 1
                      ? 'Every day'
                      : 'Every ${recurrence.intervalDays} days',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => onChanged(
                  recurrence.copyWith(
                    intervalDays: recurrence.intervalDays + 1,
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
        if (recurrence.kind == RecurrenceKind.weekly) ...[
          const SizedBox(height: 16),
          Text(
            'Which day?',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var weekday = 1; weekday <= 7; weekday++)
                ChoiceChip(
                  label: Text(_weekdayLabel(weekday)),
                  selected: recurrence.weekday == weekday,
                  onSelected: (_) => onChanged(
                    recurrence.copyWith(weekday: weekday),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }
}
