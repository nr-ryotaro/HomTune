import 'source_attribution.dart';

// メンテナンスタスクモデル

/// メンテナンスタスク（デバイスごとの定期お手入れ項目）
class MaintenanceTask {
  final String taskId; // "ac_filter", "hum_tank" etc.
  final String deviceId;
  String name; // "フィルター掃除"
  int intervalDays; // 14
  int recommendedIntervalDays; // メーカー推奨間隔（カテゴリデフォルト値）
  String priority; // "high", "medium", "low"
  String shortMethod; // 簡易手順テキスト
  final List<String> requiredTools;
  final List<String> methodTags;
  final String safetyNote;
  final SourceAttribution? sourceAttribution;
  bool notifyEnabled; // ユーザーが個別に ON/OFF 可能
  DateTime? lastCompleted;
  DateTime? nextDue; // lastCompleted + intervalDays（自動計算）
  final List<DateTime> history; // 完了履歴

  MaintenanceTask({
    required this.taskId,
    required this.deviceId,
    required this.name,
    required this.intervalDays,
    int? recommendedIntervalDays,
    this.priority = 'medium',
    this.shortMethod = '',
    List<String>? requiredTools,
    List<String>? methodTags,
    this.safetyNote = '',
    this.sourceAttribution,
    this.notifyEnabled = true,
    this.lastCompleted,
    this.nextDue,
    List<DateTime>? history,
  })  : requiredTools = requiredTools ?? [],
        methodTags = methodTags ?? [],
        recommendedIntervalDays = recommendedIntervalDays ?? intervalDays,
        history = history ?? [];

