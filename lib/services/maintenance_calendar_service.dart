import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/device.dart';
import '../models/maintenance_task.dart';
import '../utils/category_mapper.dart';
import 'config_service.dart';
import 'compliance_service.dart';

/// メンテナンスカレンダーのコアロジック
///
/// - カテゴリデフォルトからタスクを自動割り当て
/// - 期限超過 / 今週内 / 今後のタスクを分類
/// - 完了記録 + 次回日の自動再計算
/// - お手入れ方法: shortMethod → Gemini AI / ダミー → 汎用テキスト
/// - 永続化（SharedPreferences）
class MaintenanceCalendarService {
  static Map<String, List<Map<String, dynamic>>>? _categoryDefaults;

  /// Gemini API モデル名
  static const String _geminiModel = 'gemini-2.0-flash-exp';

  /// AI 生成した手順テキストのキャッシュ（deviceId:taskId → text）
  static final Map<String, String> _aiMethodCache = {};

  /// カテゴリデフォルトの読み込み
  static Future<Map<String, List<Map<String, dynamic>>>>
      _loadCategoryDefaults() async {
    if (_categoryDefaults != null) return _categoryDefaults!;

    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/category-defaults.json');
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final tasks = json['maintenanceTasks'] as Map<String, dynamic>?;
      if (tasks == null) {
        _categoryDefaults = {};
        return _categoryDefaults!;
      }

      _categoryDefaults = {};
      for (final entry in tasks.entries) {
        _categoryDefaults![entry.key] = (entry.value as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
      return _categoryDefaults!;
    } catch (e) {
      print('Error loading category defaults: $e');
      _categoryDefaults = {};
      return _categoryDefaults!;
    }
  }

  /// デバイスのカテゴリに基づいてメンテナンスタスクを自動割り当て
  static Future<List<MaintenanceTask>> initializeTasksForDevice(
      Device device) async {
    final defaults = await _loadCategoryDefaults();

    // カテゴリに一致するタスクテンプレートを検索（英語カテゴリもマッピング）
    final categoryKey = CategoryMapper.normalize(device.category);
    final templates = defaults[categoryKey] ?? defaults[device.category];
    if (templates == null || templates.isEmpty) return [];

    final purchaseDate = DateTime.tryParse(device.purchaseDate);

    final tasks = <MaintenanceTask>[];
    for (final template in templates) {
      final task = MaintenanceTask.fromCategoryDefault(template, device.id);
      final attribution = task.sourceAttribution;
      if (attribution != null && !ComplianceService.canDistribute(attribution)) {
        ComplianceService.logEvent(
          action: 'maintenance_template_filtered',
          targetId: '${device.id}:${task.taskId}',
          result: 'blocked',
          reason: 'source_not_distributable',
        );
        continue;
      }
      task.initializeNextDue(purchaseDate);
      tasks.add(task);
    }
    return tasks;
  }

  /// 全デバイスから「期限超過」タスクを取得
  static List<UpcomingTask> getOverdueTasks(List<Device> devices) {
    final results = <UpcomingTask>[];
    for (final device in devices) {
      for (final task in device.maintenanceTasks) {
        if (task.isOverdue) {
          results.add(UpcomingTask(device: device, task: task));
        }
      }
    }
    // 超過日数が多い順にソート（daysUntilDue は負値なので昇順＝より深刻な超過が先）
    results.sort((a, b) => a.task.daysUntilDue.compareTo(b.task.daysUntilDue));
    return results;
  }

  /// 全デバイスから「今週中に期限」タスクを取得
  static List<UpcomingTask> getUpcomingTasks(List<Device> devices) {
    final results = <UpcomingTask>[];
    for (final device in devices) {
      for (final task in device.maintenanceTasks) {
        if (task.isDueSoon && !task.isOverdue) {
          results.add(UpcomingTask(device: device, task: task));
        }
      }
    }
    // 近い順にソート
    results.sort((a, b) => a.task.daysUntilDue.compareTo(b.task.daysUntilDue));
    return results;
  }

  /// 全デバイスから「来週以降」タスクを取得
  static List<UpcomingTask> getFutureTasks(List<Device> devices) {
    final results = <UpcomingTask>[];
    for (final device in devices) {
      for (final task in device.maintenanceTasks) {
        if (!task.isOverdue && !task.isDueSoon && task.nextDue != null) {
          results.add(UpcomingTask(device: device, task: task));
        }
      }
    }
    results.sort((a, b) => a.task.daysUntilDue.compareTo(b.task.daysUntilDue));
    return results;
  }

  /// 全デバイスの期限超過 + 今週タスクの合計件数
  static int getActionRequiredCount(List<Device> devices) {
    int count = 0;
    for (final device in devices) {
      for (final task in device.maintenanceTasks) {
        if (task.isOverdue || task.isDueSoon) {
          count++;
        }
      }
    }
    return count;
  }

  /// タスクを完了として記録
  static void completeTask(MaintenanceTask task) {
    task.complete();
  }

  // ── お手入れ方法テキスト（法務ゲート付き） ──

  /// お手入れ方法テキストを取得（非同期・法務ゲート付き）
  static Future<String> getMethodText(
    MaintenanceTask task,
    Device device,
    ConfigService configService,
  ) async {
    // ① 事実データから自社文面テンプレート生成（優先）
    final templated = _buildComplianceTemplate(task, device);
    if (templated != null) {
      return templated;
    }

    // 本番では未承認ソースを配信しない
    if (kReleaseMode) {
      await ComplianceService.logEvent(
        action: 'maintenance_method_blocked',
        targetId: '${device.id}:${task.taskId}',
        result: 'blocked',
        reason: 'missing_or_unapproved_source',
      );
      return 'この手順は法務確認中です。取扱説明書またはメーカー公式サポートをご確認ください。';
    }

    // ② 開発時のみ互換で既存 shortMethod を許可
    if (task.shortMethod.isNotEmpty) {
      return task.shortMethod;
    }

    // ③ AI 生成 or ダミー応答
    final cacheKey = '${device.id}:${task.taskId}';
    if (_aiMethodCache.containsKey(cacheKey)) {
      return _aiMethodCache[cacheKey]!;
    }

    try {
      String result;
      if (configService.isUsingRealApi) {
        result = await _generateWithGemini(task, device);
      } else {
        result = _generateDummyMethod(task, device);
      }
      _aiMethodCache[cacheKey] = result;
      return result;
    } catch (e) {
      print('AI method text generation error: $e');
    }

    // ④ 汎用フォールバック
    return 'お手入れ方法の詳細は取扱説明書をご確認ください。';
  }

  /// 同期版（テンプレート優先。未承認データは非表示）
  static String getMethodTextSync(MaintenanceTask task) {
    final templated = _buildComplianceTemplate(task, null);
    if (templated != null) return templated;

    if (kReleaseMode) {
      return 'この手順は法務確認中です。取扱説明書またはメーカー公式サポートをご確認ください。';
    }
    if (task.shortMethod.isNotEmpty) return task.shortMethod;

    final cacheKey = '${task.deviceId}:${task.taskId}';
    if (_aiMethodCache.containsKey(cacheKey)) {
      return _aiMethodCache[cacheKey]!;
    }

    return 'お手入れ方法の詳細は取扱説明書をご確認ください。';
  }

  static String? _buildComplianceTemplate(
    MaintenanceTask task,
    Device? device,
  ) {
    final attribution = task.sourceAttribution;
    if (attribution == null) return null;
    if (!ComplianceService.canDistribute(attribution)) return null;

    final tools = task.requiredTools.isNotEmpty
        ? task.requiredTools.join('、')
        : '柔らかい布・中性洗剤';
    final target = device?.name ?? '対象機器';
    final tags = task.methodTags.isNotEmpty ? task.methodTags : <String>['clean'];
    final firstAction = tags.contains('power_off')
        ? '電源を切り、プラグを抜いて安全を確認します。'
        : '安全を確認してから作業を開始します。';
    final secondAction = tags.contains('water_wash')
        ? '取り外せる部品を洗浄し、十分に乾燥させます。'
        : '汚れを拭き取り、必要な箇所を清掃します。';
    final safety = task.safetyNote.isNotEmpty
        ? task.safetyNote
        : '異常や破損がある場合は作業を中止してメーカーへお問い合わせください。';

    return '【必要な道具】$tools\n\n'
        '1. $firstAction\n'
        '2. $secondAction\n'
        '3. 清掃後に$targetの動作を確認します。\n\n'
        '推奨頻度: ${task.intervalDays}日ごと\n'
        '注意: $safety';
  }

  /// Gemini API でお手入れ手順を生成
  static Future<String> _generateWithGemini(
      MaintenanceTask task, Device device) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) {
      return _generateDummyMethod(task, device);
    }

