import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/ai_usage_policy.dart';
import 'package:homtune/services/config_service.dart';
import 'package:homtune/services/market_valuation_quota_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MarketValuationQuotaService.instance.resetForTest();
  });

  test('Free tier has zero L1 quota', () async {
    final config = ConfigService();
    await config.load();
    final snap = await MarketValuationQuotaService.instance.getSnapshot(config);
    expect(snap.isPro, isFalse);
    expect(snap.monthlyLimit, 0);
    expect(snap.canConsumeL1, isFalse);
  });

  test('Pro tier consumes L1 quota up to limit', () async {
    final config = ConfigService();
    await config.load();
    await config.setSubscriptionTier(SubscriptionTier.pro);

    final policyLimit = const AiUsagePolicy().proMonthlyMarketLookups;
    for (var i = 0; i < policyLimit; i++) {
      final ok =
          await MarketValuationQuotaService.instance.tryConsumeL1(config);
      expect(ok, isTrue, reason: 'consume $i');
    }
    final snap = await MarketValuationQuotaService.instance.getSnapshot(config);
    expect(snap.remaining, 0);
    expect(
      await MarketValuationQuotaService.instance.tryConsumeL1(config),
      isFalse,
    );
  });
}