  /// カテゴリデフォルト JSON からタスクを生成
  factory MaintenanceTask.fromCategoryDefault(
    Map<String, dynamic> json,
    String deviceId,
  ) {
    final interval = (json['intervalDays'] as num?)?.toInt() ?? 30;
    final source = json['sourceAttribution'] is Map<String, dynamic>
        ? SourceAttribution.fromJson(
            json['sourceAttribution'] as Map<String, dynamic>)
        : SourceAttribution(
            sourceType: SourceType.internal,
            sourceUrl: '',
            publisher: 'HomTune Editorial',
            licenseType: 'internal-curated',
            capturedAt: DateTime.now(),
            confidence: 0.8,
            reviewState: ReviewState.approved,
          );
    return MaintenanceTask(
      taskId: json['taskId']?.toString() ?? '',
      deviceId: deviceId,
      name: json['name']?.toString() ?? '',
      intervalDays: interval,
      recommendedIntervalDays: interval, // カテゴリデフォルト = 推奨値
      priority: json['priority']?.toString() ?? 'medium',
      shortMethod: json['shortMethod']?.toString() ?? '',
      requiredTools: (json['requiredTools'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      methodTags: (json['methodTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      safetyNote: json['safetyNote']?.toString() ?? '',
      sourceAttribution: source,
      notifyEnabled: json['notifyEnabled'] != false,
    );
  }

  /// 永続化用 JSON からタスクを復元
  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    final interval = (json['intervalDays'] as num?)?.toInt() ?? 30;
    return MaintenanceTask(
      taskId: json['taskId']?.toString() ?? '',
      deviceId: json['deviceId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      intervalDays: interval,
      recommendedIntervalDays:
          (json['recommendedIntervalDays'] as num?)?.toInt() ?? interval,
      priority: json['priority']?.toString() ?? 'medium',
      shortMethod: json['shortMethod']?.toString() ?? '',
      requiredTools: (json['requiredTools'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      methodTags: (json['methodTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      safetyNote: json['safetyNote']?.toString() ?? '',
      sourceAttribution: json['sourceAttribution'] is Map<String, dynamic>
          ? SourceAttribution.fromJson(
              json['sourceAttribution'] as Map<String, dynamic>)
          : null,
      notifyEnabled: json['notifyEnabled'] != false,
      lastCompleted: json['lastCompleted'] != null
          ? DateTime.tryParse(json['lastCompleted'].toString())
          : null,
      nextDue: json['nextDue'] != null
          ? DateTime.tryParse(json['nextDue'].toString())
          : null,
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => DateTime.tryParse(e.toString()))
              .whereType<DateTime>()
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'deviceId': deviceId,
      'name': name,
      'intervalDays': intervalDays,
      'recommendedIntervalDays': recommendedIntervalDays,
      'priority': priority,
      'shortMethod': shortMethod,
      'requiredTools': requiredTools,
      'methodTags': methodTags,
      'safetyNote': safetyNote,
      'sourceAttribution': sourceAttribution?.toJson(),
      'notifyEnabled': notifyEnabled,
      'lastCompleted': lastCompleted?.toIso8601String(),
      'nextDue': nextDue?.toIso8601String(),
      'history': history.map((e) => e.toIso8601String()).toList(),
    };
  }

  /// タスクを完了として記録し、次回日を再計算
  void complete() {
    final now = DateTime.now();
    lastCompleted = now;
    nextDue = now.add(Duration(days: intervalDays));
    history.add(now);
  }

  /// 間隔を変更し、次回期限を再計算
  void updateInterval(int newIntervalDays) {
    intervalDays = newIntervalDays;
    if (lastCompleted != null) {
      nextDue = lastCompleted!.add(Duration(days: intervalDays));
    } else if (nextDue != null) {
      // lastCompleted がない場合は、現在の nextDue から逆算して再設定
      nextDue = DateTime.now().add(Duration(days: intervalDays));
    }
  }

  /// 初回の nextDue を設定（デバイス登録時）
  void initializeNextDue(DateTime? devicePurchaseDate) {
    if (nextDue != null) return; // 既に設定済み

    final baseDate = devicePurchaseDate ?? DateTime.now();
    // 購入日から intervalDays 経過後を最初の期限とする
    // ただし過去の場合は今日から intervalDays 後に設定
    final calculated = baseDate.add(Duration(days: intervalDays));
    final now = DateTime.now();

    if (calculated.isBefore(now)) {
      // 購入日からだと既に過去 → 今日基準で次回を設定
      // ただし「期限超過」を表現するため、最も近い過去サイクルの期限を計算
      final daysSincePurchase = now.difference(baseDate).inDays;
      final cyclesPassed = daysSincePurchase ~/ intervalDays;
      nextDue = baseDate.add(Duration(days: (cyclesPassed + 1) * intervalDays));
    } else {
      nextDue = calculated;
    }
  }

  /// 期限超過しているかどうか
  bool get isOverdue {
    if (nextDue == null) return false;
    return DateTime.now().isAfter(nextDue!);
  }

  /// 今日から7日以内に期限が来るか
  bool get isDueSoon {
    if (nextDue == null) return false;
    final now = DateTime.now();
    final weekLater = now.add(const Duration(days: 7));
    return nextDue!.isAfter(now) && !nextDue!.isAfter(weekLater);
  }

  /// 期限までの残り日数（負の値は超過日数）
  int get daysUntilDue {
    if (nextDue == null) return 0;
    return nextDue!.difference(DateTime.now()).inDays;
  }

  /// 表示用の優先度アイコン
  String get priorityIcon {
    switch (priority) {
      case 'high':
        return '🔴';
      case 'medium':
        return '🟡';
      case 'low':
        return '🟢';
      default:
        return '⚪';
    }
  }

  /// ユーザーが推奨より長い間隔に設定したか
  bool get isIntervalLongerThanRecommended =>
      intervalDays > recommendedIntervalDays;

  /// 前回完了からの経過日数（未完了の場合は null）
  int? get daysSinceLastCompleted {
    if (lastCompleted == null) return null;
    return DateTime.now().difference(lastCompleted!).inDays;
  }
}
