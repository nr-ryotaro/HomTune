import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/ai_usage_policy.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/models/device_asset.dart';
import 'package:homtune/models/market_refresh_mode.dart';
import 'package:homtune/services/asset_valuation_refresh_service.dart';
import 'package:homtune/services/config_service.dart';
import 'package:homtune/services/market_valuation_quota_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MarketValuationQuotaService.instance.resetForTest();
  });

  Device _sonyTv() => Device(
        id: 'l1-test',
        name: 'TV',
        modelNumber: 'XRJ-65A95K',
        category: 'テレビ',
        manufacturer: 'SONY',
        purchaseDate: '2023-01-01',
        purchasePrice: 450000,
        yearsOwned: 2,
        room: 'living-room',
        location: 'wall',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
      );

  test('L1 applies referenceCatalog for known model', () async {
    final config = ConfigService();
    await config.load();
    await config.setSubscriptionTier(SubscriptionTier.pro);

    final service = AssetValuationRefreshService();
    final result = await service.refreshWithMode(
      _sonyTv(),
      config: config,
      mode: MarketRefreshMode.proReference,
    );

    expect(
      result.assetValue.marketSourceParsed,
      MarketValueSource.referenceCatalog,
    );
    expect(result.assetValue.marketValue, greaterThan(0));
  });

  test('L1 rejects Free tier', () async {
    final config = ConfigService();
    await config.load();
    final service = AssetValuationRefreshService();
    expect(
      () => service.refreshWithMode(
        _sonyTv(),
        config: config,
        mode: MarketRefreshMode.proReference,
      ),
      throwsA(isA<AssetRefreshPolicyException>()),
    );
  });

  test('L2 mock applies geminiEstimate on Pro without real API', () async {
    final config = ConfigService();
    await config.load();
    await config.setSubscriptionTier(SubscriptionTier.pro);

    final service = AssetValuationRefreshService();
    final result = await service.refreshWithMode(
      _sonyTv(),
      config: config,
      mode: MarketRefreshMode.proAi,
    );

    expect(
      result.assetValue.marketSourceParsed,
      MarketValueSource.geminiEstimate,
    );
  });
}
