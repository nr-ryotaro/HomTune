import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/device_service.dart';
import '../models/device.dart';
import '../widgets/device_card.dart';

import '../widgets/chat_widget.dart';
import 'all_devices_screen.dart';
import 'scan_screen.dart';
import 'dev_settings_screen.dart';
import '../models/room_card_model.dart';
import '../widgets/room_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedRoomId;
  List<Device> _filteredDevices = [];
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    // フレームが構築された後にデータを読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDevices();
      _testFinancialInsight(); // テスト実行
    });
  }

  // 金融インサイトのテスト
  void _testFinancialInsight() async {
    // 少し待機してデータロードを待つ
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final deviceService = Provider.of<DeviceService>(context, listen: false);

    // 対象デバイスのID
    final targetIds = ['espresso_001', 'light_bed_001'];

    print('--- [Insight Test] Start ---');
    for (var id in targetIds) {
      final device = deviceService.getDeviceById(id);
      if (device != null && device.assetValue?.valuationInsight != null) {
        print(
            '[Insight Test] ${device.name}: ${device.assetValue!.valuationInsight}');
      } else {
        print('[Insight Test] ${device?.name ?? id}: No insight available');
      }
    }
    print('--- [Insight Test] End ---');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadDevices() async {
    if (!mounted) return;

    try {
      final deviceService = Provider.of<DeviceService>(context, listen: false);
      await deviceService.loadData();

      if (mounted) {
        setState(() {
          // 初期表示時は最初の部屋を選択状態にする
          // Note: deviceService is available in the outer scope of _loadDevices via Provider lookup? No, we looked it up at line 47.
          // Re-using the deviceService instance from line 47 is tricky because we are in setState callback (anonymous function).
          // But line 47 variable 'deviceService' is available in the closure? Yes.
          final rooms = _getRooms(deviceService);
          if (rooms.isNotEmpty) {
            _selectedRoomId = rooms[0].id;
          }
          _updateFilteredDevices();
        });
      }
    } catch (e) {
      print('Error loading devices in HomeScreen: $e');
      if (mounted) {
        setState(() {});
      }
    }
  }

  List<RoomCardModel> _getRooms(DeviceService deviceService) {
    // Helper to calculate room stats
    RoomCardModel createRoomCard({
      required String id,
      required String title,
      required String styleName,
      required String imagePath,
      required double maintenanceHealth,
    }) {
      final devices = deviceService.getDevicesByRoom(id);
      final deviceCount = devices.length;

      // Calculate dynamic asset value (base + device values)
      double totalAssetValue = 0;
      for (var d in devices) {
        // 資産価値（現在価値）を使用。未計算の場合は購入価格をフォールバックとして使用
        if (d.assetValue != null) {
          totalAssetValue += d.assetValue!.currentUsedPrice;
        } else {
          totalAssetValue += d.purchasePrice;
        }
      }

      int alertCount = 0;
      int maintenanceCount = 0;

      for (var d in devices) {
        // Count alerts
        if (d.maintenance?.alerts.isNotEmpty == true) {
          // Simplified logic: count all high/medium alerts
          alertCount += d.maintenance!.alerts
              .where((a) => a.priority == 'high' || a.priority == 'medium')
              .length;
        }

        // Count maintenance (upcoming within 30 days)
        if (d.maintenance?.nextMaintenance != null) {
          try {
            final nextDate = DateTime.parse(d.maintenance!.nextMaintenance!);
            final today = DateTime.now();
            final diff = nextDate.difference(today).inDays;
            if (diff >= 0 && diff <= 30) {
              maintenanceCount++;
            }
          } catch (_) {}
        }
      }

      return RoomCardModel(
        id: id,
        title: title,
        styleName: styleName,
        imagePath: imagePath,
        totalAssetValue: totalAssetValue,
        maintenanceHealth: maintenanceHealth,
        deviceCount: deviceCount,
        alertCount: alertCount,
        maintenanceCount: maintenanceCount,
      );
    }

    return [
      createRoomCard(
        id: 'living-room', // ID修正: living -> living-room (DeviceServiceのダミーデータと一致させる)
        title: 'Living Room',
        styleName: 'Tech Japandi',
        imagePath: 'assets/images/Living_sample.jpg',
        maintenanceHealth: 0.9,
      ),
      createRoomCard(
        id: 'bedroom-01', // ID修正: bedroom -> bedroom-01
        title: 'Bedroom',
        styleName: 'Hotel-like Japandi',
        imagePath: 'assets/images/Bedroom_sample.jpg',
        maintenanceHealth: 0.75,
      ),
      createRoomCard(
        id: 'kitchen-01', // ID修正: kitchen -> kitchen-01
        title: 'Kitchen',
        styleName: 'Japandi Kitchen',
        imagePath: 'assets/images/Kitchen_sample.jpg',
        maintenanceHealth: 0.95,
      ),
    ];
  }

  void _updateFilteredDevices() {
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    if (_selectedRoomId != null) {
      _filteredDevices = deviceService.getDevicesByRoom(_selectedRoomId!);
    } else {
      _filteredDevices = deviceService.devices;
    }
  }

  void _onPageChanged(int index) {
    // Need deviceService to get rooms stats
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    setState(() {
      final rooms = _getRooms(deviceService);
      if (index < rooms.length) {
        _selectedRoomId = rooms[index].id;
      } else {
        // AI Generator card selected
        _selectedRoomId = null;
      }
      _updateFilteredDevices();
    });
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
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.settings, color: Color(0xFF333333)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DevSettingsScreen(),
                  ),
                );
              },
              tooltip: '開発者設定',
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
          if (deviceService.errorMessage != null) {
            return _buildErrorState(deviceService);
          }
          if (deviceService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (deviceService.devices.isEmpty &&
              deviceService.errorMessage == null) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 間取り図 (Room Card Carousel)
                _buildRoomCardsCarousel(context, deviceService),
                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // チャットBOX (Reduced height)
                      _buildChatBox(context, deviceService),
                      const SizedBox(height: 24),

                      // デバイス一覧
                      _buildDeviceList(context, deviceService),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(DeviceService deviceService) {
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

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices_other, size: 64, color: Color(0xFF999999)),
          SizedBox(height: 16),
          Text(
            'デバイスが登録されていません',
            style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
          ),
        ],
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
                    child:
                        const Text('フィルタをクリア', style: TextStyle(fontSize: 12)),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('すべて見る', style: TextStyle(fontSize: 12)),
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
              border: Border.all(color: const Color(0xFFE5E5E5), width: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Center(
              child: Text(
                'この部屋にはデバイスが登録されていません',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
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

  Widget _buildRoomCardsCarousel(
      BuildContext context, DeviceService deviceService) {
    final rooms = _getRooms(deviceService);
    final itemCount = rooms.length + 1; // +1 for AI Generator

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Rooms',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
              ),
              // Updated Button Name and Icon
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ScanScreen()),
                  );
                },
                icon: const Icon(Icons.qr_code_2, size: 20), // Barcode icon
                label: const Text('家電を追加'), // Clearer label
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF3b82f6)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Carousel
        SizedBox(
          height:
              380, // Restored to smaller height due to overflow fix + PageView behavior
          child: PageView.builder(
            controller: _pageController,
            itemCount: itemCount,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8.0), // Padding between cards
                child: index < rooms.length
                    ? RoomCardWidget(
                        room: rooms[index],
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                      )
                    : _buildAiGeneratorCard(context),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAiGeneratorCard(BuildContext context) {
    return Container(
      width: 280,
      // Removed margin here because PageView handles spacing via padding in itemBuilder
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 0.5),
      ),
      child: InkWell(
        onTap: () => _simulateAiGeneration(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome,
                  size: 32, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Generate My Room\nwith AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF333333),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Transform your photo\ninto Japandi Style',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simulateAiGeneration(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Analyzing your room structure...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    decoration: TextDecoration.none)),
          ],
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 3));
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('✨ Room generated! (Demo functionality)'),
          behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildChatBox(BuildContext context, DeviceService deviceService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200, // Reduced height to fix "useless whitespace"
          child: ChatWidget(devices: deviceService.devices),
        ),
      ],
    );
  }

  String _getRoomName(String roomId) {
    if (roomId == 'living') return 'Living Room';
    if (roomId == 'bedroom') return 'Bedroom';
    if (roomId == 'kitchen') return 'Kitchen';

    final deviceService = Provider.of<DeviceService>(context, listen: false);
    try {
      final room = deviceService.rooms.firstWhere((r) => r.id == roomId);
      return room.name;
    } catch (e) {
      return roomId;
    }
  }
}
