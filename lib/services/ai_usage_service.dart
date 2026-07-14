import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_usage_policy.dart';
import 'analytics_service.dart';
import 'config_service.dart';
import 'market_price_gemini_service.dart';

class AiUsageService {
  AiUsageService._();

  static final AiUsageService instance = AiUsageService._();
  static const String _usageKey = 'ai_usage_v1';
  static const String _featureCountsKey = 'ai_feature_counts_v1';
  static const String _roomImageLifetimeKey = 'ai_room_image_lifetime_v1';
  static const String _roomImageMonthlyKey = 'ai_room_image_monthly_v1';
  static const String _policyOverrideKey = 'ai_policy_override_v1';

  static const String _bonusCreditsKey = 'ai_bonus_credits_v1';

  final AiUsagePolicy _policy = const AiUsagePolicy();
  SharedPreferences? _prefs;
  bool _loaded = false;

  Map<String, dynamic> _usage = <String, dynamic>{};
  Map<String, dynamic> _featureCounts = <String, dynamic>{};
  Map<String, dynamic> _roomImageLifetime = <String, dynamic>{};
  Map<String, dynamic> _roomImageMonthly = <String, dynamic>{};
  Map<String, dynamic> _policyOverride = <String, dynamic>{};
  Map<String, dynamic> _bonusCredits = <String, dynamic>{};

  void resetForTest() {
    _prefs = null;
    _loaded = false;
    _usage = <String, dynamic>{};
    _featureCounts = <String, dynamic>{};
    _roomImageLifetime = <String, dynamic>{};
    _roomImageMonthly = <String, dynamic>{};
    _policyOverride = <String, dynamic>{};
    _bonusCredits = <String, dynamic>{};
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _prefs = await SharedPreferences.getInstance();
    final usageRaw = _prefs!.getString(_usageKey);
    final featureCountsRaw = _prefs!.getString(_featureCountsKey);
    final roomImageLifetimeRaw = _prefs!.getString(_roomImageLifetimeKey);
    final roomImageMonthlyRaw = _prefs!.getString(_roomImageMonthlyKey);
    final policyOverrideRaw = _prefs!.getString(_policyOverrideKey);
    final bonusCreditsRaw = _prefs!.getString(_bonusCreditsKey);
    if (usageRaw != null && usageRaw.isNotEmpty) {
      _usage = jsonDecode(usageRaw) as Map<String, dynamic>;
    }
    if (featureCountsRaw != null && featureCountsRaw.isNotEmpty) {
      _featureCounts = jsonDecode(featureCountsRaw) as Map<String, dynamic>;
    }
    if (roomImageLifetimeRaw != null && roomImageLifetimeRaw.isNotEmpty) {
      _roomImageLifetime =
          jsonDecode(roomImageLifetimeRaw) as Map<String, dynamic>;
    }
    if (roomImageMonthlyRaw != null && roomImageMonthlyRaw.isNotEmpty) {
      _roomImageMonthly =
          jsonDecode(roomImageMonthlyRaw) as Map<String, dynamic>;
    }
    if (policyOverrideRaw != null && policyOverrideRaw.isNotEmpty) {
      _policyOverride = jsonDecode(policyOverrideRaw) as Map<String, dynamic>;
    }
    if (bonusCreditsRaw != null && bonusCreditsRaw.isNotEmpty) {
      _bonusCredits = jsonDecode(bonusCreditsRaw) as Map<String, dynamic>;
    }
    _loaded = true;
  }

  String _monthKey(DateTime now) =>
      '${now.year}-${now.month.toString().padLeft(2, '0')}';

  SubscriptionTier _tierFromConfig(ConfigService configService) =>
      configService.subscriptionTier;

  Future<void> _save() async {
    await _prefs?.setString(_usageKey, jsonEncode(_usage));
    await _prefs?.setString(_featureCountsKey, jsonEncode(_featureCounts));
    await _prefs?.setString(
      _roomImageLifetimeKey,
      jsonEncode(_roomImageLifetime),
    );
    await _prefs?.setString(
      _roomImageMonthlyKey,
      jsonEncode(_roomImageMonthly),
    );
    await _prefs?.setString(
      _policyOverrideKey,
      jsonEncode(_policyOverride),
    );
    await _prefs?.setString(_bonusCreditsKey, jsonEncode(_bonusCredits));
  }

  Future<int> getBonusCredits() async {
    await _ensureLoaded();
    final monthKey = _monthKey(DateTime.now());
    return (_bonusCredits[monthKey] as num?)?.toInt() ?? 0;
  }

  /// 追加クレジット付与（IAP 検証後 or 開発者設定）
  Future<void> grantBonusCredits(int credits) async {
    if (credits <= 0) return;
    await _ensureLoaded();
    final monthKey = _monthKey(DateTime.now());
    final current = (_bonusCredits[monthKey] as num?)?.toInt() ?? 0;
    _bonusCredits[monthKey] = current + credits;
    await _save();
  }

