import '../models/ai_usage_policy.dart';
import 'ai_usage_service.dart';
import 'analytics_service.dart';

class BillingControlService {
  static const double _defaultFxJpyPerUsd = 155.0;
  static const int _proPriceJpy = 490;
  static const double _targetCostRatio = 0.45; // cost / revenue
  static const double _minScale = 0.5;
  static const double _maxScale = 1.1;

  /// 実請求データから翌月の上限を自動再計算して適用
  ///
  /// [actualCostUsd]: 当月の実コスト（請求ベース）
  /// [proSubscriberCount]: 当月の有料会員数
  /// [fxJpyPerUsd]: 為替（JPY/USD）
  Future<BillingAutoTuneResult> autoTuneFromActualBilling({
    required double actualCostUsd,
    required int proSubscriberCount,
    double fxJpyPerUsd = _defaultFxJpyPerUsd,
  }) async {
    final usageService = AiUsageService.instance;
    final base = await usageService.getEffectivePolicy();

    final revenueJpy = proSubscriberCount * _proPriceJpy;
    final revenueUsd = revenueJpy / fxJpyPerUsd;
    final targetCostUsd = revenueUsd * _targetCostRatio;

    double scale;
    if (actualCostUsd <= 0 || targetCostUsd <= 0) {
      scale = _minScale;
    } else {
      scale = (targetCostUsd / actualCostUsd).clamp(_minScale, _maxScale);
    }

    final adjustedProCredits =
        (base.proMonthlyCredits * scale).round().clamp(40, 300);
    final adjustedProRoomImage =
        (base.proRoomImagePerRoomMonthly * scale).round().clamp(1, 3);
    final adjustedSoftWarn =
        (base.softMonthlyCostWarnUsd * scale).clamp(0.5, 10.0);
    final adjustedHardCap =
        (base.hardMonthlyCostCapUsd * scale).clamp(0.8, 15.0);

    await usageService.applyPolicyOverride(
      proMonthlyCredits: adjustedProCredits,
      proRoomImagePerRoomMonthly: adjustedProRoomImage,
      softMonthlyCostWarnUsd: adjustedSoftWarn,
      hardMonthlyCostCapUsd: adjustedHardCap,
    );

    await AnalyticsService.logEvent(
      event: 'billing_auto_tuned',
      properties: {
        'actualCostUsd': actualCostUsd,
        'proSubscriberCount': proSubscriberCount,
        'revenueUsd': revenueUsd,
        'targetCostUsd': targetCostUsd,
        'scale': scale,
        'adjustedProCredits': adjustedProCredits,
        'adjustedProRoomImagePerRoomMonthly': adjustedProRoomImage,
      },
    );

    return BillingAutoTuneResult(
      scale: scale,
      targetCostUsd: targetCostUsd,
      actualCostUsd: actualCostUsd,
      adjustedProMonthlyCredits: adjustedProCredits,
      adjustedProRoomImagePerRoomMonthly: adjustedProRoomImage,
      adjustedSoftWarnUsd: adjustedSoftWarn,
      adjustedHardCapUsd: adjustedHardCap,
    );
  }
}
