import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../models/recurrence.dart';
import 'pro_badge.dart';

const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _weekdayLong = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

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
        return _weeklyHelper(recurrence.selectedWeekdays);
    }
  }

  String _weeklyHelper(List<int> weekdays) {
    final days = weekdays.isEmpty ? [DateTime.now().weekday] : weekdays;
    final names = [for (final day in days) _weekdayLong[day - 1]];
    if (names.length == 1) {
      return 'After you finish it, it comes back next ${names.single}.';
    }
    final listed = names.length == 2
        ? '${names[0]} or ${names[1]}'
        : '${names.sublist(0, names.length - 1).join(', ')}, or ${names.last}';
    return 'After you finish it, it comes back the next $listed.';
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
                  clearWeekdays: true,
                ),
              ),
            ),
            ChoiceChip(
              label: const Text('Weekly'),
              selected: recurrence.kind == RecurrenceKind.weekly,
              onSelected: (_) => onChanged(
                recurrence.copyWith(
                  kind: RecurrenceKind.weekly,
                  weekdays: recurrence.selectedWeekdays.isEmpty
                      ? [DateTime.now().weekday]
                      : recurrence.selectedWeekdays,
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
            'Which days?',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _WeekdayToggles(
            selected: recurrence.selectedWeekdays,
            onToggle: (weekday) => onChanged(
              recurrence.toggleWeekday(weekday),
            ),
          ),
        ],
      ],
    );
  }
}

class _WeekdayToggles extends StatelessWidget {
  const _WeekdayToggles({
    required this.selected,
    required this.onToggle,
  });

  final List<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var weekday = DateTime.monday;
            weekday <= DateTime.sunday;
            weekday++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: weekday == DateTime.monday ? 0 : 4,
              ),
              child: _WeekdayToggle(
                label: _weekdayShort[weekday - 1],
                fullName: _weekdayLong[weekday - 1],
                selected: selected.contains(weekday),
                onPressed: () => onToggle(weekday),
              ),
            ),
          ),
      ],
    );
  }
}

class _WeekdayToggle extends StatelessWidget {
  const _WeekdayToggle({
    required this.label,
    required this.fullName,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final String fullName;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = selected ? colorScheme.primary : Colors.transparent;
    final foreground = selected ? colorScheme.onPrimary : colorScheme.onSurface;
    final borderColor = selected ? colorScheme.primary : colorScheme.outline;

    return Tooltip(
      message: selected ? '$fullName on' : '$fullName off',
      child: Semantics(
        button: true,
        toggled: selected,
        label: fullName,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: onPressed,
            child: SizedBox(
              height: 48,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
