import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';

import '../models/device.dart';

class AssetValuationService {
  static final AssetValuationService _instance =
      AssetValuationService._internal();
  factory AssetValuationService() => _instance;
  AssetValuationService._internal();

  Map<String, int>? _cachedUsefulLifes;

  /// カテゴリごとの法定耐用年数を読み込み
  Future<Map<String, int>> loadUsefulLifes() async {
    if (_cachedUsefulLifes != null) {
      return _cachedUsefulLifes!;
    }

    try {
      final jsonString =
          await rootBundle.loadString('assets/data/category-defaults.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final usefulLifes = jsonData['usefulLife'] as Map<String, dynamic>?;
      _cachedUsefulLifes = usefulLifes
              ?.map((key, value) => MapEntry(key, (value as num).toInt())) ??
          {};
      return _cachedUsefulLifes!;
    } catch (e) {
      print('Error loading category defaults: $e');
      _cachedUsefulLifes = {
        'エアコン': 10,
        '冷蔵庫': 12,
        '洗濯機': 10,
        'テレビ': 8,
        'PC': 4,
        'パソコン': 4,
        'スマートフォン': 3,
        '掃除機': 8,
        '電子レンジ': 8,
        'オーディオ': 15,
      };
      return _cachedUsefulLifes!;
    }
  }

  Future<double> getUsefulLife(String category) async {
    final usefulLifes = await loadUsefulLifes();
    return (usefulLifes[category] ?? 10).toDouble();
  }

  double calculateElapsedTime(DateTime purchaseDate) {
    try {
      final now = DateTime.now();
      final difference = now.difference(purchaseDate);
      if (difference.isNegative) return 0.0;
      final months = difference.inDays / 30.44;
      return months / 12.0;
    } catch (e) {
      print('Error calculating elapsed time: $e');
      return 0.0;
    }
  }

  double calculateElapsedTimeFromString(String purchaseDateString) {
    if (purchaseDateString.isEmpty) return 0.0;
    try {
      return calculateElapsedTime(DateTime.parse(purchaseDateString));
    } catch (e) {
      print('Error parsing purchase date "$purchaseDateString": $e');
      return 0.0;
    }
  }

  /// 法定耐用年数ベースの帳簿価値（旧 ValuationService 互換）
  int calculateStatutoryBookValue(
    int purchasePrice,
    double usefulLife,
    double elapsedTime,
  ) {
    try {
      if (usefulLife <= 0 || purchasePrice <= 0) return 0;
      final safeElapsed = math.max(0.0, elapsedTime);
      final depreciationPerYear = purchasePrice / usefulLife;
      final bookValue = purchasePrice - depreciationPerYear * safeElapsed;
      return math.max(0, bookValue.round());
    } catch (e) {
      print('Error calculating statutory book value: $e');
      return 0;
    }
  }

  int getMarketValueFromDevice(Device device) {
    if (device.assetValue != null && device.assetValue!.currentUsedPrice > 0) {
      return device.assetValue!.currentUsedPrice;
    }
    return (device.purchasePrice * 0.5).round();
  }

  Future<int> calculateCurrentStatutoryValue(Device device) async {
    final usefulLife = await getUsefulLife(device.category);
    final elapsed = calculateElapsedTimeFromString(device.purchaseDate);
    final bookValue = calculateStatutoryBookValue(
      device.purchasePrice,
      usefulLife,
      elapsed,
    );
    final marketValue = getMarketValueFromDevice(device);
    return math.max(bookValue, marketValue);
  }

  Future<bool> hasSellOpportunityStatutory(Device device) async {
    final usefulLife = await getUsefulLife(device.category);
    final elapsed = calculateElapsedTimeFromString(device.purchaseDate);
    final bookValue = calculateStatutoryBookValue(
      device.purchasePrice,
      usefulLife,
      elapsed,
    );
    return getMarketValueFromDevice(device) > bookValue;
  }

  Future<AssetValue> calculateStatutoryAssetValue(
    Device device, {
    bool forceUpdate = false,
  }) async {
    try {
      if (!forceUpdate && device.assetValue != null) {
        final lastCheck = DateTime.tryParse(device.assetValue!.lastPriceCheck);
        if (lastCheck != null &&
            DateTime.now().difference(lastCheck).inDays < 30) {
          return device.assetValue!;
        }
      }

      final usefulLife = await getUsefulLife(device.category);
      final elapsed = calculateElapsedTimeFromString(device.purchaseDate);
      final bookValue = calculateStatutoryBookValue(
        device.purchasePrice,
        usefulLife,
        elapsed,
      );
      final marketValue = getMarketValueFromDevice(device);
      final currentValue = math.max(bookValue, marketValue);
      final hasSellOpp = marketValue > bookValue;
      final existingHistory = device.assetValue?.priceHistory ?? [];

      double depreciationRate = 0.0;
      if (device.purchasePrice > 0) {
        depreciationRate =
            (device.purchasePrice - currentValue) / device.purchasePrice;
      }

      return AssetValue(
        purchasePrice: device.purchasePrice,
        currentUsedPrice: currentValue,
        depreciationRate:
            device.assetValue?.depreciationRate ?? depreciationRate,
        lastPriceCheck: DateTime.now().toIso8601String(),
        priceHistory: existingHistory,
        bookValue: bookValue,
        marketValue: marketValue,
        hasSellOpportunity: hasSellOpp,
        usefulLife: usefulLife,
      );
    } catch (e) {
      print('Error in calculateStatutoryAssetValue: $e');
      return AssetValue(
        purchasePrice: device.purchasePrice,
        currentUsedPrice: device.purchasePrice,
        depreciationRate: 0.0,
        lastPriceCheck: DateTime.now().toIso8601String(),
        priceHistory: [],
      );
    }
  }

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

  /// グラフ用データを生成（旧API・後方互換）
  Map<String, List<FlSpot>> generateGraphData(Device device) {
    final purchaseDate =
        DateTime.tryParse(device.purchaseDate) ?? DateTime.now();
    final now = DateTime.now();
    final oneYearLater = now.add(const Duration(days: 365));

    final bookValueSpots = <FlSpot>[];
    final marketValueSpots = <FlSpot>[];

    final totalMonths = _calculateMonthsDifference(purchaseDate, oneYearLater);

    for (int i = 0; i <= totalMonths.ceil(); i++) {
      final targetDate = _addMonths(purchaseDate, i);
      final bookVal = calculateBookValue(device, targetDate: targetDate);
      bookValueSpots.add(FlSpot(i.toDouble(), bookVal.toDouble()));
      final marketVal = simulateMarketValue(device, targetDate: targetDate);
      marketValueSpots.add(FlSpot(i.toDouble(), marketVal.toDouble()));
    }

    return {
      'bookValue': bookValueSpots,
      'marketValue': marketValueSpots,
    };
  }

  /// ダッシュボード表示と整合したグラフデータ（帳簿=タイムラインと法定の平均）
  Future<AssetGraphData> buildAlignedGraphData(Device device) async {
    final purchaseDate =
        DateTime.tryParse(device.purchaseDate) ?? DateTime.now();
    final now = DateTime.now();
    final oneYearLater = now.add(const Duration(days: 365));
    final totalMonths =
        _calculateMonthsDifference(purchaseDate, oneYearLater).ceil();
    final todayIndex = _calculateMonthsDifference(purchaseDate, now);
    final usefulLife = await getUsefulLife(device.category);

    final bookSpots = <FlSpot>[];
    final marketSpots = <FlSpot>[];

    for (var i = 0; i <= totalMonths; i++) {
      final targetDate = _addMonths(purchaseDate, i);
      final timeline = calculateBookValue(device, targetDate: targetDate);
      final elapsed =
          _calculateMonthsDifference(purchaseDate, targetDate) / 12.0;
      final statutory = calculateStatutoryBookValue(
        device.purchasePrice,
        usefulLife,
        elapsed,
      );
      final bookVal = ((timeline + statutory) / 2).round();
      bookSpots.add(FlSpot(i.toDouble(), bookVal.toDouble()));

      final isToday = (i - todayIndex).abs() < 0.6;
      final marketVal = isToday && device.assetValue?.marketValue != null
          ? device.assetValue!.marketValue!
          : simulateMarketValue(device, targetDate: targetDate);
      marketSpots.add(FlSpot(i.toDouble(), marketVal.toDouble()));
    }

    final historySpots = <FlSpot>[];
    for (final h in device.assetValue?.priceHistory ?? []) {
      final dt = DateTime.tryParse(h.date);
      if (dt == null) continue;
      final monthIdx = _calculateMonthsDifference(purchaseDate, dt);
      if (monthIdx >= 0 && monthIdx <= totalMonths) {
        historySpots.add(FlSpot(monthIdx, h.price.toDouble()));
      }
    }

    return AssetGraphData(
      bookValueSpots: bookSpots,
      marketValueSpots: marketSpots,
      historySpots: historySpots,
      todayMonthIndex: todayIndex,
      maxX: totalMonths.toDouble(),
    );
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

/// 資産グラフ用の整合データセット
class AssetGraphData {
  final List<FlSpot> bookValueSpots;
  final List<FlSpot> marketValueSpots;
  final List<FlSpot> historySpots;
  final double todayMonthIndex;
  final double maxX;

  const AssetGraphData({
    required this.bookValueSpots,
    required this.marketValueSpots,
    required this.historySpots,
    required this.todayMonthIndex,
    required this.maxX,
  });
}
