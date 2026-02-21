import 'package:flutter/foundation.dart';
import '../models/device.dart';
import '../models/maintenance_task.dart';

/// メンテナンス通知サービス
///
/// ローカル通知のスケジューリング・管理を担当。
/// flutter_local_notifications が利用できない環境ではログ出力のみ。
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// 通知の初期化
  ///
  /// 実デバイスでは flutter_local_notifications を初期化。
  /// デモ・シミュレータ環境ではスキップしてログ出力。
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // NOTE: flutter_local_notifications パッケージが追加された場合、
      //       ここで FlutterLocalNotificationsPlugin を初期化。
      //       現在はプラットフォーム設定不要で動作するログベースの実装。
      _initialized = true;
      if (kDebugMode) {
        print('NotificationService: initialized (log-based)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: initialization failed: $e');
      }
    }
  }

  /// 全デバイスのメンテナンスタスク通知をスケジュール
  Future<void> scheduleAllMaintenanceNotifications(List<Device> devices) async {
    if (!_initialized) await initialize();

    int scheduled = 0;
    for (final device in devices) {
      for (final task in device.maintenanceTasks) {
        if (task.notifyEnabled && task.nextDue != null) {
          await _scheduleTaskNotification(device, task);
          scheduled++;
        }
      }
    }

    if (kDebugMode) {
      print('NotificationService: $scheduled notifications scheduled');
    }
  }

  /// 個別タスクの通知をスケジュール（優先度別）
  Future<void> _scheduleTaskNotification(
      Device device, MaintenanceTask task) async {
    if (task.nextDue == null || !task.notifyEnabled) return;

    // 低優先度はバッジのみ（通知なし）
    if (task.priority == 'low') {
      if (kDebugMode) {
        print('  BADGE ONLY: ${device.name} / ${task.name} (low priority)');
      }
      return;
    }

    final now = DateTime.now();
    final scheduleDates = _getScheduleDates(task);

    for (final date in scheduleDates) {
      if (date.isBefore(now)) continue; // 過去の日付はスキップ

      final notificationId = _generateNotificationId(
          '${task.taskId}_${date.millisecondsSinceEpoch}', device.id);

      if (kDebugMode) {
        print(
            '  SCHEDULED: ${device.name} / ${task.name} [${task.priority}] → $date (id=$notificationId)');
      }
    }

    // 超過時のリマインド設定もログ出力
    if (task.isOverdue) {
      final reminderInterval = task.priority == 'high' ? 1 : 3;
      if (kDebugMode) {
        print(
            '  OVERDUE REMIND: ${device.name} / ${task.name} → every $reminderInterval day(s)');
      }
    }
  }

  /// 優先度に応じた通知日リストを生成
  List<DateTime> _getScheduleDates(MaintenanceTask task) {
    if (task.nextDue == null) return [];
    final dueDate = task.nextDue!;

    switch (task.priority) {
      case 'high':
        // 3日前 + 当日 + 1日後
        return [
          dueDate.subtract(const Duration(days: 3)),
          dueDate,
          dueDate.add(const Duration(days: 1)),
        ];
      case 'medium':
        // 当日のみ
        return [dueDate];
      default:
        // 低: 通知なし
        return [];
    }
  }

  /// タスク完了時に次回通知を再スケジュール
  Future<void> rescheduleAfterCompletion(
      Device device, MaintenanceTask task) async {
    // 完了済みタスクの古い通知をキャンセル
    final oldId = _generateNotificationId(task.taskId, device.id);
    await _cancelNotification(oldId);

    // 次回期日が設定されていれば再スケジュール
    if (task.nextDue != null && task.notifyEnabled) {
      await _scheduleTaskNotification(device, task);
    }
  }

  /// 通知のキャンセル
  Future<void> _cancelNotification(int id) async {
    if (kDebugMode) {
      print('  CANCELLED: notification id=$id');
    }
    // NOTE: await _plugin.cancel(id);
  }

  /// 全通知のキャンセル
  Future<void> cancelAllNotifications() async {
    if (kDebugMode) {
      print('NotificationService: all notifications cancelled');
    }
    // NOTE: await _plugin.cancelAll();
  }

  /// 通知ペイロードの解析
  ///
  /// ペイロード形式: "deviceId|taskId"
  static ({String deviceId, String taskId})? parsePayload(String? payload) {
    if (payload == null || !payload.contains('|')) return null;
    final parts = payload.split('|');
    if (parts.length != 2) return null;
    return (deviceId: parts[0], taskId: parts[1]);
  }

  /// 通知 ID 生成（taskId + deviceId → 一意の int）
  int _generateNotificationId(String taskId, String deviceId) {
    return ('$taskId:$deviceId'.hashCode).abs() % 100000;
  }

  /// デモ用: 即座に通知的なメッセージを生成（UI 表示用）
  static String createReminderMessage(Device device, MaintenanceTask task) {
    if (task.isOverdue) {
      return '⚠️ ${device.name}の「${task.name}」が${-task.daysUntilDue}日超過しています';
    } else if (task.isDueSoon) {
      return '🔔 ${device.name}の「${task.name}」があと${task.daysUntilDue}日で期限です';
    }
    return '📅 ${device.name}の「${task.name}」: ${task.daysUntilDue}日後に予定';
  }
}
