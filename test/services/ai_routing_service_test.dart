import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/models/local_response_plan.dart';
import 'package:homtune/models/ai_usage_policy.dart';
import 'package:homtune/services/ai_routing_service.dart';
import 'package:homtune/services/local_response_planner.dart';

void main() {
  group('AiRoutingService', () {
    final devices = [
      Device(
        id: 'd1',
        name: 'BRAVIA 65V型 有機ELテレビ',
        modelNumber: 'XRJ-65A95K',
        category: 'テレビ',
        manufacturer: 'SONY',
        purchaseDate: '2025-01-01',
        purchasePrice: 100000,
        yearsOwned: 1,
        room: 'living-room',
        location: 'wall',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
      ),
      Device(
        id: 'd2',
        name: 'リビングエアコン',
        modelNumber: 'CS-101',
        category: 'エアコン',
        manufacturer: 'Panasonic',
        purchaseDate: '2025-01-01',
        purchasePrice: 100000,
        yearsOwned: 1,
        room: 'living-room',
        location: 'wall',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
      ),
    ];

    test('型番質問は localOnly（localPlan 連携）', () {
      final message = 'リビングのテレビの型番を教えて';
      final plan = LocalResponsePlanner.plan(message, devices);
      final decision = AiRoutingService.instance.decideChatRoute(
        message,
        devices: devices,
        localPlan: plan,
      );
      expect(decision.routeType, AiRouteType.localOnly);
      expect(decision.shouldUseAi, false);
      expect(decision.needsConfirmation, isFalse);
      expect(decision.reason, contains('local_plan'));
    });

    test('複雑質問は aiOptional', () {
      final decision = AiRoutingService.instance.decideChatRoute(
        '電気代とメンテ効率を比較して最適な運用を提案して',
        devices: devices,
      );
      expect(decision.routeType, AiRouteType.aiOptional);
      expect(decision.estimatedCredits, greaterThan(0));
    });

    test('長文でも localPlan が高信頼なら localOnly', () {
      final message =
          '登録されているリビングのBRAVIA 65V型 有機ELテレビの型番を教えてください。メーカーも確認したいです。';
      final plan = LocalResponsePlanner.plan(message, devices);
      final decision = AiRoutingService.instance.decideChatRoute(
        message,
        devices: devices,
        localPlan: plan,
      );
      expect(plan.confidence, greaterThanOrEqualTo(0.7));
      expect(decision.routeType, AiRouteType.localOnly);
    });

    test('FreeはAIルートで確認必須', () {
      final message = '電気代を比較して最適な運用を提案して';
      final plan = LocalResponsePlanner.plan(message, devices);
      final decision = AiRoutingService.instance.decideChatRoute(
        message,
        devices: devices,
        localPlan: plan,
        subscriptionTier: SubscriptionTier.free,
      );
      expect(decision.routeType, isNot(AiRouteType.localOnly));
      expect(decision.needsConfirmation, isTrue);
    });

    test('Proはローカル十分なら確認なし', () {
      final message = 'リビングのテレビの型番を教えて';
      final plan = LocalResponsePlanner.plan(message, devices);
      expect(
        AiRoutingService.needsUserConfirmationForAi(
          decision: AiRoutingService.instance.decideChatRoute(
            message,
            devices: devices,
            localPlan: plan,
            subscriptionTier: SubscriptionTier.pro,
          ),
          plan: plan,
          tier: SubscriptionTier.pro,
        ),
        isFalse,
      );
    });

    test('何台質問は localOnly', () {
      final message = '登録してる家電は何台？';
      final plan = LocalResponsePlanner.plan(message, devices);
      final decision = AiRoutingService.instance.decideChatRoute(
        message,
        devices: devices,
        localPlan: plan,
      );
      expect(plan.topic, LocalResponseTopic.deviceCount);
      expect(decision.routeType, AiRouteType.localOnly);
    });
  });
}
