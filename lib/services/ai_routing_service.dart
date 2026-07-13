import '../models/ai_usage_policy.dart';
import '../models/device.dart';
import '../models/local_response_plan.dart';
import 'device_query_matcher.dart';
import 'local_response_planner.dart';
import 'market_price_gemini_service.dart';

enum AiRouteType {
  localOnly,
  aiOptional,
  aiRequired,
}

class AiRoutingDecision {
  final AiRouteType routeType;
  final int estimatedCredits;
  final bool needsConfirmation;
  final String reason;

  const AiRoutingDecision({
    required this.routeType,
    required this.estimatedCredits,
    required this.needsConfirmation,
    required this.reason,
  });

  bool get shouldUseAi => routeType != AiRouteType.localOnly;
}

class AiRoutingService {
  static final AiRoutingService instance = AiRoutingService._();
  AiRoutingService._();

  static const double highLocalConfidence = 0.7;
  static const double minLocalConfidence = 0.4;

  static const _localKeywords = <String>[
    '型番',
    '保証',
    'リコール',
    'メンテ',
    '電源',
    '使い方',
    'どこ',
    '登録',
    '何台',
  ];

  static const _aiOptionalKeywords = <String>[
    '比較',
    '原因分析',
    '最適',
    '提案',
    '調べて',
    '調査',
    'なぜ',
    'まとめて',
    '選び方',
  ];

  static const _aiRequiredKeywords = <String>[
    '画像生成',
    'デザイン案',
    'キャッチコピー',
    '長文で',
    'ブログ風',
  ];

  /// AI実行前にユーザー確認が必要か（Phase 2 ポリシー）
  static bool needsUserConfirmationForAi({
    required AiRoutingDecision decision,
    required LocalResponsePlan plan,
    required SubscriptionTier tier,
  }) {
    if (!decision.shouldUseAi) return false;
    if (plan.canAnswer) return false;
    if (tier == SubscriptionTier.free) return true;
    if (decision.routeType == AiRouteType.aiRequired) return true;
    return decision.estimatedCredits >= 2;
  }

  AiRoutingDecision decideChatRoute(
    String message, {
    required List<Device> devices,
    LocalResponsePlan? localPlan,
    SubscriptionTier subscriptionTier = SubscriptionTier.free,
  }) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return const AiRoutingDecision(
        routeType: AiRouteType.localOnly,
        estimatedCredits: 0,
        needsConfirmation: false,
        reason: 'empty_message',
      );
    }

    final plan = localPlan ?? LocalResponsePlanner.plan(trimmed, devices);
    final lower = trimmed.toLowerCase();
    final matchedDevice = DeviceQueryMatcher.hasDeviceMatch(trimmed, devices);

    if (_containsAny(lower, _aiRequiredKeywords)) {
      return _withConfirmation(
        decision: AiRoutingDecision(
          routeType: AiRouteType.aiRequired,
          estimatedCredits: _estimateCredits(trimmed, bonus: 2),
          needsConfirmation: false,
          reason: 'explicit_ai_request',
        ),
        plan: plan,
        tier: subscriptionTier,
      );
    }

    if (plan.canAnswer && plan.confidence >= highLocalConfidence) {
      return AiRoutingDecision(
        routeType: AiRouteType.localOnly,
        estimatedCredits: 0,
        needsConfirmation: false,
        reason: 'local_plan_high_${plan.topic.name}',
      );
    }

    if (plan.canAnswer && plan.confidence >= minLocalConfidence) {
      return const AiRoutingDecision(
        routeType: AiRouteType.localOnly,
        estimatedCredits: 0,
        needsConfirmation: false,
        reason: 'local_plan_sufficient',
      );
    }

    if (_containsAny(lower, _localKeywords) && matchedDevice) {
      return const AiRoutingDecision(
        routeType: AiRouteType.localOnly,
        estimatedCredits: 0,
        needsConfirmation: false,
        reason: 'local_knowledge_match',
      );
    }

    final longMessage = trimmed.length > 90;
    final optionalSignal = _containsAny(lower, _aiOptionalKeywords) ||
        (longMessage && !plan.canAnswer) ||
        (!matchedDevice && !plan.canAnswer);

    if (optionalSignal) {
      return _withConfirmation(
        decision: AiRoutingDecision(
          routeType: AiRouteType.aiOptional,
          estimatedCredits: _estimateCredits(trimmed),
          needsConfirmation: false,
          reason: 'complex_or_unknown_query',
        ),
        plan: plan,
        tier: subscriptionTier,
      );
    }

    return const AiRoutingDecision(
      routeType: AiRouteType.localOnly,
      estimatedCredits: 0,
      needsConfirmation: false,
      reason: 'default_local_first',
    );
  }

  AiRoutingDecision _withConfirmation({
    required AiRoutingDecision decision,
    required LocalResponsePlan plan,
    required SubscriptionTier tier,
  }) {
    return AiRoutingDecision(
      routeType: decision.routeType,
      estimatedCredits: decision.estimatedCredits,
      needsConfirmation: needsUserConfirmationForAi(
        decision: decision,
        plan: plan,
        tier: tier,
      ),
      reason: decision.reason,
    );
  }

  int defaultCreditsForFeature(AiFeature feature) {
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

  bool _containsAny(String source, List<String> keywords) =>
      keywords.any(source.contains);

  int _estimateCredits(String message, {int bonus = 0}) {
    final len = message.length;
    if (len <= 40) return 1 + bonus;
    if (len <= 120) return 2 + bonus;
    if (len <= 240) return 3 + bonus;
    return 4 + bonus;
  }
}
