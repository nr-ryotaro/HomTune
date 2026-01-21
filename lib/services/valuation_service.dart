import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../models/device.dart';

/// 資産価値計算サービス
/// IT/金融の視点に基づいた数式ベースの資産価値計算ロジックを提供
class ValuationService {
  static final ValuationService _instance = ValuationService._internal();
  factory ValuationService() => _instance;
  ValuationService._internal();

  Map<String, int>? _cachedUsefulLifes;

  /// カテゴリごとの法定耐用年数を読み込み
  Future<Map<String, int>> _loadUsefulLifes() async {
    if (_cachedUsefulLifes != null) {
      return _cachedUsefulLifes!;
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/data/category-defaults.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final Map<String, dynamic>? usefulLifes = jsonData['usefulLife'] as Map<String, dynamic>?;
      _cachedUsefulLifes = usefulLifes?.map((key, value) => MapEntry(key, (value as num).toInt())) ?? {};
      return _cachedUsefulLifes!;
    } catch (e) {
      print('Error loading category defaults: $e');
      // エラー時はデフォルト値を返す
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

  /// カテゴリごとの法定耐用年数を取得
  /// 
  /// [category] デバイスカテゴリ
  /// 戻り値: 法定耐用年数（年）
  Future<double> getUsefulLife(String category) async {
    final usefulLifes = await _loadUsefulLifes();
    return (usefulLifes[category] ?? 10).toDouble(); // デフォルト10年
  }

  /// 購入日からの経過年数を月単位で計算
  /// 
  /// [purchaseDate] 購入日
  /// 戻り値: 経過年数（年単位、月単位で按分）
  double calculateElapsedTime(DateTime purchaseDate) {
    try {
      final now = DateTime.now();
      final difference = now.difference(purchaseDate);
      // 未来の日付の場合は0を返す
      if (difference.isNegative) {
        return 0.0;
      }
      final months = difference.inDays / 30.44; // 平均月日数
      return months / 12.0; // 年単位に変換
    } catch (e) {
      print('Error calculating elapsed time: $e');
      return 0.0;
    }
  }

  /// 購入日文字列から経過年数を計算
  /// 
  /// [purchaseDateString] 購入日（ISO 8601形式またはYYYY-MM-DD形式）
  /// 戻り値: 経過年数（年単位、月単位で按分）
  double calculateElapsedTimeFromString(String purchaseDateString) {
    if (purchaseDateString.isEmpty) {
      return 0.0;
    }
    
    try {
      final purchaseDate = DateTime.parse(purchaseDateString);
      return calculateElapsedTime(purchaseDate);
    } catch (e) {
      print('Error parsing purchase date "$purchaseDateString": $e');
      return 0.0;
    }
  }

  /// 帳簿上の価値（減価償却残高）を計算
  /// 
  /// 計算式: P_purchase - ((P_purchase / L_life) * T_elapsed)
  /// 
  /// [purchasePrice] 購入金額
  /// [usefulLife] 法定耐用年数
  /// [elapsedTime] 経過年数
  /// 戻り値: 帳簿上の価値（円、負の値にならない）
  int calculateBookValue(int purchasePrice, double usefulLife, double elapsedTime) {
    try {
      if (usefulLife <= 0 || purchasePrice <= 0) {
        return 0;
      }

      // 経過年数が負の値の場合は0として扱う
      final safeElapsedTime = math.max(0.0, elapsedTime);

      final depreciationPerYear = purchasePrice / usefulLife;
      final totalDepreciation = depreciationPerYear * safeElapsedTime;
      final bookValue = purchasePrice - totalDepreciation;
      return math.max(0, bookValue.round()); // 負の値にならないように
    } catch (e) {
      print('Error calculating book value: $e');
      return 0;
    }
  }

  /// 市場価値を取得
  /// 
  /// デバイスの`assetValue.currentUsedPrice`を使用、またはモックデータから取得
  /// 
  /// [device] デバイス
  /// 戻り値: 市場価値（円）
  int getMarketValue(Device device) {
    // 既存のassetValueがある場合はそれを使用
    if (device.assetValue != null && device.assetValue!.currentUsedPrice > 0) {
      return device.assetValue!.currentUsedPrice;
    }
    
    // モックデータがない場合は、購入価格の50%を仮定
    return (device.purchasePrice * 0.5).round();
  }

  /// 現在の資産価値を計算
  /// 
  /// 計算式: V_current = max(V_market, P_purchase - ((P_purchase / L_life) * T_elapsed))
  /// 
  /// [device] デバイス
  /// 戻り値: 現在の資産価値（円）
  Future<int> calculateCurrentValue(Device device) async {
    final usefulLife = await getUsefulLife(device.category);
    final elapsedTime = calculateElapsedTimeFromString(device.purchaseDate);
    final bookValue = calculateBookValue(device.purchasePrice, usefulLife, elapsedTime);
    final marketValue = getMarketValue(device);
    
    // V_current = max(bookValue, marketValue)
    return math.max(bookValue, marketValue);
  }

  /// 市場価値が帳簿価値を上回っているか判定
  /// 
  /// [device] デバイス
  /// 戻り値: 売却チャンスがあるか
  Future<bool> hasSellOpportunity(Device device) async {
    final usefulLife = await getUsefulLife(device.category);
    final elapsedTime = calculateElapsedTimeFromString(device.purchaseDate);
    final bookValue = calculateBookValue(device.purchasePrice, usefulLife, elapsedTime);
    final marketValue = getMarketValue(device);
    
    return marketValue > bookValue;
  }

  /// デバイスの資産価値情報を計算して更新
  /// 
  /// [device] デバイス
  /// 戻り値: 更新されたAssetValue
  Future<AssetValue> calculateAssetValue(Device device) async {
    try {
      final usefulLife = await getUsefulLife(device.category);
      final elapsedTime = calculateElapsedTimeFromString(device.purchaseDate);
      final bookValue = calculateBookValue(device.purchasePrice, usefulLife, elapsedTime);
      final marketValue = getMarketValue(device);
      final currentValue = math.max(bookValue, marketValue);
      final hasSellOpp = marketValue > bookValue;

      // 既存のAssetValueがある場合は、priceHistoryを保持
      final existingPriceHistory = device.assetValue?.priceHistory ?? [];
      final lastPriceCheck = device.assetValue?.lastPriceCheck ?? DateTime.now().toIso8601String();

      // 減価償却率の計算（ゼロ除算を防ぐ）
      double depreciationRate = 0.0;
      if (device.purchasePrice > 0) {
        depreciationRate = (device.purchasePrice - currentValue) / device.purchasePrice;
      }

      return AssetValue(
        purchasePrice: device.purchasePrice,
        currentUsedPrice: currentValue,
        depreciationRate: device.assetValue?.depreciationRate ?? depreciationRate,
        lastPriceCheck: lastPriceCheck,
        priceHistory: existingPriceHistory,
        bookValue: bookValue,
        marketValue: marketValue,
        hasSellOpportunity: hasSellOpp,
        usefulLife: usefulLife,
      );
    } catch (e) {
      print('Error in calculateAssetValue: $e');
      // エラー時はデフォルト値を返す
      return AssetValue(
        purchasePrice: device.purchasePrice,
        currentUsedPrice: device.purchasePrice,
        depreciationRate: 0.0,
        lastPriceCheck: DateTime.now().toIso8601String(),
        priceHistory: [],
      );
    }
  }
}
