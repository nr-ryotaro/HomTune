import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../models/maintenance_task.dart';
import '../services/device_service.dart';
import '../services/maintenance_calendar_service.dart';
import 'maintenance_detail_screen.dart';

/// メンテナンスカレンダー画面
///
/// 各部屋ごとに登録されている家電のメンテタスクを表示。
/// 部屋内では期限超過→今週→今後の順で表示。
class MaintenanceCalendarScreen extends StatefulWidget {
  const MaintenanceCalendarScreen({super.key});

  @override
  State<MaintenanceCalendarScreen> createState() =>
      _MaintenanceCalendarScreenState();
}

class _MaintenanceCalendarScreenState extends State<MaintenanceCalendarScreen> {
  @override
  Widget build(BuildContext context) {
    final deviceService = Provider.of<DeviceService>(context);
    final devices = deviceService.devices;
    final rooms = deviceService.rooms;

    // 部屋ごとにデバイスをグループ化
    final roomGroups = <String, List<Device>>{};
    final roomNames = <String, String>{};

    for (final device in devices) {
      if (device.maintenanceTasks.isEmpty) continue;
      final roomId = device.room;
      roomGroups.putIfAbsent(roomId, () => []);
      roomGroups[roomId]!.add(device);
    }

    // 部屋名を取得
    for (final roomId in roomGroups.keys) {
      final matchingRoom = rooms.where((r) => r.id == roomId);
      if (matchingRoom.isNotEmpty) {
        roomNames[roomId] = matchingRoom.first.name;
      } else {
        // フォールバック: ID がそのまま名前
        roomNames[roomId] = _fallbackRoomName(roomId);
      }
    }

    final hasAnyTasks = roomGroups.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: const Text('メンテナンスカレンダー'),
        backgroundColor: const Color(0xFFF8F6F0),
        foregroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
      ),
      body: !hasAnyTasks
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 資産価値維持バナー
                _buildAssetValueBanner(devices),

                // 期限超過サマリー（部屋横断）
                _buildOverdueSummary(devices),

                // スマートナッジメッセージ
                _buildNudgeMessages(devices),

                // 部屋ごとのセクション
                ...roomGroups.entries.map((entry) {
                  final roomId = entry.key;
                  final roomDevices = entry.value;
                  final roomName = roomNames[roomId] ?? roomId;
                  return _buildRoomSection(roomName, roomDevices);
                }),

