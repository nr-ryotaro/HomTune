import '../../models/ai_usage_policy.dart';
import '../../utils/platform_support.dart';
import '../config_service.dart';

/// Pro 限定・Web UI プレビュー・debounce
class RemoteControlPolicy {
  RemoteControlPolicy._();

  static const Duration commandDebounce = Duration(seconds: 3);
  static DateTime? _lastCommandAt;
  static String? _lastCommandKey;

  /// リモコン UI の表示（Web プレビュー含む）
  static bool get supportsRemoteControlUi => true;

  /// Remo / SwitchBot への実 API 送信（Web では不可）
  static bool get supportsRemoteControlApi => !PlatformSupport.isWebUiPreview;

  /// 後方互換 — UI 表示可否
  static bool get supportsRemoteControl => supportsRemoteControlUi;

  /// Web プレビューでコマンドをシミュレートするか
  static bool get simulatesCommands => PlatformSupport.isWebUiPreview;

  static bool canUseRemoteControl(ConfigService config) {
    if (!supportsRemoteControlApi) return false;
    return config.subscriptionTier == SubscriptionTier.pro;
  }

  static bool canDebounceCommand(String key) {
    final now = DateTime.now();
    if (_lastCommandKey == key &&
        _lastCommandAt != null &&
        now.difference(_lastCommandAt!) < commandDebounce) {
      return false;
    }
    _lastCommandKey = key;
    _lastCommandAt = now;
    return true;
  }

  static void resetDebounceForTest() {
    _lastCommandAt = null;
    _lastCommandKey = null;
  }
}
