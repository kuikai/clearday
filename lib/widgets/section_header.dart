import 'package:flutter/material.dart';

import '../core/motion.dart';

/// Quiet section label used on group and task lists.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.progressLabel,
    this.accent,
    this.action,
  });

  final String title;
  final int? count;

  /// e.g. "4/6 done" — shown instead of [count] when set.
  final String? progressLabel;
  final Color? accent;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final trailing = progressLabel ?? (count != null ? '$count' : null);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
          if (action != null) ...[const Spacer(), action!],
        ],
      ),
    );
  }
}

/// Chevron that turns as a section opens or closes.
class ExpandChevron extends StatelessWidget {
  const ExpandChevron({
    super.key,
    required this.expanded,
    this.icon = Icons.expand_more,
    this.color,
  });

  final bool expanded;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint =
        color ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    return AnimatedRotation(
      turns: expanded ? 0.5 : 0,
      duration: Motion.short,
      curve: Motion.ease,
      child: Icon(icon, color: tint),
    );
  }
}
