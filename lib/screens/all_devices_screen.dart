import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appliance_presentation.dart';
import '../models/device.dart';
import '../services/appliance_template_service.dart';
import '../services/device_service.dart';
import '../widgets/appliance_detail_card.dart';
import '../widgets/edit_device_appearance_sheet.dart';
import 'add_appliance_screen.dart';
import 'device_detail_screen.dart';

/// すべての家電を一覧表示する画面
class AllDevicesScreen extends StatefulWidget {
  const AllDevicesScreen({super.key});

  @override
  State<AllDevicesScreen> createState() => _AllDevicesScreenState();
}

class _AllDevicesScreenState extends State<AllDevicesScreen> {
  Map<String, AppliancePresentation> _presentations = {};

  Future<void> _loadPresentations(List<Device> devices) async {
    final map = <String, AppliancePresentation>{};
    for (final device in devices) {
      map[device.id] =
          await ApplianceTemplateService.instance.resolvePresentation(device);
    }
    if (!mounted) return;
    setState(() => _presentations = map);
  }

  bool _deviceNeedsAttention(Device device) {
    if (device.safetyInfo?.isRecallActive == true) return true;
    final alerts = device.maintenance?.alerts ?? [];
    return alerts.any((a) => a.priority == 'high' || a.priority == 'medium');
  }

  String _roomLabel(String roomId) {
    switch (roomId) {
      case 'living-room':
        return 'リビング';
      case 'study':
        return '書斎';
      case 'bedroom':
      case 'bedroom-01':
        return '寝室';
      case 'kitchen':
      case 'kitchen-01':
        return 'キッチン';
      case 'entrance':
        return '玄関';
      default:
        return roomId;
    }
  }

  Future<void> _openEditAppearance(
    BuildContext context,
    Device device,
  ) async {
    final defaultPresentation = await resolveDefaultPresentation(device);
    if (!context.mounted) return;
    final service = Provider.of<DeviceService>(context, listen: false);
    final latest = service.getDeviceById(device.id) ?? device;
    final updated = await EditDeviceAppearanceSheet.show(
      context,
      device: latest,
      defaultPresentation: defaultPresentation,
    );
    if (updated == true && mounted) {
      await service.loadData();
      await _loadPresentations(service.devices);
    }
  }

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
              onPressed: () async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const AddApplianceScreen(),
                  ),
                );
                if (!mounted) return;
                final service =
                    Provider.of<DeviceService>(context, listen: false);
                await service.loadData();
                await _loadPresentations(service.devices);
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
            return const Center(child: CircularProgressIndicator());
          }

          if (deviceService.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    deviceService.errorMessage!,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final devices = deviceService.devices;
          if (_presentations.length != devices.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadPresentations(devices);
            });
          }

          if (devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.devices_other, size: 64, color: Colors.grey[400]),
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

          final devicesByRoom = <String, List<Device>>{};
          for (final device in devices) {
            final roomKey = device.room.isNotEmpty ? device.room : '未分類';
            devicesByRoom.putIfAbsent(roomKey, () => []).add(device);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: devicesByRoom.length,
            itemBuilder: (context, index) {
              final roomId = devicesByRoom.keys.elementAt(index);
              final roomDevices = devicesByRoom[roomId]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        EdgeInsets.only(top: index > 0 ? 24 : 0, bottom: 12),
                    child: Row(
                      children: [
                        Text(
                          _roomLabel(roomId),
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
                            color:
                                const Color(0xFF3b82f6).withValues(alpha: 0.1),
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
                  SizedBox(
                    height: ApplianceDetailCard.cardHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: roomDevices.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, deviceIndex) {
                        final device = roomDevices[deviceIndex];
                        final p = _presentations[device.id];
                        final title = p?.title ??
                            (device.category.isNotEmpty
                                ? device.category
                                : device.name);
                        return ApplianceDetailCard(
                          icon: p?.icon ?? '📦',
                          title: title,
                          subtitle: p?.subtitle,
                          showAlertDot: _deviceNeedsAttention(device),
                          onEdit: () => _openEditAppearance(context, device),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    DeviceDetailScreen(device: device),
                              ),
                            );
                            if (!mounted) return;
                            final service = Provider.of<DeviceService>(
                              context,
                              listen: false,
                            );
                            await _loadPresentations(service.devices);
                          },
                        );
                      },
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
