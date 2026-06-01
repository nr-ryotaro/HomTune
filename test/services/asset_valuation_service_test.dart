import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/services/asset_valuation_service.dart';

void main() {
  group('AssetValuationService', () {
    late AssetValuationService service;

    setUp(() {
      service = AssetValuationService();
    });

    test('currentUsedPrice uses max of book and market value', () async {
      final device = Device(
        id: 'val-test',
        name: 'Test Item',
        modelNumber: 'M1',
        category: 'PC',
        manufacturer: 'Maker',
        purchaseDate: '2020-01-01',
        purchasePrice: 200000,
        yearsOwned: 5,
        room: 'living-room',
        location: 'desk',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
        condition: ItemCondition.newItem,
        releaseDate: DateTime(2019, 6, 1),
        originalPrice: 250000,
      );

      final asset = await service.calculateAssetValue(device);
      final book = asset.bookValue ?? 0;
      final market = asset.marketValue ?? 0;
      final expected = book > market ? book : market;

      expect(asset.currentUsedPrice, expected);
    });
  });
}