    final model = GenerativeModel(
      model: _geminiModel,
      apiKey: apiKey,
    );

    final prompt = '''あなたは家電のメンテナンス専門家です。
以下の家電のお手入れ方法を、具体的かつ安全に説明してください。

【製品情報】
- 製品名: ${device.name}
- メーカー: ${device.manufacturer}
- 型番: ${device.modelNumber}
- カテゴリ: ${device.category}
- 所有期間: ${device.yearsOwned}年

【お手入れ項目】
- タスク名: ${task.name}
- 推奨頻度: ${task.intervalDays}日ごと

【回答ルール】
1. 手順は番号付きリスト形式で記述
2. 必要な道具を最初に明示
3. 安全上の注意点は先に記述
4. 200文字以内で簡潔に
5. 日本語で回答''';

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text?.trim();
    if (text != null && text.isNotEmpty) return text;

    return _generateDummyMethod(task, device);
  }

  /// ダミー応答生成（APIオフ時の高品質なローカル応答）
  ///
  /// タスク名とカテゴリに基づいて実用的なお手入れ手順を返す
  static String _generateDummyMethod(MaintenanceTask task, Device device) {
    // タスク名のキーワードに基づく応答マップ
    final taskKeywordResponses = <String, String>{
      'フィルター': '【必要な道具】掃除機、柔らかいブラシ、中性洗剤\n\n'
          '① 電源を切り、プラグを抜きます\n'
          '② フィルターを取り外します\n'
          '③ 掃除機でホコリを吸い取ります\n'
          '④ 汚れがひどい場合は、ぬるま湯（40℃以下）で中性洗剤を使い、やさしく洗います\n'
          '⑤ 完全に乾燥させてから取り付けます\n\n'
          '⚠️ 乾燥が不十分だとカビ発生の原因になります',
      'タンク': '【必要な道具】柔らかいスポンジ、中性洗剤\n\n'
          '① 水タンクの残水を捨てます\n'
          '② 少量の水を入れ、振り洗いします\n'
          '③ タンクの蓋やパッキンもスポンジで洗います\n'
          '④ ぬめりがある場合は中性洗剤を使います\n'
          '⑤ すすぎ後、自然乾燥させます\n\n'
          '⚠️ 毎日の水交換を推奨します',
      '庫内': '【必要な道具】柔らかい布2枚、中性洗剤（薄め）\n\n'
          '① 電源を切ります\n'
          '② 中性洗剤を水で薄めた布で庫内を拭きます\n'
          '③ きれいな水で絞った布で洗剤を拭き取ります\n'
          '④ ドアパッキン部分も忘れずに拭きます\n\n'
          '⚠️ 研磨剤・アルコールは表面を傷めるため使用不可',
      'パッキン': '【必要な道具】柔らかい布、綿棒、中性洗剤\n\n'
          '① ドアパッキンを湿らせた布で拭きます\n'
          '② 隙間の汚れは綿棒で取り除きます\n'
          '③ カビがある場合はカビ取り剤を使います\n'
          '④ 密閉不良は電気代増加の原因になります\n\n'
          '⚠️ パッキンのヒビや変形を発見したらメーカーに連絡',
      '排水': '【必要な道具】ぬるま湯、柔らかいブラシ\n\n'
          '① 排水口の蓋を外します\n'
          '② ごみやホコリを取り除きます\n'
          '③ ぬるま湯を流して詰まりがないか確認\n'
          '④ 蓋を元に戻します\n\n'
          '⚠️ 定期的な確認で水漏れを防止できます',
      '背面': '【必要な道具】掃除機（ノズル付き）、乾いた布\n\n'
          '① ${device.name}を少し手前に引き出します\n'
          '② 背面・底面のホコリを掃除機で吸い取ります\n'
          '③ 放熱部分は乾いた布で拭きます\n'
          '④ 元の位置に戻します\n\n'
          '⚠️ 放熱効率を維持し省エネにつながります',
      'トレー': '【必要な道具】スポンジ、中性洗剤、クエン酸（任意）\n\n'
          '① トレーを取り外します\n'
          '② スポンジと中性洗剤で洗います\n'
          '③ 水アカにはクエン酸水（1〜2時間つけ置き）\n'
          '④ すすいで乾燥後に戻します',
    };

    // タスク名からキーワードマッチ
    for (final entry in taskKeywordResponses.entries) {
      if (task.name.contains(entry.key)) {
        return entry.value;
      }
    }

    // カテゴリベースの汎用応答
    return '【${device.name}の${task.name}】\n\n'
        '① 電源を切り、安全を確認します\n'
        '② 取扱説明書の指示に従い、該当箇所を清掃します\n'
        '③ 作業後、正常に動作するか確認します\n\n'
        '推奨頻度: ${task.intervalDays}日ごと\n\n'
        '⚠️ 不明な点はメーカー（${device.manufacturer}）のサポートへお問い合わせください';
  }

  /// マニュアル PDF リンクがあるかどうか
  static bool hasManualLink(Device device) {
    final url = device.manualPdfUrl;
    if (url == null || url.isEmpty) return false;
    return ComplianceService.isAllowedSourceUrl(url);
  }

  // ── 永続化 ──

  static const _storageKey = 'maintenance_tasks';

  /// 全デバイスのメンテタスクを永続化
  static Future<void> saveTasks(List<Device> devices) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allTasks = <String, dynamic>{};
      for (final device in devices) {
        if (device.maintenanceTasks.isNotEmpty) {
          allTasks[device.id] =
              device.maintenanceTasks.map((t) => t.toJson()).toList();
        }
      }
      await prefs.setString(_storageKey, jsonEncode(allTasks));
    } catch (e) {
      print('Error saving maintenance tasks: $e');
    }
  }

  /// 永続化されたメンテタスクを読み込み、デバイスに適用
  static Future<List<MaintenanceTask>> loadTasksForDevice(
      String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      if (stored == null) return [];

      final allTasks = jsonDecode(stored) as Map<String, dynamic>;
      final deviceTasks = allTasks[deviceId] as List<dynamic>?;
      if (deviceTasks == null) return [];

      return deviceTasks
          .map((e) => MaintenanceTask.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading maintenance tasks: $e');
      return [];
    }
  }
}

/// 期限タスクの表示用データ（デバイス情報 + タスク情報のペア）
class UpcomingTask {
  final Device device;
  final MaintenanceTask task;

  UpcomingTask({required this.device, required this.task});
}
