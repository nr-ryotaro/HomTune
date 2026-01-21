import 'package:flutter/material.dart';
import '../models/device.dart';
import '../widgets/device_detail_card.dart';
import '../widgets/chat_widget.dart';
import 'add_device_screen.dart';

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
                    padding: const EdgeInsets.all(16),
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
