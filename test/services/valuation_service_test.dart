import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/services/valuation_service.dart';

void main() {
  group('ValuationService Tests', () {
    late ValuationService valuationService;

    setUp(() {
      valuationService = ValuationService();
    });

    test('MacBook Proシナリオ: 購入額30万、2年経過、市場価値18万', () async {
      // テストデータ: MacBook Pro
      // 購入日: 2022年1月1日（2年前）
      // 購入額: 300,000円
      // 市場価値: 180,000円（assetValue.currentUsedPrice）
      // カテゴリ: PC（法定耐用年数4年）

      final purchaseDate = DateTime.now().subtract(const Duration(days: 730)); // 2年前
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
          currentUsedPrice: 180000, // 市場価値
          depreciationRate: 0.4,
          lastPriceCheck: DateTime.now().toIso8601String(),
          priceHistory: [],
        ),
      );

      // 経過年数の計算をテスト
      final elapsedTime = valuationService.calculateElapsedTimeFromString(device.purchaseDate);
      expect(elapsedTime, closeTo(2.0, 0.1)); // 約2年

      // 法定耐用年数の取得をテスト
      final usefulLife = await valuationService.getUsefulLife(device.category);
      expect(usefulLife, 4.0); // PCは4年

      // 帳簿価値の計算をテスト
      // 減価償却: 300,000 / 4 * 2 = 150,000
      // 帳簿価値: 300,000 - 150,000 = 150,000
      final bookValue = valuationService.calculateBookValue(
        device.purchasePrice,
        usefulLife,
        elapsedTime,
      );
      expect(bookValue, closeTo(150000, 1000)); // 約150,000円

      // 市場価値の取得をテスト
      final marketValue = valuationService.getMarketValue(device);
      expect(marketValue, 180000); // 180,000円

      // 現在の資産価値の計算をテスト
      // V_current = max(150,000, 180,000) = 180,000
      final currentValue = await valuationService.calculateCurrentValue(device);
      expect(currentValue, 180000); // 市場価値が大きい

      // 売却チャンスの判定をテスト
      // 市場価値(180,000) > 帳簿価値(150,000) = true
      final hasSellOpp = await valuationService.hasSellOpportunity(device);
      expect(hasSellOpp, true);

      // calculateAssetValueの統合テスト
      final calculatedAssetValue = await valuationService.calculateAssetValue(device);
      expect(calculatedAssetValue.bookValue, closeTo(150000, 1000));
      expect(calculatedAssetValue.marketValue, 180000);
      expect(calculatedAssetValue.currentUsedPrice, 180000);
      expect(calculatedAssetValue.hasSellOpportunity, true);
      expect(calculatedAssetValue.usefulLife, 4.0);
    });

    test('市場価値が帳簿価値を下回る場合', () async {
      final purchaseDate = DateTime.now().subtract(const Duration(days: 365)); // 1年前
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
          currentUsedPrice: 80000, // 市場価値が低い
          depreciationRate: 0.6,
          lastPriceCheck: DateTime.now().toIso8601String(),
          priceHistory: [],
        ),
      );

      final usefulLife = await valuationService.getUsefulLife(device.category);
      expect(usefulLife, 10.0); // エアコンは10年

      final elapsedTime = valuationService.calculateElapsedTimeFromString(device.purchaseDate);
      final bookValue = valuationService.calculateBookValue(
        device.purchasePrice,
        usefulLife,
        elapsedTime,
      );
      // 減価償却: 200,000 / 10 * 1 = 20,000
      // 帳簿価値: 200,000 - 20,000 = 180,000
      expect(bookValue, closeTo(180000, 1000));

      final marketValue = valuationService.getMarketValue(device);
      expect(marketValue, 80000);

      // V_current = max(180,000, 80,000) = 180,000
      final currentValue = await valuationService.calculateCurrentValue(device);
      expect(currentValue, 180000); // 帳簿価値が大きい

      // 市場価値(80,000) < 帳簿価値(180,000) = false
      final hasSellOpp = await valuationService.hasSellOpportunity(device);
      expect(hasSellOpp, false);
    });

    test('月単位の経過時間計算の精度', () {
      final purchaseDate = DateTime.now().subtract(const Duration(days: 90)); // 3ヶ月前
      final elapsedTime = valuationService.calculateElapsedTime(purchaseDate);
      expect(elapsedTime, closeTo(0.25, 0.05)); // 約0.25年（3ヶ月）

      final purchaseDate2 = DateTime.now().subtract(const Duration(days: 180)); // 6ヶ月前
      final elapsedTime2 = valuationService.calculateElapsedTime(purchaseDate2);
      expect(elapsedTime2, closeTo(0.5, 0.05)); // 約0.5年（6ヶ月）
    });

    test('帳簿価値が負の値にならない', () {
      // 耐用年数を大幅に超過した場合
      final bookValue = valuationService.calculateBookValue(
        100000, // 購入価格
        5.0,    // 耐用年数5年
        10.0,   // 経過年数10年（耐用年数を超過）
      );
      expect(bookValue, greaterThanOrEqualTo(0));
    });

    test('カテゴリごとの法定耐用年数の取得', () async {
      final pcLife = await valuationService.getUsefulLife('PC');
      expect(pcLife, 4.0);

      final airconLife = await valuationService.getUsefulLife('エアコン');
      expect(airconLife, 10.0);

      final smartphoneLife = await valuationService.getUsefulLife('スマートフォン');
      expect(smartphoneLife, 3.0);

      // 存在しないカテゴリの場合はデフォルト値（10年）
      final unknownLife = await valuationService.getUsefulLife('不明なカテゴリ');
      expect(unknownLife, 10.0);
    });
  });
}
