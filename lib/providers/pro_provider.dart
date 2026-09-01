import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/revenue_cat_config.dart';
import '../services/revenue_cat_service.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';

class ProStatus {
  const ProStatus({
    required this.isPro,
    this.priceString,
    this.lastRefreshedAt,
  });

  final bool isPro;
  final String? priceString;
  final DateTime? lastRefreshedAt;

  String get unlockLabel =>
      'Unlock for ${priceString ?? AppConstants.defaultProPrice}';

  ProStatus copyWith({
    bool? isPro,
    String? priceString,
    DateTime? lastRefreshedAt,
    bool clearPriceString = false,
  }) {
    return ProStatus(
      isPro: isPro ?? this.isPro,
      priceString: clearPriceString ? null : (priceString ?? this.priceString),
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
    );
  }
}

final proProvider = StateNotifierProvider<ProNotifier, ProStatus>((ref) {
  return ProNotifier(
    ref.watch(storageServiceProvider),
    ref.watch(revenueCatServiceProvider),
  );
});

class ProNotifier extends StateNotifier<ProStatus> {
  ProNotifier(this._storage, this._revenueCat)
      : super(
          ProStatus(
            isPro: _storage.loadIsPro(),
            lastRefreshedAt: _storage.loadProRefreshedAt(),
          ),
        ) {
    _customerInfoListener = (customerInfo) {
      if (_syncingPurchase) {
        return;
      }
      _applyCustomerInfo(customerInfo, source: 'listener');
    };
    if (_revenueCat.isConfigured) {
      _revenueCat.addCustomerInfoListener(_customerInfoListener);
    }
    _bootstrap();
  }

  final StorageService _storage;
  final RevenueCatService _revenueCat;
  late final CustomerInfoUpdateListener _customerInfoListener;
  bool _syncingPurchase = false;

  Future<PurchaseActionResult> purchasePro() async {
    if (!_revenueCat.isConfigured) {
      return const PurchaseActionFailure(
        'Purchases are not available on this device yet.',
      );
    }

    _syncingPurchase = true;
    try {
      final offering = await _revenueCat.getCurrentOffering();
      if (offering == null) {
        return const PurchaseActionFailure(
          'No offer is available right now. Try again later.',
        );
      }

      final package = _revenueCat.resolveLifetimePackage(offering);
      if (package == null) {
        return const PurchaseActionFailure(
          'Pro product is not available right now.',
        );
      }

      final result = await _revenueCat.purchasePackage(package);
      await _applyCustomerInfo(result.customerInfo, source: 'purchase');

      if (!state.isPro) {
        final refreshed = await _revenueCat.refreshCustomerInfo();
        await _applyCustomerInfo(refreshed, source: 'purchase-refresh');
      }

      if (!state.isPro) {
        return const PurchaseActionFailure(
          'Purchase completed, but Pro is not active yet.',
        );
      }
      return const PurchaseActionSuccess();
    } catch (error) {
      final code = purchasesErrorCodeFrom(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseActionCancelled();
      }
      return PurchaseActionFailure(userFacingPurchaseError(error));
    } finally {
      _syncingPurchase = false;
    }
  }

  Future<PurchaseActionResult> restorePurchases() async {
    if (!_revenueCat.isConfigured) {
      return const PurchaseActionFailure(
        'Purchases are not available on this device yet.',
      );
    }

    _syncingPurchase = true;
    try {
      final customerInfo = await _revenueCat.restorePurchases();
      await _applyCustomerInfo(customerInfo, source: 'restore');

      if (!state.isPro) {
        final refreshed = await _revenueCat.refreshCustomerInfo();
        await _applyCustomerInfo(refreshed, source: 'restore-refresh');
      }

      if (state.isPro) {
        return const PurchaseActionSuccess();
      }
      return const PurchaseActionNoPurchase();
    } catch (error) {
      return PurchaseActionFailure(userFacingPurchaseError(error));
    } finally {
      _syncingPurchase = false;
    }
  }

  Future<void> refreshOfferings() async {
    if (!_revenueCat.isConfigured) {
      return;
    }
    try {
      final offering = await _revenueCat.getCurrentOffering();
      final package =
          offering == null ? null : _revenueCat.resolveLifetimePackage(offering);
      final price = package?.storeProduct.priceString;
      if (price != null && price.isNotEmpty) {
        state = state.copyWith(priceString: price);
      }
    } catch (_) {}
  }

  Future<void> unlockProForTesting() async {
    state = state.copyWith(isPro: true, lastRefreshedAt: DateTime.now());
    await _storage.saveProStatus(
      isPro: true,
      refreshedAt: DateTime.now(),
    );
  }

  Future<void> resetProForTesting() async {
    if (_revenueCat.isConfigured) {
      _syncingPurchase = true;
      try {
        try {
          await _revenueCat.logOut();
        } catch (_) {
          await _revenueCat.switchToFreshTestUser();
        }
      } finally {
        _syncingPurchase = false;
      }
    }

    state = state.copyWith(isPro: false, lastRefreshedAt: DateTime.now());
    await _storage.saveProStatus(
      isPro: false,
      refreshedAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    if (_revenueCat.isConfigured) {
      _revenueCat.removeCustomerInfoListener(_customerInfoListener);
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!_revenueCat.isConfigured) {
      return;
    }
    try {
      final customerInfo = await _revenueCat.getCustomerInfo();
      await _applyCustomerInfo(customerInfo, source: 'bootstrap');
      await refreshOfferings();
    } catch (_) {}
  }

  Future<void> _applyCustomerInfo(
    CustomerInfo customerInfo, {
    required String source,
  }) async {
    _revenueCat.logEntitlements(customerInfo, source);
    final isPro = _revenueCat.hasProEntitlement(customerInfo);
    debugPrint('[Pro][$source] setting isPro=$isPro');
    debugPrint(
      '[Pro][$source] accepted entitlement IDs: '
      '${RevenueCatConfig.proEntitlementIds}',
    );
    final now = DateTime.now();
    state = state.copyWith(isPro: isPro, lastRefreshedAt: now);
    await _storage.saveProStatus(isPro: isPro, refreshedAt: now);
  }
}
