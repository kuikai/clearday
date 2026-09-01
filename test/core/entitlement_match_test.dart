import 'package:clearday/core/constants/revenue_cat_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Play release config uses pro entitlement and clearday_pro product', () {
    expect(RevenueCatConfig.proEntitlementId, 'pro');
    expect(RevenueCatConfig.proEntitlementIds, contains('pro'));
    expect(RevenueCatConfig.proProductId, 'clearday_pro');
    expect(RevenueCatConfig.googlePlayApiKey, startsWith('goog_'));
  });
}
