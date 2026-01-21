/// 安全性情報モデル
/// リコール情報と安全性スコアを管理
class SafetyInfo {
  /// リコール状態: 'none' | 'active' | 'resolved'
  final String recallStatus;
  
  /// リコール詳細情報
  final RecallDetails? recallDetails;
  
  /// 安全性スコア（0-100）
  final double safetyScore;
  
  /// 最終安全性チェック日時（ISO 8601形式）
  final String lastSafetyCheck;
  
  /// 安全アドバイス（パーツ交換等）
  final List<String> safetyAdvice;

  SafetyInfo({
    required this.recallStatus,
    this.recallDetails,
    required this.safetyScore,
    required this.lastSafetyCheck,
    this.safetyAdvice = const [],
  });

  factory SafetyInfo.fromJson(Map<String, dynamic> json) {
    try {
      return SafetyInfo(
        recallStatus: json['recallStatus']?.toString() ?? 'none',
        recallDetails: json['recallDetails'] != null
            ? RecallDetails.fromJson(json['recallDetails'] as Map<String, dynamic>)
            : null,
        safetyScore: ((json['safetyScore'] as num?) ?? 100.0).toDouble(),
        lastSafetyCheck: json['lastSafetyCheck']?.toString() ?? '',
        safetyAdvice: (json['safetyAdvice'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
    } catch (e) {
      print('Error parsing SafetyInfo: $e');
      return SafetyInfo(
        recallStatus: 'none',
        safetyScore: 100.0,
        lastSafetyCheck: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'recallStatus': recallStatus,
      'recallDetails': recallDetails?.toJson(),
      'safetyScore': safetyScore,
      'lastSafetyCheck': lastSafetyCheck,
      'safetyAdvice': safetyAdvice,
    };
  }

  /// リコールがアクティブかどうか
  bool get isRecallActive => recallStatus == 'active';
}

/// リコール詳細情報
class RecallDetails {
  /// 型番
  final String modelNumber;
  
  /// メーカー名
  final String manufacturer;
  
  /// リコール発生日（ISO 8601形式）
  final String date;
  
  /// リコール内容
  final String description;
  
  /// リコール理由
  final String reason;
  
  /// メーカー連絡先URL
  final String? manufacturerContactUrl;

  RecallDetails({
    required this.modelNumber,
    required this.manufacturer,
    required this.date,
    required this.description,
    required this.reason,
    this.manufacturerContactUrl,
  });

  factory RecallDetails.fromJson(Map<String, dynamic> json) {
    try {
      return RecallDetails(
        modelNumber: json['modelNumber']?.toString() ?? '',
        manufacturer: json['manufacturer']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        reason: json['reason']?.toString() ?? '',
        manufacturerContactUrl: json['manufacturerContactUrl']?.toString(),
      );
    } catch (e) {
      print('Error parsing RecallDetails: $e');
      return RecallDetails(
        modelNumber: '',
        manufacturer: '',
        date: '',
        description: '',
        reason: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'modelNumber': modelNumber,
      'manufacturer': manufacturer,
      'date': date,
      'description': description,
      'reason': reason,
      'manufacturerContactUrl': manufacturerContactUrl,
    };
  }
}
