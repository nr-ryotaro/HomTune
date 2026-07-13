import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/ai_usage_policy.dart';
import 'package:homtune/services/ai_usage_service.dart';
import 'package:homtune/services/billing/store_billing_service.dart';
import 'package:homtune/services/config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AiUsageService.instance.resetForTest();
  });

  test('sandbox Pro purchase upgrades tier in debug', () async {
    final config = ConfigService();
    await config.load();
    expect(config.subscriptionTier, SubscriptionTier.free);

    final result =
        await StoreBillingService.instance.purchaseProSubscription(config);

    expect(result.isSuccess, isTrue);
    expect(config.subscriptionTier, SubscriptionTier.pro);
  });

  test('sandbox addon grants bonus credits for Pro', () async {
    final config = ConfigService();
    await config.load();
    await config.setSubscriptionTier(SubscriptionTier.pro);

    final pack = AiUsagePolicy.proAddonPacks.first;
    final before = await AiUsageService.instance.getBonusCredits();
    final result = await StoreBillingService.instance
        .purchaseAddonCredits(config, pack);

    expect(result.isSuccess, isTrue);
    final after = await AiUsageService.instance.getBonusCredits();
    expect(after - before, pack.credits);
  });

  test('addon purchase rejected for Free tier', () async {
    final config = ConfigService();
    await config.load();
    final pack = AiUsagePolicy.proAddonPacks.first;
    final result = await StoreBillingService.instance
        .purchaseAddonCredits(config, pack);
    expect(result.isSuccess, isFalse);
    expect(result.status, StorePurchaseStatus.unavailable);
  });
}
