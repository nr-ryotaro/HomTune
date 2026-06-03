import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/services/asset_valuation_refresh_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AssetValuationRefreshService', () {
    test('refresh updates book and market and display is max', () async {
      final service = AssetValuationRefreshService();
      final device = Device(
        id: 'refresh-test',
        name: 'Test AC',
        modelNumber: 'AC-TEST-1',
        category: 'エアコン',
        manufacturer: 'Test',
        purchaseDate: '2022-01-01',
        purchasePrice: 200000,
        yearsOwned: 3,
        room: 'living-room',
        location: 'wall',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
        condition: ItemCondition.newItem,
      );

      final av = await service.refresh(device);
      expect(av.bookValue, isNotNull);
      expect(av.marketValue, isNotNull);
      expect(
        av.currentUsedPrice,
        math.max(av.bookValue!, av.marketValue!),
      );
      expect(av.lastPriceCheck, isNotEmpty);
      expect(av.marketValueSource, isNotNull);
    });

    test('second refresh on same day updates book value downward over time',
        () async {
      final service = AssetValuationRefreshService();
      final device = Device(
        id: 'time-test',
        name: 'Fridge',
        modelNumber: 'FR-1',
        category: '冷蔵庫',
        manufacturer: 'Panasonic',
        purchaseDate: '2020-06-01',
        purchasePrice: 300000,
        yearsOwned: 5,
        room: 'kitchen-01',
        location: 'kitchen',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
      );

      final first = await service.refresh(device);
      final second = await service.refresh(device);
      expect(second.bookValue, lessThanOrEqualTo(first.bookValue!));
    });
  });
}
