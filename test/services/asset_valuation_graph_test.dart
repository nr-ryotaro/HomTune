import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/models/device_asset.dart';
import 'package:homtune/services/asset_valuation_service.dart';

void main() {
  group('AssetValuationService.buildAlignedGraphData', () {
    test('book spots align with dashboard book value logic', () async {
      final service = AssetValuationService();
      final device = Device(
        id: 'ac-1',
        name: 'エアコン',
        modelNumber: 'CS-X876C-W',
        category: 'エアコン',
        manufacturer: 'Panasonic',
        purchaseDate: '2024-01-15',
        purchasePrice: 248000,
        yearsOwned: 1,
        room: 'living-room',
        location: '壁面',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
        assetValue: AssetValue(
          purchasePrice: 248000,
          currentUsedPrice: 200000,
          depreciationRate: 0.1,
          lastPriceCheck: DateTime.now().toIso8601String(),
          priceHistory: [
            PriceHistory(
              date: DateTime.now()
                  .subtract(const Duration(days: 30))
                  .toIso8601String(),
              price: 205000,
            ),
          ],
          bookValue: 210000,
          marketValue: 185000,
        ),
      );

      final graph = await service.buildAlignedGraphData(device);
      expect(graph.bookValueSpots, isNotEmpty);
      expect(graph.marketValueSpots, isNotEmpty);
      expect(graph.historySpots, isNotEmpty);
      expect(graph.todayMonthIndex, greaterThan(0));
      expect(graph.maxX, greaterThan(graph.todayMonthIndex));
    });
  });
}
