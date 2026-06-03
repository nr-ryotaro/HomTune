import 'package:flutter/foundation.dart';

/// AdMob ユニット ID（本番は --dart-define で上書き）
class AdMobConfig {
  AdMobConfig._();

  static const String _androidBannerFromEnv = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
    defaultValue: '',
  );
  static const String _iosBannerFromEnv = String.fromEnvironment(
    'ADMOB_IOS_BANNER_ID',
    defaultValue: '',
  );

  /// Google 公式テスト ID（デバッグ・未設定時）
  static const String testAndroidBannerId =
      'ca-app-pub-3940256099942544/9214589761';
  static const String testIosBannerId =
      'ca-app-pub-3940256099942544/2934735716';

  static const String testAndroidAppId =
      'ca-app-pub-3940256099942544~3347511713';

  /// 未設定の release では null（テスト ID の誤配信を防ぐ）
  static String? bannerAdUnitId(TargetPlatform platform) {
    if (platform == TargetPlatform.iOS) {
      if (_iosBannerFromEnv.isNotEmpty) return _iosBannerFromEnv;
      return kReleaseMode ? null : testIosBannerId;
    }
    if (_androidBannerFromEnv.isNotEmpty) return _androidBannerFromEnv;
    return kReleaseMode ? null : testAndroidBannerId;
  }
}
