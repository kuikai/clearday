import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pro_provider.dart';
import '../services/revenue_cat_service.dart';

class RestorePurchaseButton extends ConsumerStatefulWidget {
  const RestorePurchaseButton({super.key});

  @override
  ConsumerState<RestorePurchaseButton> createState() =>
      _RestorePurchaseButtonState();
}

class _RestorePurchaseButtonState extends ConsumerState<RestorePurchaseButton> {
  bool _isRestoring = false;

  Future<void> _restore() async {
    if (_isRestoring) {
      return;
    }
    setState(() => _isRestoring = true);
    final result = await ref.read(proProvider.notifier).restorePurchases();
    if (!mounted) {
      return;
    }
    setState(() => _isRestoring = false);

    final message = switch (result) {
      PurchaseActionSuccess() => 'Purchase restored',
      PurchaseActionNoPurchase() => 'No previous purchase found.',
      PurchaseActionCancelled() => null,
      PurchaseActionFailure(:final message) => message,
    };
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _isRestoring ? null : _restore,
      child: _isRestoring
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          : const Text('Restore Purchase'),
    );
  }
}
