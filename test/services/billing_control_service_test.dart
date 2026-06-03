import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/services/ai_usage_service.dart';
import 'package:homtune/services/billing_control_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BillingControlService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AiUsageService.instance.resetForTest();
    });

    test('高コスト時にPro上限を縮小する', () async {
      final service = BillingControlService();
      final before = await AiUsageService.instance.getEffectivePolicy();
      final result = await service.autoTuneFromActualBilling(
        actualCostUsd: 25.0,
        proSubscriberCount: 10,
        fxJpyPerUsd: 155.0,
      );
      final after = await AiUsageService.instance.getEffectivePolicy();

      expect(result.scale, lessThan(1.0));
      expect(after.proMonthlyCredits, lessThan(before.proMonthlyCredits));
      expect(
        after.proRoomImagePerRoomMonthly,
        lessThanOrEqualTo(before.proRoomImagePerRoomMonthly),
      );
    });

    test('低コスト時にPro上限を増やせる（上限あり）', () async {
      final service = BillingControlService();
      final before = await AiUsageService.instance.getEffectivePolicy();
      final result = await service.autoTuneFromActualBilling(
        actualCostUsd: 0.5,
        proSubscriberCount: 200,
        fxJpyPerUsd: 155.0,
      );
      final after = await AiUsageService.instance.getEffectivePolicy();

      expect(result.scale, greaterThanOrEqualTo(1.0));
      expect(after.proMonthlyCredits, greaterThanOrEqualTo(before.proMonthlyCredits));
      expect(after.proMonthlyCredits, lessThanOrEqualTo(300));
    });
  });
}
