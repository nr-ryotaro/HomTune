enum SubscriptionTier {
  free,
  pro,
}

enum AiFeature {
  chat,
  roomImage,
  scanner,
  maintenance,
  marketValuation,
}

class AiUsagePolicy {
  final int freeMonthlyCredits;
  final int proMonthlyCredits;
  final int freeRoomImageLifetimePerRoom;
  final int proRoomImagePerRoomMonthly;
  final double softMonthlyCostWarnUsd;
  final double hardMonthlyCostCapUsd;
  final double chatCreditCostUsd;
  final double roomImageCreditCostUsd;
  final double scannerCreditCostUsd;
  final double maintenanceCreditCostUsd;
  final double marketValuationCreditCostUsd;
  /// Pro: L1 相場DB参照の月間回数（AIクレジットとは別枠）
  final int proMonthlyMarketLookups;

  const AiUsagePolicy({
    this.freeMonthlyCredits = 40,
    this.proMonthlyCredits = 120,
    this.freeRoomImageLifetimePerRoom = 1,
    this.proRoomImagePerRoomMonthly = 2,
    this.softMonthlyCostWarnUsd = 1.2,
    this.hardMonthlyCostCapUsd = 2.0,
    this.chatCreditCostUsd = 0.010,
    this.roomImageCreditCostUsd = 0.050,
    this.scannerCreditCostUsd = 0.020,
    this.maintenanceCreditCostUsd = 0.015,
    this.marketValuationCreditCostUsd = 0.010,
    this.proMonthlyMarketLookups = 10,
  });

  int monthlyCreditLimit(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.pro:
        return proMonthlyCredits;
      case SubscriptionTier.free:
        return freeMonthlyCredits;
    }
  }

  int roomImageLimitForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return freeRoomImageLifetimePerRoom;
      case SubscriptionTier.pro:
        return proRoomImagePerRoomMonthly;
    }
  }

  double creditCost(AiFeature feature) {
    switch (feature) {
      case AiFeature.chat:
        return chatCreditCostUsd;
      case AiFeature.roomImage:
        return roomImageCreditCostUsd;
      case AiFeature.scanner:
        return scannerCreditCostUsd;
      case AiFeature.maintenance:
        return maintenanceCreditCostUsd;
      case AiFeature.marketValuation:
        return marketValuationCreditCostUsd;
    }
  }

  AiUsagePolicy copyWith({
    int? freeMonthlyCredits,
    int? proMonthlyCredits,
    int? freeRoomImageLifetimePerRoom,
    int? proRoomImagePerRoomMonthly,
    double? softMonthlyCostWarnUsd,
    double? hardMonthlyCostCapUsd,
    double? chatCreditCostUsd,
    double? roomImageCreditCostUsd,
    double? scannerCreditCostUsd,
    double? maintenanceCreditCostUsd,
  }) {
    return AiUsagePolicy(
      freeMonthlyCredits: freeMonthlyCredits ?? this.freeMonthlyCredits,
      proMonthlyCredits: proMonthlyCredits ?? this.proMonthlyCredits,
      freeRoomImageLifetimePerRoom:
          freeRoomImageLifetimePerRoom ?? this.freeRoomImageLifetimePerRoom,
      proRoomImagePerRoomMonthly:
          proRoomImagePerRoomMonthly ?? this.proRoomImagePerRoomMonthly,
      softMonthlyCostWarnUsd:
          softMonthlyCostWarnUsd ?? this.softMonthlyCostWarnUsd,
      hardMonthlyCostCapUsd: hardMonthlyCostCapUsd ?? this.hardMonthlyCostCapUsd,
      chatCreditCostUsd: chatCreditCostUsd ?? this.chatCreditCostUsd,
      roomImageCreditCostUsd:
          roomImageCreditCostUsd ?? this.roomImageCreditCostUsd,
      scannerCreditCostUsd: scannerCreditCostUsd ?? this.scannerCreditCostUsd,
      maintenanceCreditCostUsd:
          maintenanceCreditCostUsd ?? this.maintenanceCreditCostUsd,
    );
  }
}

class BillingAutoTuneResult {
  final double scale;
  final double targetCostUsd;
  final double actualCostUsd;
  final int adjustedProMonthlyCredits;
  final int adjustedProRoomImagePerRoomMonthly;
  final double adjustedSoftWarnUsd;
  final double adjustedHardCapUsd;

  const BillingAutoTuneResult({
    required this.scale,
    required this.targetCostUsd,
    required this.actualCostUsd,
    required this.adjustedProMonthlyCredits,
    required this.adjustedProRoomImagePerRoomMonthly,
    required this.adjustedSoftWarnUsd,
    required this.adjustedHardCapUsd,
  });
}

class AiUsageSnapshot {
  final String monthKey;
  final int usedCredits;
  final int creditLimit;
  final double estimatedCostUsd;
  final bool overSoftWarnThreshold;
  final bool overHardCap;

  const AiUsageSnapshot({
    required this.monthKey,
    required this.usedCredits,
    required this.creditLimit,
    required this.estimatedCostUsd,
    required this.overSoftWarnThreshold,
    required this.overHardCap,
  });

  int get remainingCredits => (creditLimit - usedCredits).clamp(0, creditLimit);
}

class AiBudgetCheck {
  final bool allowed;
  final String reason;
  final AiUsageSnapshot snapshot;

  const AiBudgetCheck({
    required this.allowed,
    required this.reason,
    required this.snapshot,
  });
}
