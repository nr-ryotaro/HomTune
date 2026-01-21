import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/device_service.dart';
import '../models/device.dart';
import '../widgets/device_card.dart';
import '../widgets/floor_plan_widget.dart';
import '../widgets/summary_card.dart';
import '../widgets/chat_widget.dart';
import 'room_devices_screen.dart';
import 'add_device_screen.dart';
import 'all_devices_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedRoomId;
  List<Device> _filteredDevices = [];

  @override
  void initState() {
    super.initState();
    // フレームが構築された後にデータを読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDevices();
    });
  }

  void _loadDevices() async {
    if (!mounted) return;
    
    try {
      final deviceService = Provider.of<DeviceService>(context, listen: false);
      await deviceService.loadData();
      
      if (mounted) {
        setState(() {
          _updateFilteredDevices();
        });
      }
    } catch (e) {
      print('Error loading devices in HomeScreen: $e');
      if (mounted) {
        // エラーが発生してもUIを更新してエラー状態を表示
        setState(() {});
      }
    }
  }

  void _updateFilteredDevices() {
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    if (_selectedRoomId != null) {
      _filteredDevices = deviceService.getDevicesByRoom(_selectedRoomId!);
    } else {
      _filteredDevices = deviceService.devices;
    }
  }

  void _onRoomTap(String roomId) {
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    final roomDevices = deviceService.getDevicesByRoom(roomId);
    
    if (roomDevices.isEmpty) {
      // デバイスがない場合はフィルタリングのみ
      setState(() {
        _selectedRoomId = roomId;
        _updateFilteredDevices();
      });
    } else {
      // デバイスがある場合は詳細画面に遷移
      final room = deviceService.rooms.firstWhere(
        (r) => r.id == roomId,
        orElse: () => deviceService.rooms.first,
      );
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RoomDevicesScreen(
            roomId: roomId,
            roomName: room.name,
            devices: roomDevices,
          ),
        ),
      );
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedRoomId = null;
      _updateFilteredDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HomTune',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Color(0xFF333333)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AllDevicesScreen(),
                ),
              );
            },
            tooltip: 'すべての家電を見る',
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
          // エラー状態
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      deviceService.loadData();
                    },
                    child: const Text('再試行'),
                  ),
                ],
              ),
            );
          }

          // ローディング状態
          if (deviceService.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // データが空の場合（エラーではない）
          if (deviceService.devices.isEmpty && deviceService.errorMessage == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.devices_other,
                    size: 64,
                    color: Color(0xFF999999),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'デバイスが登録されていません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 間取り図（最上部）
                _buildFloorPlan(context, deviceService),
                const SizedBox(height: 24),

                // チャットBOX
                _buildChatBox(context, deviceService),
                const SizedBox(height: 24),

                // サマリーカード（一行3列）
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: '警告',
                        count: _safeGetAlertCount(deviceService),
                        icon: Icons.warning_amber_rounded,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SummaryCard(
                        title: 'メンテナンス予定',
                        count: _safeGetMaintenanceCount(deviceService),
                        icon: Icons.access_time_rounded,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SummaryCard(
                        title: '登録デバイス',
                        count: deviceService.devices.length,
                        icon: Icons.devices_rounded,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // デバイス一覧
                _buildDeviceList(context, deviceService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context, DeviceService deviceService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedRoomId != null
                    ? 'デバイス一覧 - ${_getRoomName(_selectedRoomId!)}'
                    : 'デバイス一覧',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            Row(
              children: [
                if (_selectedRoomId != null)
                  TextButton(
                    onPressed: _clearFilter,
                    child: const Text(
                      'フィルタをクリア',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AllDevicesScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'すべて見る',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_filteredDevices.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFFE5E5E5),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Center(
              child: Text(
                'この部屋にはデバイスが登録されていません',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ),
          )
        else
          ..._filteredDevices.map(
            (device) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DeviceCard(device: device),
            ),
          ),
      ],
    );
  }

  Widget _buildFloorPlan(BuildContext context, DeviceService deviceService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '間取り図',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w300,
              ),
            ),
            OutlinedButton.icon(
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
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFFE5E5E5),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: FloorPlanWidget(
              floorPlan: deviceService.floorPlan,
              devices: deviceService.devices,
              selectedRoomId: _selectedRoomId,
              onRoomTap: _onRoomTap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatBox(BuildContext context, DeviceService deviceService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 400,
          child: ChatWidget(
            devices: deviceService.devices,
          ),
        ),
      ],
    );
  }

  String _getRoomName(String roomId) {
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    try {
      final room = deviceService.rooms.firstWhere(
        (r) => r.id == roomId,
      );
      return room.name;
    } catch (e) {
      return roomId;
    }
  }

  int _safeGetAlertCount(DeviceService deviceService) {
    try {
      return deviceService.getAlertCount();
    } catch (e) {
      print('Error getting alert count: $e');
      return 0;
    }
  }

  int _safeGetMaintenanceCount(DeviceService deviceService) {
    try {
      return deviceService.getMaintenanceCount();
    } catch (e) {
      print('Error getting maintenance count: $e');
      return 0;
    }
  }
}