  Future<int> effectiveCreditLimit(ConfigService configService) async {
    await _ensureLoaded();
    final tier = _tierFromConfig(configService);
    final policy = _effectivePolicy();
    final bonus = await getBonusCredits();
    return policy.monthlyCreditLimit(tier) + bonus;
  }

  AiUsagePolicy _effectivePolicy() {
    return _policy.copyWith(
      proMonthlyCredits: (_policyOverride['proMonthlyCredits'] as num?)?.toInt(),
      proRoomImagePerRoomMonthly:
          (_policyOverride['proRoomImagePerRoomMonthly'] as num?)?.toInt(),
      softMonthlyCostWarnUsd:
          (_policyOverride['softMonthlyCostWarnUsd'] as num?)?.toDouble(),
      hardMonthlyCostCapUsd:
          (_policyOverride['hardMonthlyCostCapUsd'] as num?)?.toDouble(),
    );
  }

  Future<AiUsagePolicy> getEffectivePolicy() async {
    await _ensureLoaded();
    return _effectivePolicy();
  }

  Future<void> applyPolicyOverride({
    int? proMonthlyCredits,
    int? proRoomImagePerRoomMonthly,
    double? softMonthlyCostWarnUsd,
    double? hardMonthlyCostCapUsd,
  }) async {
    await _ensureLoaded();
    if (proMonthlyCredits != null) {
      _policyOverride['proMonthlyCredits'] = proMonthlyCredits;
    }
    if (proRoomImagePerRoomMonthly != null) {
      _policyOverride['proRoomImagePerRoomMonthly'] = proRoomImagePerRoomMonthly;
    }
    if (softMonthlyCostWarnUsd != null) {
      _policyOverride['softMonthlyCostWarnUsd'] = softMonthlyCostWarnUsd;
    }
    if (hardMonthlyCostCapUsd != null) {
      _policyOverride['hardMonthlyCostCapUsd'] = hardMonthlyCostCapUsd;
    }
    await _save();
  }

  int estimateChatCredits(String message) {
    final length = message.trim().length;
    if (length <= 30) return 1;
    if (length <= 120) return 2;
    if (length <= 240) return 3;
    return 4;
  }

  int defaultFeatureCredits(AiFeature feature) {
    switch (feature) {
      case AiFeature.chat:
        return 2;
      case AiFeature.roomImage:
        return AiUsagePolicy.roomImageCreditsPerGeneration;
      case AiFeature.scanner:
        return 3;
      case AiFeature.maintenance:
        return 2;
      case AiFeature.marketValuation:
        return MarketPriceGeminiService.creditCost;
    }
  }

