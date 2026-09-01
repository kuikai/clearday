import 'package:clearday/services/revenue_cat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Fake purchases SDK. Never talks to the store.
class FakeRevenueCatService extends RevenueCatService {
  FakeRevenueCatService({this.configured = false});

  final bool configured;

  @override
  bool get isConfigured => configured;

  @override
  Future<void> initialize() async {}

  @override
  void addCustomerInfoListener(CustomerInfoUpdateListener listener) {}

  @override
  void removeCustomerInfoListener(CustomerInfoUpdateListener listener) {}
}
