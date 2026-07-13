import '../models/ai_usage_policy.dart';
import 'ai_routing_service.dart';
import 'ai_usage_service.dart';

/// Pro 1ユーザーあたりの推定AI原価と黒字ライン試算
class ProUserCostEstimate {
  final int roomCount;
  final int deviceCount;
  final double roomImageCostUsd;
  final double marketL2CostUsd;
  final double chatCostUsd;
  final double scannerCostUsd;
  final double maintenanceCostUsd;
  final double totalEstimatedCostUsd;
  final double proRevenueUsd;
  /// ストア手数料30%控除後の実収入
  final double proNetRevenueUsd;
  final double targetMaxCostUsd;
  final double costRatio;
  /// ネット売上に対する原価率
  final double netCostRatio;
  final bool withinTarget;
  final bool withinNetTarget;

  const ProUserCostEstimate({
    required this.roomCount,
    required this.deviceCount,
    required this.roomImageCostUsd,
    required this.marketL2CostUsd,
    required this.chatCostUsd,
    required this.scannerCostUsd,
    required this.maintenanceCostUsd,
    required this.totalEstimatedCostUsd,
    required this.proRevenueUsd,
    required this.proNetRevenueUsd,
    required this.targetMaxCostUsd,
    required this.costRatio,
    required this.netCostRatio,
    required this.withinTarget,
    required this.withinNetTarget,
  });
}

class UnitEconomicsService {
  UnitEconomicsService._();
  static final UnitEconomicsService instance = UnitEconomicsService._();

  static const int proPriceJpy = 490;
  static const double defaultFxJpyPerUsd = 155.0;
  /// 目標粗利率 60% → 実コスト上限は売上の 40%
  static const double targetMaxCostRatio = 0.40;
  /// App Store / Play 手数料（試算用・意思決定保留）
  static const double storeFeeRatio = 0.30;

  double proRevenueUsd({double fxJpyPerUsd = defaultFxJpyPerUsd}) =>
      proPriceJpy / fxJpyPerUsd;

  /// ストア手数料控除後の Pro 実収入（USD）
  double proNetRevenueUsd({double fxJpyPerUsd = defaultFxJpyPerUsd}) =>
      proRevenueUsd(fxJpyPerUsd: fxJpyPerUsd) * (1 - storeFeeRatio);

  double targetMaxAiCostUsd({double fxJpyPerUsd = defaultFxJpyPerUsd}) =>
      proRevenueUsd(fxJpyPerUsd: fxJpyPerUsd) * targetMaxCostRatio;

  /// Pro ユーザーが上限いっぱい使った場合の推定AI原価（インフラ・広告除く）
  Future<ProUserCostEstimate> estimateHeavyProUser({
    required AiUsagePolicy policy,
    int roomCount = 3,
    int deviceCount = 10,
    double fxJpyPerUsd = defaultFxJpyPerUsd,
  }) async {
    final routing = AiRoutingService.instance;
    final roomCredits = routing.defaultCreditsForFeature(AiFeature.roomImage);

    final roomImageRuns = roomCount * policy.proRoomImagePerRoomMonthly;
    final roomImageCredits = roomImageRuns * roomCredits;
    final roomImageCost =
        roomImageCredits * policy.creditCost(AiFeature.roomImage);

    final remainingCredits =
        (policy.proMonthlyCredits - roomImageCredits).clamp(0, policy.proMonthlyCredits);

    // 残りクレジットはプール消費（チャット・L2相場・スキャン等）— 単価はチャット基準で保守試算
    final chatCost =
        remainingCredits * policy.creditCost(AiFeature.chat);
    const marketL2CostUsd = 0.0;
    const scannerCost = 0.0;
    const maintenanceCost = 0.0;

    final uncappedTotal = roomImageCost +
        marketL2CostUsd +
        chatCost +
        scannerCost +
        maintenanceCost;
    // 実運用では Hard Cap が先に効くため、黒字判定はキャップ後コストを用いる
    final total = uncappedTotal.clamp(0.0, policy.hardMonthlyCostCapUsd);
    final revenue = proRevenueUsd(fxJpyPerUsd: fxJpyPerUsd);
    final netRevenue = proNetRevenueUsd(fxJpyPerUsd: fxJpyPerUsd);
    final target = targetMaxAiCostUsd(fxJpyPerUsd: fxJpyPerUsd);
    final netTarget = netRevenue * targetMaxCostRatio;
    final ratio = revenue > 0 ? total / revenue : 0.0;
    final netRatio = netRevenue > 0 ? total / netRevenue : 0.0;

    return ProUserCostEstimate(
      roomCount: roomCount,
      deviceCount: deviceCount,
      roomImageCostUsd: roomImageCost,
      marketL2CostUsd: marketL2CostUsd,
      chatCostUsd: chatCost,
      scannerCostUsd: scannerCost,
      maintenanceCostUsd: maintenanceCost,
      totalEstimatedCostUsd: total,
      proRevenueUsd: revenue,
      proNetRevenueUsd: netRevenue,
      targetMaxCostUsd: target,
      costRatio: ratio,
      netCostRatio: netRatio,
      withinTarget: total <= target,
      withinNetTarget: total <= netTarget,
    );
  }

  /// 月間総AI原価から必要な Pro 会員数（黒字ライン・AI原価のみ）
  int breakEvenProSubscribers({
    required double totalMonthlyAiCostUsd,
    double fxJpyPerUsd = defaultFxJpyPerUsd,
    bool afterStoreFee = false,
  }) {
    final contribution = afterStoreFee
        ? proNetRevenueUsd(fxJpyPerUsd: fxJpyPerUsd) * targetMaxCostRatio
        : targetMaxAiCostUsd(fxJpyPerUsd: fxJpyPerUsd);
    if (contribution <= 0) return 0;
    return (totalMonthlyAiCostUsd / contribution).ceil();
  }

  Future<ProUserCostEstimate> estimateFromEffectivePolicy({
    int roomCount = 3,
    int deviceCount = 10,
    double fxJpyPerUsd = defaultFxJpyPerUsd,
  }) async {
    final policy = await AiUsageService.instance.getEffectivePolicy();
    return estimateHeavyProUser(
      policy: policy,
      roomCount: roomCount,
      deviceCount: deviceCount,
      fxJpyPerUsd: fxJpyPerUsd,
    );
  }
}