                const SizedBox(height: 40),
              ],
            ),
    );
  }

  /// 期限超過サマリーバナー（部屋横断で件数表示）
  Widget _buildOverdueSummary(List<Device> devices) {
    final overdue = MaintenanceCalendarService.getOverdueTasks(devices);
    if (overdue.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${overdue.length}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ 期限超過 ${overdue.length}件',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '早めにお手入れしましょう',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 部屋セクション
  Widget _buildRoomSection(String roomName, List<Device> roomDevices) {
    // 部屋内のタスクを期限順に集約
    final allTasks = <_RoomTask>[];
    for (final device in roomDevices) {
      for (final task in device.maintenanceTasks) {
        allTasks.add(_RoomTask(device: device, task: task));
      }
    }
    // 期限超過 → 今週 → 今後の順にソート
    allTasks.sort((a, b) {
      // 超過を先頭に
      if (a.task.isOverdue && !b.task.isOverdue) return -1;
      if (!a.task.isOverdue && b.task.isOverdue) return 1;
      // 今週を次に
      if (a.task.isDueSoon && !b.task.isDueSoon) return -1;
      if (!a.task.isDueSoon && b.task.isDueSoon) return 1;
      return a.task.daysUntilDue.compareTo(b.task.daysUntilDue);
    });

    // 部屋のアイコン決定
    final roomIcon = _getRoomIcon(roomName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 部屋ヘッダー
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDE6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(roomIcon, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                roomName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${roomDevices.length}台',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),

        // タスクカード
        ...allTasks.map((rt) => _buildTaskCard(rt)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTaskCard(_RoomTask rt) {
    final task = rt.task;
    final device = rt.device;
    final dateFormat = DateFormat('M/d(E)', 'ja_JP');

    Color cardBorder;
    Color iconColor;
    if (task.isOverdue) {
      cardBorder = Colors.red.shade200;
      iconColor = Colors.red.shade400;
    } else if (task.isDueSoon) {
      cardBorder = Colors.amber.shade200;
      iconColor = Colors.amber.shade600;
    } else {
      cardBorder = Colors.grey.shade200;
      iconColor = Colors.grey.shade400;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: InkWell(
        onTap: () => _openDetail(device, task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 優先度アイコン
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    task.priorityIcon,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // テキスト
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                  ],
                ),
              ),

              // 日付 or 超過数
              if (task.isOverdue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(-task.daysUntilDue)}日超過',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                )
              else if (task.nextDue != null)
                Text(
                  dateFormat.format(task.nextDue!),
                  style: TextStyle(
                    fontSize: 12,
                    color: task.isDueSoon
                        ? Colors.amber.shade800
                        : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),

              const SizedBox(width: 6),

              // お手入れボタン
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: task.isOverdue
                      ? Colors.red.shade50
                      : const Color(0xFFF0EDE6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'お手入れ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: task.isOverdue
                        ? Colors.red.shade700
                        : const Color(0xFF2C2C2C),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'メンテナンスタスクはありません',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'デバイスを登録すると自動でスケジュールされます',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  void _openDetail(Device device, MaintenanceTask task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaintenanceDetailScreen(
          device: device,
          task: task,
          onCompleted: () => setState(() {}),
        ),
      ),
    );
  }

  /// 部屋 ID からフォールバック名を推測
  String _fallbackRoomName(String roomId) {
    if (roomId.contains('living')) return 'リビング';
    if (roomId.contains('bedroom')) return '寝室';
    if (roomId.contains('kitchen')) return 'キッチン';
    if (roomId.contains('bath')) return 'バスルーム';
    if (roomId.contains('entrance')) return '玄関';
    return roomId;
  }

  /// 部屋名からアイコンを選択
  String _getRoomIcon(String roomName) {
    if (roomName.contains('リビング') || roomName.contains('Living')) return '🛋️';
    if (roomName.contains('寝室') || roomName.contains('Bedroom')) return '🛏️';
    if (roomName.contains('キッチン') || roomName.contains('Kitchen')) return '🍳';
    if (roomName.contains('バス') || roomName.contains('Bath')) return '🛁';
    if (roomName.contains('玄関') || roomName.contains('Entrance')) return '🚪';
    if (roomName.contains('和室')) return '🏠';
    return '🏠';
  }

  /// 資産価値維持バナー
  Widget _buildAssetValueBanner(List<Device> devices) {
    // 完了タスク数から推定維持額を計算
    int completedCount = 0;
    double totalValue = 0;
    for (var d in devices) {
      if (d.assetValue != null) {
        totalValue += d.assetValue!.currentUsedPrice;
      }
      for (var task in d.maintenanceTasks) {
        completedCount += task.history.length;
      }
    }

    if (completedCount == 0) return const SizedBox.shrink();

    // 1回のメンテ完了ごとに資産価値の0.5%を維持と推定
    final preservedValue = (totalValue * 0.005 * completedCount).round();
    if (preservedValue <= 0) return const SizedBox.shrink();

    final formatter = NumberFormat('#,###');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                '💰',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'お手入れで資産価値を維持',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '推定¥${formatter.format(preservedValue)}の価値を維持しています',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.teal.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// スマートナッジメッセージ（長期未実施タスク向け）
  Widget _buildNudgeMessages(List<Device> devices) {
    final nudges = <Widget>[];

    for (var d in devices) {
      for (var task in d.maintenanceTasks) {
        final daysSince = task.daysSinceLastCompleted;
        // 推奨間隔の2倍以上経過しているタスクにナッジ
        if (daysSince != null && daysSince > task.recommendedIntervalDays * 2) {
          nudges.add(
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Text('⏰',
                      style: TextStyle(
                          fontSize: 16, color: Colors.orange.shade700)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${d.name}の「${task.name}」─ 最後のお手入れから$daysSince日経過しています',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    if (nudges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...nudges,
        const SizedBox(height: 8),
      ],
    );
  }
}

/// 部屋内タスク表示用のヘルパー
class _RoomTask {
  final Device device;
  final MaintenanceTask task;

  _RoomTask({required this.device, required this.task});
}
