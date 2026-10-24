import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../providers/pro_provider.dart';
import '../providers/tasks_provider.dart';
import '../screens/paywall/paywall_screen.dart';

/// Shows remaining free tasks and groups. Hidden for Pro users.
class LimitBanner extends ConsumerWidget {
  const LimitBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(proProvider.select((status) => status.isPro));
    if (isPro) {
      return const SizedBox.shrink();
    }

    final data = ref.watch(appDataProvider);
    return _banner(
      context,
      activeTasks: data.activeTaskCount,
      groups: data.topLevelGroupCount,
      subgroups: data.subgroupCount,
    );
  }

  Widget _banner(
    BuildContext context, {
    required int activeTasks,
    required int groups,
    required int subgroups,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summary = _freeLimitBannerText(
      activeTasks: activeTasks,
      groups: groups,
      subgroups: subgroups,
    );
    final reason = _paywallReasonForLimits(
      activeTasks: activeTasks,
      groups: groups,
      subgroups: subgroups,
    );

    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showPaywall(context, reason: reason),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.lock_open_rounded, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    summary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Pro',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LimitPart {
  const _LimitPart({required this.full, required this.label});

  final bool full;
  final String label;
}

String _freeLimitBannerText({
  required int activeTasks,
  required int groups,
  required int subgroups,
}) {
  final parts = [
    _LimitPart(
      full: activeTasks >= AppConstants.freeActiveTaskLimit,
      label: '$activeTasks of ${AppConstants.freeActiveTaskLimit} free tasks',
    ),
    _LimitPart(
      full: groups >= AppConstants.freeGroupLimit,
      label: '$groups of ${AppConstants.freeGroupLimit} groups',
    ),
    _LimitPart(
      full: subgroups >= AppConstants.freeSubgroupLimit,
      label: '$subgroups of ${AppConstants.freeSubgroupLimit} subgroups',
    ),
  ];
  final full = parts.where((part) => part.full);
  final open = parts.where((part) => !part.full);
  return [...full, ...open].map((part) => part.label).join(' · ');
}

PaywallReason _paywallReasonForLimits({
  required int activeTasks,
  required int groups,
  required int subgroups,
}) {
  if (activeTasks >= AppConstants.freeActiveTaskLimit) {
    return PaywallReason.tasks;
  }
  if (groups >= AppConstants.freeGroupLimit) {
    return PaywallReason.groups;
  }
  if (subgroups >= AppConstants.freeSubgroupLimit) {
    return PaywallReason.subgroups;
  }
  return PaywallReason.general;
}
