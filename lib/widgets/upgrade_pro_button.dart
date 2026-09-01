import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pro_provider.dart';
import '../screens/paywall/paywall_screen.dart';

class UpgradeProButton extends ConsumerWidget {
  const UpgradeProButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(proProvider.select((status) => status.isPro));
    if (isPro) {
      return const SizedBox.shrink();
    }

    return OutlinedButton.icon(
      onPressed: () => showPaywall(context),
      icon: const Icon(Icons.workspace_premium_rounded),
      label: const Text('Upgrade to Pro'),
    );
  }
}
