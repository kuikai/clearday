import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/pro_provider.dart';
import '../../services/revenue_cat_service.dart';

Future<void> showPaywall(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const PaywallScreen(),
      fullscreenDialog: true,
    ),
  );
}

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isPurchasing = false;
  bool _isRestoring = false;
  String? _errorMessage;

  bool get _isBusy => _isPurchasing || _isRestoring;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(proProvider.notifier).refreshOfferings();
    });
  }

  Future<void> _purchase() async {
    if (_isBusy) {
      return;
    }
    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });
    final result = await ref.read(proProvider.notifier).purchasePro();
    if (!mounted) {
      return;
    }
    setState(() => _isPurchasing = false);
    await _handleResult(
      result,
      successMessage: 'Pro unlocked. Enjoy unlimited lists and tasks.',
    );
  }

  Future<void> _restore() async {
    if (_isBusy) {
      return;
    }
    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });
    final result = await ref.read(proProvider.notifier).restorePurchases();
    if (!mounted) {
      return;
    }
    setState(() => _isRestoring = false);
    await _handleResult(
      result,
      successMessage: 'Purchase restored',
      noPurchaseMessage: 'No previous purchase found.',
    );
  }

  Future<void> _handleResult(
    PurchaseActionResult result, {
    required String successMessage,
    String? noPurchaseMessage,
  }) async {
    switch (result) {
      case PurchaseActionSuccess():
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case PurchaseActionCancelled():
        break;
      case PurchaseActionNoPurchase():
        setState(() {
          _errorMessage = noPurchaseMessage ?? 'No previous purchase found.';
        });
      case PurchaseActionFailure(:final message):
        setState(() => _errorMessage = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unlockLabel = ref.watch(
      proProvider.select((status) => status.unlockLabel),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('ClearDay Pro'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 36,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Unlock Full Access',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Keep the free version for light use, or unlock Pro forever.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  const _BenefitRow(
                    icon: Icons.all_inclusive_rounded,
                    title: 'Unlimited tasks',
                    subtitle:
                        'No ${AppConstants.freeActiveTaskLimit}-task cap on active chores',
                  ),
                  const _BenefitRow(
                    icon: Icons.list_alt_rounded,
                    title: 'Unlimited groups',
                    subtitle:
                        'More than ${AppConstants.freeGroupLimit} groups and ${AppConstants.freeSubgroupLimit} subgroups',
                  ),
                  const _BenefitRow(
                    icon: Icons.repeat_rounded,
                    title: 'Recurring tasks',
                    subtitle: 'Every 5 days, weekly, or your own interval',
                  ),
                  const _BenefitRow(
                    icon: Icons.notifications_active_outlined,
                    title: 'Full reminder control',
                    subtitle: 'Custom reminder times, not only at due',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isBusy ? null : _purchase,
            child: _isPurchasing
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Text(unlockLabel),
          ),
          const SizedBox(height: 10),
          Text(
            AppConstants.oneTimePurchaseCopy,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isBusy ? null : _restore,
            child: _isRestoring
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: colorScheme.primary,
                    ),
                  )
                : const Text('Restore Purchase'),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
