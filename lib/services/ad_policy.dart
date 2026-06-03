import 'package:flutter/foundation.dart';

import '../models/ai_usage_policy.dart';
import 'config_service.dart';

/// Free プラン向けバナー広告の表示ポリシー
class AdPolicy {
  AdPolicy._();

  static bool _enabledInTests = true;

  @visibleForTesting
  static void setEnabledInTests(bool value) {
    _enabledInTests = value;
  }

  static bool get supportsBannerAds {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      default:
        return false;
    }
  }

  static bool shouldShowFor(ConfigService config) {
    if (!_enabledInTests) return false;
    if (!supportsBannerAds) return false;
    if (config.subscriptionTier == SubscriptionTier.pro) return false;
    return true;
  }

  /// 広告を出さない画面（資産詳細・オンボーディング等）
  static const Set<String> blockedPlacements = {
    'onboarding',
    'device_detail',
    'add_appliance',
    'scan',
    'maintenance',
    'dev_settings',
  };

  static bool isPlacementAllowed(String placement) {
    return !blockedPlacements.contains(placement);
  }
}
