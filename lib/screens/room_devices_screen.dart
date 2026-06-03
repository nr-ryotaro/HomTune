import 'package:flutter/material.dart';
import '../models/appliance_presentation.dart';
import '../models/device.dart';
import '../services/appliance_template_service.dart';
import '../widgets/device_detail_card.dart';
import '../widgets/chat_widget.dart';
import 'add_appliance_screen.dart';
import '../widgets/room_card_widget.dart';
import '../models/room_card_model.dart';
import '../widgets/ads/free_plan_ad_body.dart';

class RoomDevicesScreen extends StatefulWidget {
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
  State<RoomDevicesScreen> createState() => _RoomDevicesScreenState();
}

class _RoomDevicesScreenState extends State<RoomDevicesScreen> {
  Map<String, AppliancePresentation> _presentations = {};

  @override
  void initState() {
    super.initState();
    _loadPresentations();
  }

  Future<void> _loadPresentations() async {
    final map = <String, AppliancePresentation>{};
    for (final device in widget.devices) {
      map[device.id] =
          await ApplianceTemplateService.instance.resolvePresentation(device);
    }
    if (!mounted) return;
    setState(() => _presentations = map);
  }

  @override
  Widget build(BuildContext context) {
    final devices = widget.devices;

    double totalAssetValue = 0;
    int alertCount = 0;
    int maintenanceCount = 0;

    final today = DateTime.now();

    for (var device in devices) {
      if (device.assetValue != null) {
        totalAssetValue += device.assetValue!.currentUsedPrice;
      }

      if (device.maintenance?.alerts != null) {
        alertCount += device.maintenance!.alerts
            .where((a) => a.priority == 'high' || a.priority == 'medium')
            .length;
      }

      if (device.safetyInfo?.isRecallActive == true) {
        alertCount++;
      }

      if (device.maintenance?.nextMaintenance != null) {
        try {
          final nextDate =
              DateTime.parse(device.maintenance!.nextMaintenance!);
          final daysUntil = nextDate.difference(today).inDays;
          if (daysUntil >= 0 && daysUntil <= 30) {
            maintenanceCount++;
          }
        } catch (e) {
          // ignore
        }
      }
    }

    double healthScore = 1.0;
    if (alertCount > 0) healthScore -= 0.3;
    if (maintenanceCount > 0) healthScore -= 0.1;
    if (healthScore < 0) healthScore = 0;

    String imagePath = 'assets/images/Living_sample.jpg';
    if (widget.roomName.contains('寝室') || widget.roomId.contains('bed')) {
      imagePath = 'assets/images/Bedroom_sample.jpg';
    } else if (widget.roomName.contains('キッチン') ||
        widget.roomId.contains('kitchen')) {
      imagePath = 'assets/images/Kitchen_sample.jpg';
    }

    final roomCardModel = RoomCardModel(
      id: widget.roomId,
      title: widget.roomName,
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
          widget.roomName,
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
                    builder: (context) => AddApplianceScreen(
                      initialRoomId: widget.roomId,
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
      body: FreePlanAdBody(
        placement: 'room_list',
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: RoomCardWidget(
                    room: roomCardModel,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildRoomStatusSummary(
              context,
              healthScore: healthScore,
              alertCount: alertCount,
              maintenanceCount: maintenanceCount,
            ),
          ),
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
                      final device = devices[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DeviceDetailCard(
                          device: device,
                          presentation: _presentations[device.id],
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(
            height: 220,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ChatWidget(
                devices: devices,
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomStatusSummary(
    BuildContext context, {
    required double healthScore,
    required int alertCount,
    required int maintenanceCount,
  }) {
    final score = (healthScore * 100).round();
    final String label;
    final Color dotColor;
    if (healthScore >= 0.8) {
      label = '良好';
      dotColor = const Color(0xFF22C55E);
    } else if (healthScore >= 0.5) {
      label = '注意';
      dotColor = const Color(0xFFF59E0B);
    } else {
      label = '要対応';
      dotColor = const Color(0xFFEF4444);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E5E5), width: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label ($score%)',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const Spacer(),
          Text(
            '警告 $alertCount ・ 近日 $maintenanceCount',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }
}
