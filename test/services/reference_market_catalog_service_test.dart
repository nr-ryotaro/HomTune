import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/ai_usage_policy.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/services/config_service.dart';
import 'package:homtune/services/reference_market_catalog_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Device _sonyTv() => Device(
        id: 'l1-remote',
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

  tearDown(() {
    ReferenceMarketCatalogService.instance.resetForTest();
  });

  test('bundled JSON lookup still works offline', () async {
    final price = await ReferenceMarketCatalogService.instance
        .lookupAdjustedPrice(_sonyTv());
    expect(price, isNotNull);
    expect(price!, greaterThan(0));
  });

  test('remote hit merges into cache for Pro lookup', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/v1/market/reference');
      return http.Response(
        jsonEncode({
          'success': true,
          'entry': {
            'manufacturer': 'SONY',
            'modelNumber': 'XRJ-65A95K',
            'referenceMarketYen': 280000,
            'referenceAsOf': '2024-06-01',
            'monthlyDecayRateDefault': 0.012,
          },
        }),
        200,
        headers: {'Content-Type': 'application/json'},
      );
    });

    ReferenceMarketCatalogService.instance.resetForTest(httpClient: client);

    final config = ConfigService();
    await config.load();
    await config.setSubscriptionTier(SubscriptionTier.pro);

    final price = await ReferenceMarketCatalogService.instance.lookupAdjustedPrice(
      _sonyTv(),
      config: config,
    );
    expect(price, isNotNull);
    expect(price!, greaterThanOrEqualTo(1000));
  });

  test('remote failure falls back to bundled entry', () async {
    final client = MockClient((request) async {
      throw Exception('network down');
    });
    ReferenceMarketCatalogService.instance.resetForTest(httpClient: client);

    final config = ConfigService();
    await config.load();
    await config.setSubscriptionTier(SubscriptionTier.pro);

    final price = await ReferenceMarketCatalogService.instance.lookupAdjustedPrice(
      _sonyTv(),
      config: config,
    );
    expect(price, isNotNull);
  });
}
