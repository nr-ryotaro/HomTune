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

/// AI利用不可の理由（Free→Pro / Pro→追加クレジット導線用）
enum AiExhaustionReason {
  none,
  realApiOff,
  hardCap,
  monthlyCredits,
  roomQuotaFree,
  roomQuotaPro,
}

/// Pro 専用の追加クレジットパック（IAP 連携前の定義）
class CreditAddonPack {
  final String id;
  final int credits;
  final int priceJpy;

  const CreditAddonPack({
    required this.id,
    required this.credits,
    required this.priceJpy,
  });
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
  /// Free で登録できる最大部屋数（13LDK 等の悪用防止）
  final int maxRoomsFree;
  /// Pro で登録できる最大部屋数（追加部屋は枠内で画像クォータ適用）
  final int maxRoomsPro;

  /// 部屋画像は Gemini テキスト1回＋端末内描画（Imagen 等は未使用）
  static const int roomImageCreditsPerGeneration = 2;

  /// Pro 専用追加クレジット（Free は Pro へ誘導）
  static const List<CreditAddonPack> proAddonPacks = [
    CreditAddonPack(id: 'addon_50', credits: 50, priceJpy: 350),
    CreditAddonPack(id: 'addon_120', credits: 120, priceJpy: 780),
  ];

  const AiUsagePolicy({
    this.freeMonthlyCredits = 40,
    this.proMonthlyCredits = 120,
    this.freeRoomImageLifetimePerRoom = 1,
    this.proRoomImagePerRoomMonthly = 2,
    this.softMonthlyCostWarnUsd = 0.95,
    this.hardMonthlyCostCapUsd = 1.25,
    this.chatCreditCostUsd = 0.010,
    this.roomImageCreditCostUsd = 0.012,
    this.scannerCreditCostUsd = 0.020,
    this.maintenanceCreditCostUsd = 0.015,
    this.marketValuationCreditCostUsd = 0.010,
    this.proMonthlyMarketLookups = 10,
    this.maxRoomsFree = 5,
    this.maxRoomsPro = 10,
  });

  int maxRoomsForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.pro:
        return maxRoomsPro;
      case SubscriptionTier.free:
        return maxRoomsFree;
    }
  }

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
  final AiExhaustionReason exhaustionReason;

  const AiBudgetCheck({
    required this.allowed,
    required this.reason,
    required this.snapshot,
    this.exhaustionReason = AiExhaustionReason.none,
  });
}
