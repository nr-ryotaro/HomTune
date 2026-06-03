import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/services/asset_valuation_service.dart';

void main() {
  group('AssetValuationService statutory (legacy ValuationService)', () {
    late AssetValuationService service;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      service = AssetValuationService();
    });

    test('MacBook Pro scenario: book vs market value', () async {
      final purchaseDate =
          DateTime.now().subtract(const Duration(days: 730));
      final device = Device(
        id: 'test-mbp-001',
        name: 'MacBook Pro',
        modelNumber: 'MacBookPro16,1',
        category: 'PC',
        manufacturer: 'Apple',
        purchaseDate: purchaseDate.toIso8601String().split('T')[0],
        purchasePrice: 300000,
        yearsOwned: 2.0,
        room: 'study',
        location: '書斎デスク',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
        assetValue: AssetValue(
          purchasePrice: 300000,
          currentUsedPrice: 180000,
          depreciationRate: 0.4,
          lastPriceCheck: DateTime.now().toIso8601String(),
          priceHistory: [],
        ),
      );

      final elapsedTime =
          service.calculateElapsedTimeFromString(device.purchaseDate);
      expect(elapsedTime, closeTo(2.0, 0.1));

      final usefulLife = await service.getUsefulLife(device.category);
      expect(usefulLife, 4.0);

      final bookValue = service.calculateStatutoryBookValue(
        device.purchasePrice,
        usefulLife,
        elapsedTime,
      );
      expect(bookValue, closeTo(150000, 1000));

      expect(service.getMarketValueFromDevice(device), 180000);

      final currentValue = await service.calculateCurrentStatutoryValue(device);
      expect(currentValue, 180000);

      expect(await service.hasSellOpportunityStatutory(device), isTrue);

      final calculated = await service.calculateStatutoryAssetValue(
        device,
        forceUpdate: true,
      );
      expect(calculated.bookValue, closeTo(150000, 1000));
      expect(calculated.marketValue, 180000);
      expect(calculated.currentUsedPrice, 180000);
      expect(calculated.hasSellOpportunity, isTrue);
      expect(calculated.usefulLife, 4.0);
    });

    test('market below book value', () async {
      final purchaseDate =
          DateTime.now().subtract(const Duration(days: 365));
      final device = Device(
        id: 'test-device-002',
        name: 'エアコン',
        modelNumber: 'AC-001',
        category: 'エアコン',
        manufacturer: 'ダイキン',
        purchaseDate: purchaseDate.toIso8601String().split('T')[0],
        purchasePrice: 200000,
        yearsOwned: 1.0,
        room: 'living-room',
        location: 'リビング',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
        assetValue: AssetValue(
          purchasePrice: 200000,
          currentUsedPrice: 80000,
          depreciationRate: 0.6,
          lastPriceCheck: DateTime.now().toIso8601String(),
          priceHistory: [],
        ),
      );

      final usefulLife = await service.getUsefulLife(device.category);
      expect(usefulLife, 10.0);

      final elapsed =
          service.calculateElapsedTimeFromString(device.purchaseDate);
      final bookValue = service.calculateStatutoryBookValue(
        device.purchasePrice,
        usefulLife,
        elapsed,
      );
      expect(bookValue, closeTo(180000, 1000));
      expect(service.getMarketValueFromDevice(device), 80000);
      expect(await service.calculateCurrentStatutoryValue(device),
          closeTo(180000, 1000));
      expect(await service.hasSellOpportunityStatutory(device), isFalse);
    });

    test('elapsed time precision in months', () {
      final purchaseDate =
          DateTime.now().subtract(const Duration(days: 90));
      expect(service.calculateElapsedTime(purchaseDate), closeTo(0.25, 0.05));

      final purchaseDate2 =
          DateTime.now().subtract(const Duration(days: 180));
      expect(
        service.calculateElapsedTime(purchaseDate2),
        closeTo(0.5, 0.05),
      );
    });

    test('book value never negative', () {
      final bookValue = service.calculateStatutoryBookValue(100000, 5.0, 10.0);
      expect(bookValue, greaterThanOrEqualTo(0));
    });

    test('useful life per category', () async {
      expect(await service.getUsefulLife('PC'), 4.0);
      expect(await service.getUsefulLife('エアコン'), 10.0);
      expect(await service.getUsefulLife('スマートフォン'), 3.0);
      expect(await service.getUsefulLife('不明なカテゴリ'), 10.0);
    });
  });
}
