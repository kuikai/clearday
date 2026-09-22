/// RevenueCat public SDK configuration.
class RevenueCatConfig {
  RevenueCatConfig._();

  /// Google Play public SDK key.
  static const String googlePlayApiKey = 'goog_BISECzijSqQkwwqEJKUhGMylSIt';

  /// App Store public SDK key.
  static const String appStoreApiKey = 'appl_QRGJPzvkQnsxslYaqkyYLPmxkdu';

  /// Store product identifier.
  static const String proProductId = 'clearday_pro';

  /// Primary entitlement identifier.
  static const String proEntitlementId = 'pro';

  /// Accepted entitlement IDs (exact match, case-insensitive).
  static const List<String> proEntitlementIds = [
    'pro',
  ];
}
