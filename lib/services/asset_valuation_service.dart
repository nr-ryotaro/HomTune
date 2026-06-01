import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import '../models/device.dart';

class AssetValuationService {
  static final AssetValuationService _instance =
      AssetValuationService._internal();
  factory AssetValuationService() => _instance;
  AssetValuationService._internal();

  /// 帳簿価値を計算 (Book Value)
  /// 式: V_book = PurchasePrice * (1 - D) * (1 - r)^m
  /// m: 購入日からの経過月数
  int calculateBookValue(Device device, {DateTime? targetDate}) {
    final now = targetDate ?? DateTime.now();
    final purchaseDate = DateTime.tryParse(device.purchaseDate) ?? now;

    // 経過月数 m の計算
    final elapsedMonths = _calculateMonthsDifference(purchaseDate, now);
    if (elapsedMonths < 0) return device.purchasePrice; // 未来の日付の場合は購入価格

    // 係数設定
    double D = 0.0;
    double r = 0.015; // 月次償却率 1.5%

    if (device.condition == ItemCondition.newItem) {
      D = 0.15; // 開封落ち係数 15%
    } else {
      D = 0.0; // 中古は開封落ちなし
    }

    // 計算
    final double value =
        device.purchasePrice * (1.0 - D) * math.pow(1.0 - r, elapsedMonths);

    return math.max(0, value.round());
  }

  /// 市場価値をシミュレーション計算 (Simulated Market Value)
  /// 式: V_market = OriginalPrice * (1 - 0.20) * (1 - 0.02)^m_total
  /// m_total: 発売日からの経過月数
  int simulateMarketValue(Device device, {DateTime? targetDate}) {
    final now = targetDate ?? DateTime.now();
    final releaseDate = device.releaseDate;
    final originalPrice = device.originalPrice;

    // 発売日や定価が不明な場合は、購入価格をベースに簡易計算（フォールバック）
    if (releaseDate == null || originalPrice == null) {
      // フォールバック: 購入価格から年20%減価と仮定
      final purchaseDate = DateTime.tryParse(device.purchaseDate) ?? now;
      final elapsedMonths = _calculateMonthsDifference(purchaseDate, now);
      final double value = device.purchasePrice *
          math.pow(1.0 - 0.02, elapsedMonths).toDouble(); // 月2%減
      return math.max(0, value.round());
    }

    // 経過月数 m_total の計算
    final elapsedMonthsTotal = _calculateMonthsDifference(releaseDate, now);
    if (elapsedMonthsTotal < 0) return originalPrice;

    // 計算
    // 初期減価 20%, 月次減価 2%
    final double value =
        originalPrice * (1.0 - 0.20) * math.pow(1.0 - 0.02, elapsedMonthsTotal);

    return math.max(0, value.round());
  }

  /// グラフ用データを生成
  /// 期間: 購入日 -> 1年後
  /// 戻り値: { 'bookValue': List<FlSpot>, 'marketValue': List<FlSpot> }
  Map<String, List<FlSpot>> generateGraphData(Device device) {
    final purchaseDate =
        DateTime.tryParse(device.purchaseDate) ?? DateTime.now();
    final now = DateTime.now();
    final oneYearLater = now.add(const Duration(days: 365));

    // X軸の範囲: 購入日を0とし、1年後までの月数
    // しかしグラフは「時系列」で見せたいので、X軸は「購入日からの月数」とするのが一般的
    // 過去データ（購入日〜現在）と未来予測（現在〜1年後）

    final bookValueSpots = <FlSpot>[];
    final marketValueSpots = <FlSpot>[];

    // グラフの開始点（購入日）から終了点（1年後）までの総月数
    final totalMonths = _calculateMonthsDifference(purchaseDate, oneYearLater);

    // データポイント作成（1ヶ月刻み）
    for (int i = 0; i <= totalMonths; i++) {
      final targetDate = _addMonths(purchaseDate, i);

      // 帳簿価値
      final bookVal = calculateBookValue(device, targetDate: targetDate);
      bookValueSpots.add(FlSpot(i.toDouble(), bookVal.toDouble()));

      // 市場価値
      final marketVal = simulateMarketValue(device, targetDate: targetDate);
      marketValueSpots.add(FlSpot(i.toDouble(), marketVal.toDouble()));
    }

    return {
      'bookValue': bookValueSpots,
      'marketValue': marketValueSpots,
    };
  }

  DateTime _addMonths(DateTime date, int monthsToAdd) {
    final totalMonths = date.month - 1 + monthsToAdd;
    final year = date.year + totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final day = math.min(date.day, lastDayOfMonth);
    return DateTime(year, month, day);
  }

  /// 経過月数を計算
  double _calculateMonthsDifference(DateTime startDate, DateTime endDate) {
    final difference = endDate.difference(startDate).inDays;
    return difference / 30.44; // 平均月日数
  }

  /// DeviceService連携用: AssetValueオブジェクトを生成して返す
  Future<AssetValue> calculateAssetValue(Device device) async {
    final bookValue = calculateBookValue(device);
    final marketValue = simulateMarketValue(device);
    final currentValue = math.max(bookValue, marketValue);

    // インサイト生成（簡易版）
    String? insight;
    if (marketValue > bookValue * 1.1) {
      insight = '市場価値が帳簿価値を上回っています。売却の良いタイミングかもしれません。';
    } else if (bookValue < device.purchasePrice * 0.5) {
      insight = '購入価格の50%を下回りました。メンテナンスや買い替えの検討時期です。';
    }

    // 既存の履歴があれば維持
    final existingHistory = device.assetValue?.priceHistory ?? [];
    final now = DateTime.now().toIso8601String();

    return AssetValue(
      purchasePrice: device.purchasePrice,
      currentUsedPrice: currentValue,
      depreciationRate: device.purchasePrice > 0
          ? (device.purchasePrice - bookValue) / device.purchasePrice
          : 0.0,
      lastPriceCheck: now,
      priceHistory: existingHistory,
      bookValue: bookValue,
      marketValue: marketValue,
      hasSellOpportunity: marketValue > bookValue,
      usefulLife: 10.0, // デフォルト
      valuationInsight: insight,
    );
  }
}
