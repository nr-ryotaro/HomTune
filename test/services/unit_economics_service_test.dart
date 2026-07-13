import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/ai_usage_policy.dart';
import 'package:homtune/services/unit_economics_service.dart';

void main() {
  group('UnitEconomicsService', () {
    const policy = AiUsagePolicy();

    test('heavy Pro user stays within 60% margin target', () async {
      final estimate = await UnitEconomicsService.instance.estimateHeavyProUser(
        policy: policy,
        roomCount: 5,
        deviceCount: 15,
      );

      expect(estimate.withinTarget, isTrue);
      expect(estimate.costRatio, lessThan(0.40));
      expect(estimate.roomImageCostUsd, lessThan(0.25));
    });

    test('room count scaling increases image cost linearly', () async {
      final threeRooms = await UnitEconomicsService.instance
          .estimateHeavyProUser(policy: policy, roomCount: 3);
      final fiveRooms = await UnitEconomicsService.instance
          .estimateHeavyProUser(policy: policy, roomCount: 5);

      expect(
        fiveRooms.roomImageCostUsd,
        greaterThan(threeRooms.roomImageCostUsd),
      );
      expect(fiveRooms.withinTarget, isTrue);
    });

    test('break-even subscribers calculation', () {
      final subs = UnitEconomicsService.instance.breakEvenProSubscribers(
        totalMonthlyAiCostUsd: 12.5,
      );
      expect(subs, greaterThan(0));
      expect(subs, lessThan(50));
    });
  });
}
