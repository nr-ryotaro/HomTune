import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// HomTune API プロキシ設定
class RemoteApiConfig {
  RemoteApiConfig._();

  static const String _baseUrlFromEnv = String.fromEnvironment(
    'HOMTUNE_API_BASE_URL',
    defaultValue: '',
  );

  /// 開発: Android エミュレータは 10.0.2.2、実機は LAN IP を dart-define で指定
  static String get baseUrl {
    if (_baseUrlFromEnv.isNotEmpty) return _baseUrlFromEnv;
    if (kIsWeb) return 'http://localhost:8787';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8787';
    }
    return 'http://localhost:8787';
  }

  static const String devUserId = 'homtune-dev-user';
}