  Future<AiUsageSnapshot> getSnapshot(ConfigService configService) async {
    await _ensureLoaded();
    final monthKey = _monthKey(DateTime.now());
    final tier = _tierFromConfig(configService);
    final policy = _effectivePolicy();
    final record = (_usage[monthKey] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final usedCredits = (record['usedCredits'] as num?)?.toInt() ?? 0;
    final estimatedCostUsd = (record['estimatedCostUsd'] as num?)?.toDouble() ?? 0.0;
    final bonus = await getBonusCredits();
    return AiUsageSnapshot(
      monthKey: monthKey,
      usedCredits: usedCredits,
      creditLimit: policy.monthlyCreditLimit(tier) + bonus,
      estimatedCostUsd: estimatedCostUsd,
      overSoftWarnThreshold: estimatedCostUsd >= policy.softMonthlyCostWarnUsd,
      overHardCap: estimatedCostUsd >= policy.hardMonthlyCostCapUsd,
    );
  }

  Future<AiBudgetCheck> canRunFeature(
    ConfigService configService, {
    required AiFeature feature,
    required int requestedCredits,
  }) async {
    final snapshot = await getSnapshot(configService);
    if (!configService.isCloudAiEnabled) {
      return AiBudgetCheck(
        allowed: false,
        reason: 'クラウドAIがオフです（プロキシまたは実APIを有効にしてください）',
        snapshot: snapshot,
        exhaustionReason: AiExhaustionReason.realApiOff,
      );
    }
    if (snapshot.overHardCap) {
      return AiBudgetCheck(
        allowed: false,
        reason: '月次のコスト上限に到達しました',
        snapshot: snapshot,
        exhaustionReason: AiExhaustionReason.hardCap,
      );
    }
    if (snapshot.usedCredits + requestedCredits > snapshot.creditLimit) {
      return AiBudgetCheck(
        allowed: false,
        reason: '今月のAIクレジットが不足しています',
        snapshot: snapshot,
        exhaustionReason: AiExhaustionReason.monthlyCredits,
      );
    }
    return AiBudgetCheck(
      allowed: true,
      reason: '',
      snapshot: snapshot,
    );
  }

  Future<AiBudgetCheck> canRunRoomImage(
    ConfigService configService, {
    required String roomId,
    required int requestedCredits,
  }) async {
    final base = await canRunFeature(
      configService,
      feature: AiFeature.roomImage,
      requestedCredits: requestedCredits,
    );
    if (!base.allowed) return base;

    final tier = _tierFromConfig(configService);
    final policy = _effectivePolicy();
    final monthKey = _monthKey(DateTime.now());

    if (tier == SubscriptionTier.free) {
      final accountUsed = _roomImageLifetime.values.fold<int>(
        0,
        (sum, value) => sum + ((value as num?)?.toInt() ?? 0),
      );
      if (accountUsed >= policy.freeRoomImageLifetimeAccount) {
        return AiBudgetCheck(
          allowed: false,
          reason:
              'FreeプランではAI部屋画像はアカウント全体で1回までです。実写登録はなく、ほかの部屋や再生成は Pro で利用できます。',
          snapshot: base.snapshot,
          exhaustionReason: AiExhaustionReason.roomQuotaFree,
        );
      }
    } else {
      final monthlyByRoom =
          (_roomImageMonthly[monthKey] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
      final current = (monthlyByRoom[roomId] as num?)?.toInt() ?? 0;
      if (current >= policy.proRoomImagePerRoomMonthly) {
        return AiBudgetCheck(
          allowed: false,
          reason: 'Proプランでは部屋ごとに月2回までです',
          snapshot: base.snapshot,
          exhaustionReason: AiExhaustionReason.roomQuotaPro,
        );
      }
    }
    return base;
  }

  Future<void> recordUsage(
    ConfigService configService, {
    required AiFeature feature,
    required int consumedCredits,
    String? route,
    int? proxyRemainingCredits,
    int? proxyCreditLimit,
  }) async {
    await _ensureLoaded();
    if (consumedCredits <= 0 &&
        proxyRemainingCredits == null &&
        proxyCreditLimit == null) {
      return;
    }
    final monthKey = _monthKey(DateTime.now());
    final costDelta = consumedCredits > 0
        ? _effectivePolicy().creditCost(feature) * consumedCredits
        : 0.0;
    final record = (_usage[monthKey] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{'usedCredits': 0, 'estimatedCostUsd': 0.0};

    // プロキシ経由かつ残量返却あり → サーバー値を正として同期（二重減算回避）
    if (configService.preferAiProxy &&
        proxyRemainingCredits != null &&
        proxyCreditLimit != null &&
        proxyCreditLimit >= 0) {
      final syncedUsed =
          (proxyCreditLimit - proxyRemainingCredits).clamp(0, proxyCreditLimit);
      record['usedCredits'] = syncedUsed;
      final prevCost = (record['estimatedCostUsd'] as num?)?.toDouble() ?? 0.0;
      if (costDelta > 0) {
        record['estimatedCostUsd'] = prevCost + costDelta;
      }
    } else if (consumedCredits > 0) {
      final nextUsed = (record['usedCredits'] as num?)?.toInt() ?? 0;
      final nextCost = (record['estimatedCostUsd'] as num?)?.toDouble() ?? 0.0;
      record['usedCredits'] = nextUsed + consumedCredits;
      record['estimatedCostUsd'] = nextCost + costDelta;
    }
    _usage[monthKey] = record;

    final featureKey = feature.name;
    final currentFeatureCount =
        (_featureCounts[featureKey] as num?)?.toInt() ?? 0;
    _featureCounts[featureKey] = currentFeatureCount + 1;
    await _save();

    await AnalyticsService.logEvent(
      event: 'ai_usage_recorded',
      properties: {
        'feature': feature.name,
        'credits': consumedCredits,
        'route': route ?? '',
        'monthKey': monthKey,
        'estimatedCostDeltaUsd': costDelta,
        'syncedFromProxy': configService.preferAiProxy &&
            proxyRemainingCredits != null &&
            proxyCreditLimit != null,
      },
    );
  }

  Future<void> recordRoomImageUsage(
    ConfigService configService, {
    required String roomId,
    required int consumedCredits,
    int? proxyRemainingCredits,
    int? proxyCreditLimit,
  }) async {
    await recordUsage(
      configService,
      feature: AiFeature.roomImage,
      consumedCredits: consumedCredits,
      route: 'room_image_generation',
      proxyRemainingCredits: proxyRemainingCredits,
      proxyCreditLimit: proxyCreditLimit,
    );
    final tier = _tierFromConfig(configService);
    final monthKey = _monthKey(DateTime.now());

    final currentLifetime = (_roomImageLifetime[roomId] as num?)?.toInt() ?? 0;
    _roomImageLifetime[roomId] = currentLifetime + 1;

    final monthlyByRoom =
        (_roomImageMonthly[monthKey] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final currentMonth = (monthlyByRoom[roomId] as num?)?.toInt() ?? 0;
    monthlyByRoom[roomId] = currentMonth + 1;
    _roomImageMonthly[monthKey] = monthlyByRoom;
    await _save();

    await AnalyticsService.logEvent(
      event: 'room_image_quota_recorded',
      properties: {
        'roomId': roomId,
        'tier': tier.name,
        'monthKey': monthKey,
        'roomLifetimeCount': _roomImageLifetime[roomId],
        'roomMonthlyCount': monthlyByRoom[roomId],
      },
    );
  }
}
