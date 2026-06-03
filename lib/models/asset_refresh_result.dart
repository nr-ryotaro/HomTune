import 'device.dart';
import 'market_refresh_mode.dart';

/// 資産再計算の結果（UI フィードバック用）
class AssetRefreshResult {
  final AssetValue assetValue;
  final MarketRefreshMode mode;
  final bool success;
  final String? message;

  const AssetRefreshResult({
    required this.assetValue,
    required this.mode,
    this.success = true,
    this.message,
  });
}
