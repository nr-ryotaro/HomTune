import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_policy.dart';
import 'analytics_service.dart';

/// AdMob 初期化（モバイルのみ）
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  bool _initialized = false;
  bool _initFailed = false;

  bool get isReady => _initialized && !_initFailed;

  Future<void> initialize() async {
    if (_initialized || _initFailed) return;
    if (!AdPolicy.supportsBannerAds) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      await AnalyticsService.logEvent(
        event: 'ad_sdk_initialized',
        properties: {'platform': defaultTargetPlatform.name},
      );
    } catch (e, st) {
      _initFailed = true;
      debugPrint('AdMob initialize failed: $e\n$st');
    }
  }

  Future<void> ensureInitialized() async {
    if (!_initialized && !_initFailed) {
      await initialize();
    }
  }

  Future<void> logBannerLoaded(String placement) async {
    await AnalyticsService.logEvent(
      event: 'ad_banner_loaded',
      properties: {'placement': placement},
    );
  }

  Future<void> logBannerFailed(String placement, String code) async {
    await AnalyticsService.logEvent(
      event: 'ad_banner_failed',
      properties: {'placement': placement, 'code': code},
    );
  }
}
