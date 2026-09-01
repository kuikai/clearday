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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final taskLabel =
        '${data.activeTaskCount} of ${AppConstants.freeActiveTaskLimit} free tasks';
    final groupLabel =
        '${data.topLevelGroupCount} of ${AppConstants.freeGroupLimit} groups';
    final subgroupLabel =
        '${data.subgroupCount} of ${AppConstants.freeSubgroupLimit} subgroups';

    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showPaywall(context),
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
                    '$taskLabel · $groupLabel · $subgroupLabel',
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
