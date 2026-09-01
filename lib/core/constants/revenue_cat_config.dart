/// RevenueCat public SDK configuration.
///
/// Android release builds use [googlePlayApiKey] (RevenueCat → Project Settings
/// → API keys → Google Play). Add an App Store key here when shipping iOS.
class RevenueCatConfig {
  RevenueCatConfig._();

  /// Google Play public SDK key (RevenueCat → Project Settings → API keys).
  static const String googlePlayApiKey = 'goog_BISECzijSqQkwwqEJKUhGMylSIt';

  /// Store product identifier configured in Play Console / RevenueCat.
  static const String proProductId = 'clearday_pro';

  /// Primary entitlement identifier from the RevenueCat dashboard.
  static const String proEntitlementId = 'pro';

  /// Accepted entitlement IDs (exact match, case-insensitive).
  static const List<String> proEntitlementIds = [
    'pro',
  ];
}
