import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../services/device_service.dart';
import '../widgets/device_detail_card.dart';
import 'add_device_screen.dart';

/// すべての家電を一覧表示する画面
class AllDevicesScreen extends StatelessWidget {
  const AllDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'すべての家電',
          style: TextStyle(
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
                    builder: (context) => const AddDeviceScreen(),
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
      body: Consumer<DeviceService>(
        builder: (context, deviceService, child) {
          if (deviceService.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (deviceService.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    deviceService.errorMessage!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final devices = deviceService.devices;

          if (devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.devices_other,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '登録されている家電がありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            );
          }

          // 部屋ごとにグループ化（roomフィールドは部屋名）
          final devicesByRoom = <String, List<Device>>{};
          for (final device in devices) {
            final roomName = device.room.isNotEmpty ? device.room : '未分類';
            devicesByRoom.putIfAbsent(roomName, () => []).add(device);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: devicesByRoom.length,
            itemBuilder: (context, index) {
              final roomName = devicesByRoom.keys.elementAt(index);
              final roomDevices = devicesByRoom[roomName]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 部屋名ヘッダー
                  Padding(
                    padding: EdgeInsets.only(
                      top: index > 0 ? 24 : 0,
                      bottom: 12,
                    ),
                    child: Row(
                      children: [
                        Text(
                          roomName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3b82f6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${roomDevices.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3b82f6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // デバイス一覧
                  ...roomDevices.map(
                    (device) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DeviceDetailCard(device: device),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
