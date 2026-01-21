import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../models/device.dart';
import '../models/safety_info.dart';

/// 安全性管理サービス
/// リコールチェック、安全性スコア算出、安全アドバイスを提供
class SafetyService {
  static final SafetyService _instance = SafetyService._internal();
  factory SafetyService() => _instance;
  SafetyService._internal();

  List<Map<String, dynamic>>? _cachedRecallData;
  Map<String, int>? _cachedLifespans;

  /// モックリコールデータを読み込み
  Future<List<Map<String, dynamic>>> _loadMockRecallData() async {
    if (_cachedRecallData != null) {
      return _cachedRecallData!;
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/data/safety-mock-data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _cachedRecallData = (jsonData['recalls'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];
      return _cachedRecallData!;
    } catch (e) {
      print('Error loading mock recall data: $e');
      // エラー時は空のリストを返す（アプリがクラッシュしないように）
      _cachedRecallData = [];
      return [];
    }
  }

  /// 標準耐用年数データを読み込み
  Future<Map<String, int>> _loadStandardLifespans() async {
    if (_cachedLifespans != null) {
      return _cachedLifespans!;
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/data/safety-mock-data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final Map<String, dynamic>? lifespans = jsonData['standardLifespans'] as Map<String, dynamic>?;
      _cachedLifespans = lifespans?.map((key, value) => MapEntry(key, (value as num).toInt())) ?? {};
      return _cachedLifespans!;
    } catch (e) {
      print('Error loading standard lifespans: $e');
      // エラー時はデフォルト値を返す（アプリがクラッシュしないように）
      _cachedLifespans = {
        'エアコン': 10,
        '冷蔵庫': 12,
        '洗濯機': 10,
        'テレビ': 8,
        'PC': 5,
        'スマートフォン': 3,
        '掃除機': 8,
        '電子レンジ': 8,
      };
      return _cachedLifespans!;
    }
  }

  /// リコール情報をチェック
  /// 
  /// [modelNumber] 型番
  /// [manufacturer] メーカー名
  /// 戻り値: リコール情報（該当なしの場合はnull）
  /// 
  /// 将来的に外部API呼び出しに置き換え可能な構造
  Future<RecallDetails?> checkRecall(String modelNumber, String manufacturer) async {
    try {
      // モックデータから検索
      final mockData = await _loadMockRecallData();
      final recall = mockData.firstWhere(
        (r) =>
            (r['modelNumber']?.toString().toLowerCase() ==
                modelNumber.toLowerCase()) &&
            (r['manufacturer']?.toString().toLowerCase() ==
                manufacturer.toLowerCase()),
        orElse: () => <String, dynamic>{},
      );

      if (recall.isEmpty) {
        return null;
      }

      return RecallDetails(
        modelNumber: recall['modelNumber']?.toString() ?? '',
        manufacturer: recall['manufacturer']?.toString() ?? '',
        date: recall['date']?.toString() ?? '',
        description: recall['description']?.toString() ?? '',
        reason: recall['reason']?.toString() ?? '',
        manufacturerContactUrl: recall['manufacturerContactUrl']?.toString(),
      );
    } catch (e) {
      print('Error checking recall: $e');
      return null;
    }

    // 将来的に外部API呼び出しに置き換え可能
    // return await _checkRecallAPI(modelNumber, manufacturer);
  }

  /// 安全性スコアを算出
  /// 
  /// 計算要素:
  /// - 購入からの経過年数（30%）
  /// - 最終メンテナンス日（30%）
  /// - 製品標準耐用年数（20%）
  /// - リコール有無（20%）
  /// 
  /// 戻り値: 0-100の安全性スコア
  Future<double> calculateSafetyScore(Device device) async {
    double score = 100.0;

    // 経過年数による減点（30%）
    final agePenalty = math.min(device.yearsOwned / 10.0 * 30, 30.0);
    score -= agePenalty;

    // メンテナンス履歴による減点（30%）
    final maintenancePenalty = _calculateMaintenancePenalty(device);
    score -= maintenancePenalty;

    // 耐用年数による減点（20%）
    final lifespanPenalty = await _calculateLifespanPenalty(device);
    score -= lifespanPenalty;

    // リコールによる減点（20%）
    final recallPenalty = device.safetyInfo?.recallStatus == 'active' ? 20.0 : 0.0;
    score -= recallPenalty;

    return math.max(0.0, math.min(100.0, score));
  }

  /// メンテナンス履歴による減点を計算
  double _calculateMaintenancePenalty(Device device) {
    if (device.maintenance == null) {
      // メンテナンス情報がない場合は最大減点
      return 30.0;
    }

    final lastMaintenance = device.maintenance!.lastMaintenance;
    if (lastMaintenance == null || lastMaintenance.isEmpty) {
      return 30.0;
    }

    try {
      final lastMaintenanceDate = DateTime.parse(lastMaintenance);
      final now = DateTime.now();
      final daysSinceMaintenance = now.difference(lastMaintenanceDate).inDays;

      // 1年（365日）以上経過している場合は減点
      if (daysSinceMaintenance > 365) {
        final yearsOverdue = (daysSinceMaintenance - 365) / 365.0;
        return math.min(yearsOverdue * 10.0, 30.0);
      }

      return 0.0;
    } catch (e) {
      print('Error parsing lastMaintenance date: $e');
      return 15.0; // パースエラー時は中間値
    }
  }

  /// 耐用年数による減点を計算
  Future<double> _calculateLifespanPenalty(Device device) async {
    final lifespans = await _loadStandardLifespans();
    final standardLifespan = lifespans[device.category] ?? 10; // デフォルト10年

    if (device.yearsOwned <= standardLifespan) {
      return 0.0;
    }

    // 標準耐用年数を超えている場合
    final yearsOverLifespan = device.yearsOwned - standardLifespan;
    // 超過年数に応じて減点（最大20%）
    return math.min(yearsOverLifespan * 4.0, 20.0);
  }

  /// 安全面に特化したアドバイスを取得
  /// 
  /// 戻り値: アドバイスメッセージのリスト
  Future<List<String>> getSafetyAdvice(Device device) async {
    final List<String> advice = [];

    // リコールチェック
    if (device.safetyInfo?.isRecallActive == true) {
      advice.add('この子が危ないかもしれないので、一度メーカーの窓口に相談してあげましょう');
    }

    // バッテリー関連のアドバイス
    if (device.category.toLowerCase().contains('pc') ||
        device.category.toLowerCase().contains('スマートフォン') ||
        device.category.toLowerCase().contains('ノート')) {
      if (device.yearsOwned > 3) {
        advice.add('古いバッテリーは発火の恐れがあります。定期的な交換を検討しましょう');
      }
    }

    // メンテナンス履歴の確認
    if (device.maintenance?.lastMaintenance == null ||
        device.maintenance!.lastMaintenance!.isEmpty) {
      advice.add('メンテナンス履歴がありません。定期的な点検を推奨します');
    } else {
      try {
        final lastMaintenanceDate = DateTime.parse(device.maintenance!.lastMaintenance!);
        final daysSinceMaintenance = DateTime.now().difference(lastMaintenanceDate).inDays;
        if (daysSinceMaintenance > 730) {
          // 2年以上経過
          final yearsOverdue = (daysSinceMaintenance / 365).toStringAsFixed(1);
          advice.add('最終メンテナンスから$yearsOverdue年経過しています。点検を検討しましょう');
        }
      } catch (e) {
        // パースエラーは無視
      }
    }

    // 耐用年数チェック
    final lifespans = await _loadStandardLifespans();
    final standardLifespan = lifespans[device.category] ?? 10;
    if (device.yearsOwned > standardLifespan) {
      advice.add('標準耐用年数（$standardLifespan年）を超えています。買い替えや専門家による点検を検討しましょう');
    }

    return advice;
  }

  /// デバイスの安全性情報を更新
  /// 
  /// [device] デバイス情報
  /// 戻り値: 更新されたSafetyInfo
  Future<SafetyInfo> updateSafetyInfo(Device device) async {
    // リコールチェック
    final recallDetails = await checkRecall(device.modelNumber, device.manufacturer);
    final recallStatus = recallDetails != null ? 'active' : 'none';

    // 安全性スコア算出
    final safetyScore = await calculateSafetyScore(device);

    // 安全アドバイス取得
    final safetyAdvice = await getSafetyAdvice(device);

    return SafetyInfo(
      recallStatus: recallStatus,
      recallDetails: recallDetails,
      safetyScore: safetyScore,
      lastSafetyCheck: DateTime.now().toIso8601String(),
      safetyAdvice: safetyAdvice,
    );
  }
}
