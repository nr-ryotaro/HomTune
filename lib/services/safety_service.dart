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
      final String jsonString =
          await rootBundle.loadString('assets/data/safety-mock-data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _cachedRecallData = (jsonData['recalls'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];
      return _cachedRecallData!;
    } catch (e) {
      print('Error loading mock recall data: $e');
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
      final String jsonString =
          await rootBundle.loadString('assets/data/safety-mock-data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final Map<String, dynamic>? lifespans =
          jsonData['standardLifespans'] as Map<String, dynamic>?;
      _cachedLifespans = lifespans
              ?.map((key, value) => MapEntry(key, (value as num).toInt())) ??
          {};
      return _cachedLifespans!;
    } catch (e) {
      print('Error loading standard lifespans: $e');
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
  /// 将来的に外部API（NITE等）呼び出しに置き換え可能な構造
  Future<RecallDetails?> checkRecall(
      String modelNumber, String manufacturer) async {
    try {
      final mockData = await _loadMockRecallData();

      // 完全一致 → 部分一致でフォールバック
      var recall = mockData.firstWhere(
        (r) =>
            (r['modelNumber']?.toString().toLowerCase() ==
                modelNumber.toLowerCase()) &&
            (r['manufacturer']?.toString().toLowerCase() ==
                manufacturer.toLowerCase()),
        orElse: () => <String, dynamic>{},
      );

      // 部分一致（型番の前方一致）
      if (recall.isEmpty) {
        recall = mockData.firstWhere(
          (r) =>
              modelNumber.toLowerCase().startsWith(
                  r['modelNumber']?.toString().toLowerCase() ?? '___') &&
              (r['manufacturer']?.toString().toLowerCase() ==
                  manufacturer.toLowerCase()),
          orElse: () => <String, dynamic>{},
        );
      }

      if (recall.isEmpty) {
        return null;
      }

      return RecallDetails.fromJson(recall);
    } catch (e) {
      print('Error checking recall: $e');
      return null;
    }
  }

  /// 全デバイスのリコール状態を一括チェック
  /// 戻り値: リコール対象デバイスIDとリコール情報のマップ
  Future<Map<String, RecallDetails>> checkRecallForDevices(
      List<Device> devices) async {
    final Map<String, RecallDetails> results = {};
    for (final device in devices) {
      final recall = await checkRecall(device.modelNumber, device.manufacturer);
      if (recall != null) {
        results[device.id] = recall;
      }
    }
    return results;
  }

  /// デバイスにリコールが該当するか簡易チェック（UI バッジ用）
  Future<bool> hasActiveRecall(Device device) async {
    if (device.safetyInfo?.isRecallActive == true) return true;
    final recall = await checkRecall(device.modelNumber, device.manufacturer);
    return recall != null;
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

    // リコールによる減点（20%）— 深刻度に応じて変動
    double recallPenalty = 0.0;
    if (device.safetyInfo?.isRecallActive == true) {
      final severity =
          device.safetyInfo?.recallDetails?.severity ?? RecallSeverity.warning;
      switch (severity) {
        case RecallSeverity.critical:
          recallPenalty = 20.0;
          break;
        case RecallSeverity.warning:
          recallPenalty = 12.0;
          break;
        case RecallSeverity.info:
          recallPenalty = 5.0;
          break;
      }
    }
    score -= recallPenalty;

    return math.max(0.0, math.min(100.0, score));
  }

  /// メンテナンス履歴による減点を計算
  double _calculateMaintenancePenalty(Device device) {
    if (device.maintenance == null) {
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

      if (daysSinceMaintenance > 365) {
        final yearsOverdue = (daysSinceMaintenance - 365) / 365.0;
        return math.min(yearsOverdue * 10.0, 30.0);
      }

      return 0.0;
    } catch (e) {
      print('Error parsing lastMaintenance date: $e');
      return 15.0;
    }
  }

  /// 耐用年数による減点を計算
  Future<double> _calculateLifespanPenalty(Device device) async {
    final lifespans = await _loadStandardLifespans();
    final standardLifespan = lifespans[device.category] ?? 10;

    if (device.yearsOwned <= standardLifespan) {
      return 0.0;
    }

    final yearsOverLifespan = device.yearsOwned - standardLifespan;
    return math.min(yearsOverLifespan * 4.0, 20.0);
  }

  /// 安全面に特化したアドバイスを取得
  ///
  /// 戻り値: アドバイスメッセージのリスト
  Future<List<String>> getSafetyAdvice(Device device) async {
    final List<String> advice = [];

    // リコールチェック
    if (device.safetyInfo?.isRecallActive == true) {
      final severity =
          device.safetyInfo?.recallDetails?.severity ?? RecallSeverity.warning;
      if (severity == RecallSeverity.critical) {
        advice.add('⚠️ 重大なリコール対象です。直ちに使用を中止し、メーカーに連絡してください');
      } else {
        advice.add('この製品はリコール対象です。メーカーの窓口に相談しましょう');
      }
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
        final lastMaintenanceDate =
            DateTime.parse(device.maintenance!.lastMaintenance!);
        final daysSinceMaintenance =
            DateTime.now().difference(lastMaintenanceDate).inDays;
        if (daysSinceMaintenance > 730) {
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
    final recallDetails =
        await checkRecall(device.modelNumber, device.manufacturer);
    final recallStatus = recallDetails != null ? 'active' : 'none';

    // リコール付きの仮デバイスでスコア計算
    final tempDevice = Device(
      id: device.id,
      name: device.name,
      modelNumber: device.modelNumber,
      category: device.category,
      manufacturer: device.manufacturer,
      purchaseDate: device.purchaseDate,
      purchasePrice: device.purchasePrice,
      yearsOwned: device.yearsOwned,
      room: device.room,
      location: device.location,
      status: device.status,
      maintenance: device.maintenance,
      manual: device.manual,
      consumables: device.consumables,
      warranty: device.warranty,
      assetValue: device.assetValue,
      safetyInfo: SafetyInfo(
        recallStatus: recallStatus,
        recallDetails: recallDetails,
        safetyScore: 0,
        lastSafetyCheck: '',
      ),
      photos: device.photos,
      documents: device.documents,
    );

    // 安全性スコア算出
    final safetyScore = await calculateSafetyScore(tempDevice);

    // 安全アドバイス取得
    final safetyAdvice = await getSafetyAdvice(tempDevice);

    return SafetyInfo(
      recallStatus: recallStatus,
      recallDetails: recallDetails,
      safetyScore: safetyScore,
      lastSafetyCheck: DateTime.now().toIso8601String(),
      safetyAdvice: safetyAdvice,
    );
  }

  /// キャッシュをクリア（データ更新時に使用）
  void clearCache() {
    _cachedRecallData = null;
    _cachedLifespans = null;
  }
}
