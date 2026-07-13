import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/device_service.dart';
import '../services/onboarding_prefs.dart';
import '../services/room_photo_service.dart';
import 'room_photo_setup_screen.dart';
import '../services/maintenance_calendar_service.dart';
import '../models/device.dart';
import '../services/appliance_template_service.dart';
import '../models/appliance_presentation.dart';
import '../widgets/appliance_icon_chip.dart';
import '../widgets/device_quick_preview_sheet.dart';
import '../widgets/chat_widget.dart';
import '../widgets/home/home_maintenance_banner.dart';
import '../widgets/registration/remote_setup_reminder_banner.dart';
import 'all_devices_screen.dart';
import 'add_appliance_screen.dart';
import '../utils/platform_support.dart';
import 'dev_settings_screen.dart';
import 'remote_control_preview_screen.dart';
import '../models/room_card_model.dart';
import '../widgets/room_card_widget.dart';
import 'maintenance_calendar_screen.dart';
import 'room_devices_screen.dart';
import '../widgets/ads/free_plan_ad_body.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedRoomId;
  late PageController _pageController;
  List<String> _homeRoomIds = OnboardingRoomCatalog.defaultHomeRoomIds;
  final Map<String, String> _roomImagePaths = {};
  bool _applianceSetupDone = false;
  bool _roomPhotosConfigured = false;
  bool _roomPhotoPromptShown = false;
  Map<String, AppliancePresentation> _presentationByDeviceId = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _loadOnboardingRoomPrefs();
    _loadRoomPhotoPhase();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDevices();
    });
  }

  Future<void> _loadDevicePresentations(List<Device> devices) async {
    final map = <String, AppliancePresentation>{};
    for (final device in devices) {
      map[device.id] =
          await ApplianceTemplateService.instance.resolvePresentation(device);
    }
    if (!mounted) return;
    setState(() => _presentationByDeviceId = map);
  }

  bool _deviceNeedsAttention(Device device) {
    if (device.safetyInfo?.isRecallActive == true) return true;
    final alerts = device.maintenance?.alerts ?? [];
    return alerts.any((a) => a.priority == 'high' || a.priority == 'medium');
  }

  Future<void> _loadRoomPhotoPhase() async {
    final applianceDone = await RoomPhotoService.isApplianceSetupDone();
    final photosDone = await RoomPhotoService.isRoomPhotosConfigured();
    if (!mounted) return;
    setState(() {
      _applianceSetupDone = applianceDone;
      _roomPhotosConfigured = photosDone;
    });
    await _reloadRoomImagePaths();
    if (applianceDone && !photosDone) {
      _maybePromptRoomPhotoSetup();
    }
  }

  Future<void> _reloadRoomImagePaths() async {
    final ids = _homeRoomIds
        .where((id) => OnboardingRoomCatalog.cardById.containsKey(id))
        .toList();
    final effective = ids.isNotEmpty
        ? ids
        : OnboardingRoomCatalog.defaultHomeRoomIds;
    for (final id in effective) {
      _roomImagePaths[id] = await RoomPhotoService.imagePathForRoom(id);
    }
    if (mounted) setState(() {});
  }

  Future<void> _openAddAppliance() async {
    final finished = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddApplianceScreen(initialRoomId: _selectedRoomId),
      ),
    );
    if (!mounted) return;
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    await deviceService.loadData();
    await _loadDevicePresentations(deviceService.devices);
    await _loadRoomPhotoPhase();
    if (finished == true && !_roomPhotosConfigured) {
      _maybePromptRoomPhotoSetup();
    }
  }

  void _maybePromptRoomPhotoSetup() {
    if (_roomPhotosConfigured || _roomPhotoPromptShown) return;
    _roomPhotoPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('部屋の写真を設定'),
          content: const Text(
            '家電の登録、おつかれさまでした。\n'
            '次は、お部屋の写真を登録してホーム画面を自分の住まいらしくしましょう。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('あとで'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('写真を設定する'),
            ),
          ],
        ),
      );
      if (go == true && mounted) {
        await _openRoomPhotoSetup();
      }
    });
  }

  Future<void> _openRoomPhotoSetup() async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const RoomPhotoSetupScreen(),
      ),
    );
    if (done == true && mounted) {
      await _loadRoomPhotoPhase();
    }
  }

  Future<void> _loadOnboardingRoomPrefs() async {
    final ids = await OnboardingPrefs.getSelectedRoomIds();
    if (!mounted) return;
    if (ids.isNotEmpty) {
      setState(() => _homeRoomIds = ids);
    }
    await _reloadRoomImagePaths();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _applyInitialRoomSelection(DeviceService deviceService) {
    final rooms = _getRooms(deviceService);
    if (rooms.isNotEmpty && _selectedRoomId == null) {
      _selectedRoomId = rooms[0].id;
    }
  }

  void _maybeShowPendingMessage(DeviceService deviceService) {
    final message = deviceService.consumePendingUserMessage();
    if (message == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    });
  }

  void _loadDevices() async {
    if (!mounted) return;

    try {
      final deviceService = Provider.of<DeviceService>(context, listen: false);

      if (deviceService.devices.isNotEmpty && !deviceService.isLoading) {
        if (mounted) {
          await _loadOnboardingRoomPrefs();
          await _loadDevicePresentations(deviceService.devices);
          setState(() => _applyInitialRoomSelection(deviceService));
          _maybeShowPendingMessage(deviceService);
        }
        return;
      }

      await deviceService.loadData();

      if (mounted) {
        await _loadOnboardingRoomPrefs();
        await _loadDevicePresentations(deviceService.devices);
        setState(() => _applyInitialRoomSelection(deviceService));
        _maybeShowPendingMessage(deviceService);
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
      required String imagePath,
    }) {
      final devices = deviceService.getDevicesByRoom(id);
      final deviceCount = devices.length;

      // Calculate dynamic asset value (base + device values)
      double totalAssetValue = 0;
      for (var d in devices) {
        if (d.assetValue != null) {
          totalAssetValue += d.assetValue!.currentUsedPrice;
        } else {
          totalAssetValue += d.purchasePrice;
        }
      }

      int alertCount = 0;
      int maintenanceCount = 0;
      int overdueCount = 0;
      int dueSoonCount = 0;
      int longerThanRecommendedCount = 0;

      // 今月の達成率計算用
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      int tasksExpectedThisMonth = 0;
      int tasksCompletedThisMonth = 0;

      for (var d in devices) {
        // Count maintenance alerts
        if (d.maintenance?.alerts.isNotEmpty == true) {
          alertCount += d.maintenance!.alerts
              .where((a) => a.priority == 'high' || a.priority == 'medium')
              .length;
        }

        // Count recall alerts
        if (d.safetyInfo?.isRecallActive == true) {
          alertCount++;
        }

        // Count maintenance (upcoming within 30 days)
        if (d.maintenance?.nextMaintenance != null) {
          try {
            final nextDate = DateTime.parse(d.maintenance!.nextMaintenance!);
            final diff = nextDate.difference(now).inDays;
            if (diff >= 0 && diff <= 30) {
              maintenanceCount++;
            }
          } catch (_) {}
        }

        // メンテナンスタスクの統計
        for (var task in d.maintenanceTasks) {
          if (task.isOverdue) overdueCount++;
          if (task.isDueSoon) dueSoonCount++;
          if (task.isIntervalLongerThanRecommended) {
            longerThanRecommendedCount++;
          }

          // 今月の期限タスクカウント
          if (task.nextDue != null &&
              task.nextDue!.isAfter(monthStart) &&
              task.nextDue!.isBefore(now.add(const Duration(days: 1)))) {
            tasksExpectedThisMonth++;
            // 完了済みならカウント
            if (task.lastCompleted != null &&
                task.lastCompleted!.isAfter(monthStart)) {
              tasksCompletedThisMonth++;
            }
          }
          // 今月完了したタスクもカウント（nextDue が来月でも今月完了したなら）
          if (task.lastCompleted != null &&
              task.lastCompleted!.isAfter(monthStart)) {
            if (tasksExpectedThisMonth == 0) {
              tasksExpectedThisMonth = 1;
            }
            tasksCompletedThisMonth =
                tasksCompletedThisMonth.clamp(0, tasksExpectedThisMonth);
          }
        }
      }

      // ── メンテナンス健康度（動的計算） ──
      double health = 1.0;
      health -= overdueCount * 0.15;
      health -= dueSoonCount * 0.05;
      health -= longerThanRecommendedCount * 0.05;
      health = health.clamp(0.0, 1.0);

      // ── 達成率 ──
      final achievementRate = tasksExpectedThisMonth > 0
          ? (tasksCompletedThisMonth / tasksExpectedThisMonth).clamp(0.0, 1.0)
          : 1.0; // タスクなし = 100%

      // ── ストリーク（連続完了週数） ──
      int streakWeeks = 0;
      // 過去の完了履歴から連続週を計算
      final allHistory = <DateTime>[];
      for (var d in devices) {
        for (var task in d.maintenanceTasks) {
          allHistory.addAll(task.history);
        }
      }
      if (allHistory.isNotEmpty) {
        // 週単位でチェック（直近から遡る）
        for (int w = 0; w < 52; w++) {
          final weekStart =
              now.subtract(Duration(days: now.weekday - 1 + (w * 7)));
          final weekEnd = weekStart.add(const Duration(days: 7));
          final hasCompletion = allHistory
              .any((h) => h.isAfter(weekStart) && h.isBefore(weekEnd));
          if (hasCompletion) {
            streakWeeks++;
          } else {
            break;
          }
        }
      }

      return RoomCardModel(
        id: id,
        title: title,
        imagePath: imagePath,
        totalAssetValue: totalAssetValue,
        maintenanceHealth: health,
        deviceCount: deviceCount,
        alertCount: alertCount,
        maintenanceCount: maintenanceCount,
        achievementRate: achievementRate,
        streakWeeks: streakWeeks,
      );
    }

    final roomIds = _homeRoomIds
        .where((id) => OnboardingRoomCatalog.cardById.containsKey(id))
        .toList();
    final effectiveIds = roomIds.isNotEmpty
        ? roomIds
        : OnboardingRoomCatalog.defaultHomeRoomIds;

    return [
      for (final id in effectiveIds)
        createRoomCard(
          id: id,
          title: OnboardingRoomCatalog.cardById[id]!.title,
          imagePath: _roomImagePaths[id] ??
              OnboardingRoomCatalog.cardById[id]!.imagePath,
        ),
    ];
  }

  List<Device> _devicesForDisplay(DeviceService deviceService) {
    if (_selectedRoomId != null) {
      return deviceService.getDevicesByRoom(_selectedRoomId!);
    }
    return deviceService.devices;
  }

  void _onPageChanged(int index) {
    // Need deviceService to get rooms stats
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    setState(() {
      final rooms = _getRooms(deviceService);
      if (index < rooms.length) {
        _selectedRoomId = rooms[index].id;
      }
    });
  }

  void _clearFilter() {
    setState(() {
      _selectedRoomId = null;
    });
  }

  void _openRoomDetail(String roomId, String roomTitle) {
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    final roomDevices = deviceService.getDevicesByRoom(roomId);

    if (roomDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('この部屋にはまだ家電が登録されていません'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RoomDevicesScreen(
          roomId: roomId,
          roomName: roomTitle,
          devices: roomDevices,
        ),
      ),
    );
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
          if (PlatformSupport.isWebUiPreview)
            IconButton(
              icon: const Icon(Icons.settings_remote, color: Color(0xFF333333)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RemoteControlPreviewScreen(),
                  ),
                );
              },
              tooltip: 'リモコン UI',
            ),
          if (kDebugMode && !PlatformSupport.isWebUiPreview)
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
          Widget content;
          if (deviceService.errorMessage != null) {
            content = _buildErrorState(deviceService);
          } else if (deviceService.isLoading) {
            content = const Center(child: CircularProgressIndicator());
          } else {
            final displayedDevices = _devicesForDisplay(deviceService);
            content = SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRoomCardsCarousel(context, deviceService),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        _buildMaintenanceBanner(deviceService),
                        if (PlatformSupport.isWebUiPreview)
                          _buildRemotePreviewBanner(context),
                        RemoteSetupReminderBanner(
                          allDevices: deviceService.devices,
                          placement: 'home',
                        ),
                        if (_applianceSetupDone && !_roomPhotosConfigured) ...[
                          _buildRoomPhotoPromptBanner(context),
                          const SizedBox(height: 16),
                        ],
                        _buildChatBox(context, deviceService),
                        const SizedBox(height: 24),
                        _buildDeviceList(
                          context,
                          deviceService,
                          displayedDevices,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return FreePlanAdBody(placement: 'home', child: content);
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

  Widget _buildRemotePreviewBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RemoteControlPreviewScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.settings_remote, color: Color(0xFF15803D)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'リモコン UI をプレビュー',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF166534),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'エアコン・テレビのメーカー別ボタン配置を確認できます',
                        style: TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomPhotoPromptBanner(BuildContext context) {
    return Material(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _openRoomPhotoSetup,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.photo_camera_outlined, color: Color(0xFF1D4ED8)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '部屋の写真を設定しましょう',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'いまはサンプル画像です。撮影やアルバムから選べます。',
                      style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.blue[300]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList(
    BuildContext context,
    DeviceService deviceService,
    List<Device> displayedDevices,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedRoomId != null
                    ? '登録した家電 · ${_getRoomName(_selectedRoomId!)}'
                    : '登録した家電',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            Row(
              children: [
                if (_selectedRoomId != null)
                  TextButton(
                    onPressed: _clearFilter,
                    child:
                        const Text('すべて', style: TextStyle(fontSize: 12)),
                  ),
                if (displayedDevices.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AllDevicesScreen(),
                        ),
                      );
                    },
                    child: const Text('詳細一覧', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'アイコンをタップすると名前と詳細が表示されます',
          style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
        ),
        const SizedBox(height: 10),
        if (displayedDevices.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E5E5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'この部屋にはまだ家電が登録されていません',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
          )
        else
          SizedBox(
            height: ApplianceIconChip.size,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displayedDevices.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final device = displayedDevices[index];
                final presentation = _presentationByDeviceId[device.id] ??
                    AppliancePresentation(
                      icon: '📦',
                      title: device.category.isNotEmpty
                          ? device.category
                          : device.name,
                    );
                return ApplianceIconChip(
                  icon: presentation.icon,
                  showAlertDot: _deviceNeedsAttention(device),
                  onTap: () async {
                    await DeviceQuickPreviewSheet.show(
                      context,
                      device: device,
                      presentation: presentation,
                    );
                    if (!mounted) return;
                    await _loadDevicePresentations(deviceService.devices);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRoomCardsCarousel(
      BuildContext context, DeviceService deviceService) {
    final rooms = _getRooms(deviceService);
    final showPhotoSetupCard =
        _applianceSetupDone && !_roomPhotosConfigured;
    final itemCount = rooms.length + (showPhotoSetupCard ? 1 : 0);

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
                onPressed: _openAddAppliance,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('家電を追加'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF3b82f6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Carousel
        SizedBox(
          height: 395,
          child: PageView.builder(
            controller: _pageController,
            itemCount: itemCount,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8.0), // Padding between cards
                child: index < rooms.length
                    ? SizedBox(
                        height: 395,
                        child: RoomCardWidget(
                        room: rooms[index],
                        onDetailTap: () => _openRoomDetail(
                          rooms[index].id,
                          rooms[index].title,
                        ),
                        onCustomizePhoto: _applianceSetupDone &&
                                !_roomPhotosConfigured
                            ? _openRoomPhotoSetup
                            : null,
                      ),
                      )
                    : _buildRoomPhotoSetupCard(context),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRoomPhotoSetupCard(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 0.5),
      ),
      child: InkWell(
        onTap: _openRoomPhotoSetup,
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
              child: const Icon(Icons.photo_camera_outlined,
                  size: 32, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 24),
            const Text(
              '部屋の写真を\n設定する',
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
              '撮影やアルバムから\nお部屋の写真を登録',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// メンテナンスバナー（選択中の部屋のタスクのみ表示）
  Widget _buildMaintenanceBanner(DeviceService deviceService) {
    final devices = _selectedRoomId != null
        ? deviceService.getDevicesByRoom(_selectedRoomId!)
        : deviceService.devices;
    return HomeMaintenanceBanner(devices: devices);
  }

  Widget _buildChatBox(BuildContext context, DeviceService deviceService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: ChatWidget(devices: deviceService.devices),
        ),
      ],
    );
  }

  String _getRoomName(String roomId) {
    if (roomId == 'living-room' || roomId == 'living') {
      return 'Living Room';
    }
    if (roomId == 'bedroom-01' || roomId == 'bedroom') {
      return 'Bedroom';
    }
    if (roomId == 'kitchen-01' || roomId == 'kitchen') {
      return 'Kitchen';
    }
    if (roomId == 'entrance') {
      return 'Entrance';
    }
    if (roomId == 'study') {
      return 'Study';
    }

    final deviceService = Provider.of<DeviceService>(context, listen: false);
    try {
      final room = deviceService.rooms.firstWhere((r) => r.id == roomId);
      return room.name;
    } catch (e) {
      return roomId;
    }
  }
}
