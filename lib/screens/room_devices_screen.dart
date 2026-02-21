import 'package:flutter/material.dart';
import '../models/device.dart';
import '../widgets/device_detail_card.dart';
import '../widgets/chat_widget.dart';
import 'add_device_screen.dart';
import '../widgets/room_card_widget.dart';
import '../models/room_card_model.dart';

class RoomDevicesScreen extends StatelessWidget {
  final String roomId;
  final String roomName;
  final List<Device> devices;

  const RoomDevicesScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.devices,
  });

  @override
  Widget build(BuildContext context) {
    // 統計情報の計算
    double totalAssetValue = 0;
    int alertCount = 0;
    int maintenanceCount = 0;

    final today = DateTime.now();

    for (var device in devices) {
      // 資産価値
      if (device.assetValue != null) {
        totalAssetValue += device.assetValue!.currentUsedPrice;
      }

      // アラート数
      if (device.maintenance?.alerts != null) {
        alertCount += device.maintenance!.alerts
            .where((a) => a.priority == 'high' || a.priority == 'medium')
            .length;
      }

      // リコールアラート
      if (device.safetyInfo?.isRecallActive == true) {
        alertCount++;
      }

      // メンテナンス数
      if (device.maintenance?.nextMaintenance != null) {
        try {
          final nextDate = DateTime.parse(device.maintenance!.nextMaintenance!);
          final daysUntil = nextDate.difference(today).inDays;
          if (daysUntil >= 0 && daysUntil <= 30) {
            maintenanceCount++;
          }
        } catch (e) {
          // ignore
        }
      }
    }

    // ヘルススコア計算（簡易ロジック）
    double healthScore = 1.0;
    if (alertCount > 0) healthScore -= 0.3;
    if (maintenanceCount > 0) healthScore -= 0.1;
    if (healthScore < 0) healthScore = 0;

    // 部屋IDや名前から画像パスを決定
    String imagePath = 'assets/images/Living_sample.jpg'; // デフォルト
    if (roomName.contains('寝室') || roomId.contains('bed')) {
      imagePath = 'assets/images/Bedroom_sample.jpg';
    } else if (roomName.contains('キッチン') || roomId.contains('kitchen')) {
      imagePath = 'assets/images/Kitchen_sample.jpg';
    }

    // RoomCardModelの作成
    final roomCardModel = RoomCardModel(
      id: roomId,
      title: roomName,
      imagePath: imagePath,
      totalAssetValue: totalAssetValue,
      maintenanceHealth: healthScore,
      alertCount: alertCount,
      maintenanceCount: maintenanceCount,
      deviceCount: devices.length,
      isAiGenerated: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          roomName,
          style: const TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddDeviceScreen(
                      initialRoomId: roomId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                '家電を追加',
                style: TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                side: const BorderSide(
                  color: Color(0xFF3b82f6),
                  width: 1,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            color: const Color(0xFFE5E5E5),
            height: 0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // ルームカード（サマリー）
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: RoomCardWidget(
                room: roomCardModel,
                onTap: () {
                  // カードタップ時のアクション（必要であれば実装）
                },
              ),
            ),
          ),

          // デバイス一覧
          Expanded(
            child: devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.devices_other,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'この部屋にはデバイスが登録されていません',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DeviceDetailCard(device: devices[index]),
                      );
                    },
                  ),
          ),
          // チャットBOX
          Container(
            height: 400,
            margin: const EdgeInsets.all(16),
            child: ChatWidget(
              devices: devices,
            ),
          ),
        ],
      ),
    );
  }
}
