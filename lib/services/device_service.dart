import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../data/repositories/device_repository.dart';
import '../models/device.dart';
import '../models/manufacturer_bundle.dart';
import '../models/maintenance_task.dart';
import '../models/room.dart';
import '../models/room.dart' as room_models;
import '../models/asset_refresh_result.dart';
import '../models/market_refresh_mode.dart';
import 'asset_valuation_refresh_service.dart';
import 'config_service.dart';
import 'maintenance_calendar_service.dart';
import 'notification_service.dart';
import 'manual_link_resolver.dart';
import 'manual_search_service.dart';
import 'appliance_template_service.dart';
import 'onboarding_prefs.dart';

class DeviceService extends ChangeNotifier {
  DeviceService({
    DeviceRepository? repository,
    NotificationService? notificationService,
    ManualLinkResolver? manualLinkResolver,
    ApplianceTemplateService? applianceTemplateService,
  })  : _repository = repository ?? DeviceRepository(),
        _notificationService = notificationService ?? NotificationService(),
        _manualLinkResolver = manualLinkResolver ?? ManualLinkResolver.instance,
        _applianceTemplateService =
            applianceTemplateService ?? ApplianceTemplateService.instance;

  final DeviceRepository _repository;
  final NotificationService _notificationService;
  final ManualLinkResolver _manualLinkResolver;
  final ApplianceTemplateService _applianceTemplateService;
  final AssetValuationRefreshService _assetRefresh =
      AssetValuationRefreshService();

  List<Device> _devices = [];
  FloorPlan? _floorPlan;
  List<Room> _rooms = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _pendingUserMessage;

  List<Device> get devices => _devices;
  FloorPlan? get floorPlan => _floorPlan;
  List<Room> get rooms => _rooms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// One-shot message for UI (e.g. manual archive complete after navigation).
  String? consumePendingUserMessage() {
    final msg = _pendingUserMessage;
    _pendingUserMessage = null;
    return msg;
  }

  /// 複数デバイスを一括追加（バンドル登録用）
  Future<List<Device>> addDevices(
    List<BundleRegistrationItem> items,
  ) async {
    final added = <Device>[];
    for (final item in items) {
      await addDevice(item.device, archetypeId: item.archetypeId);
      final stored = _devices.lastWhere(
        (d) => d.id == item.device.id,
        orElse: () => item.device,
      );
      added.add(stored);
    }
    return added;
  }

  /// デバイスを追加（[archetypeId] 指定時は部屋別テンプレのケア項目をマージ）
  Future<void> addDevice(Device device, {String? archetypeId}) async {
    try {
      // 資産価値を計算 (Double Timeline Logic)
      final calculatedAssetValue = await _assetRefresh.refresh(device);

      // 資産価値を更新したデバイスを作成
      final deviceWithAssetValue = Device(
        id: device.id,
        name: device.name,
        modelNumber: device.modelNumber,
        category: device.category,
        manufacturer: device.manufacturer,
        purchaseDate: device.purchaseDate,
        purchasePrice: device.purchasePrice,
        yearsOwned: device.yearsOwned,
        room: device.room,
        location: device.location,
        status: device.status,
        maintenance: device.maintenance,
        manual: device.manual,
        janCode: device.janCode,
        consumables: device.consumables,
        warranty: device.warranty,
        assetValue: calculatedAssetValue,
        safetyInfo: device.safetyInfo,
        photos: device.photos,
        documents: device.documents,
        archetypeId: archetypeId ?? device.archetypeId,
      );

      var deviceToStore = deviceWithAssetValue;
      if (deviceToStore.maintenanceTasks.isEmpty) {
        final categoryTasks =
            await MaintenanceCalendarService.initializeTasksForDevice(
                deviceToStore);
        final archetypeTasks = archetypeId != null
            ? await _applianceTemplateService
                .buildTasksForArchetype(archetypeId, deviceToStore.id)
            : <MaintenanceTask>[];
        final merged = _mergeMaintenanceTasks(categoryTasks, archetypeTasks);
        if (merged.isNotEmpty) {
          deviceToStore = deviceToStore.copyWith(maintenanceTasks: merged);
        }
      }

      final shouldResolveManual = deviceToStore.manufacturer.trim().isNotEmpty ||
          deviceToStore.modelNumber.trim().isNotEmpty;
      if (shouldResolveManual && deviceToStore.manual == null) {
        deviceToStore = deviceToStore.copyWith(
          manualState: ManualFetchState.fetching,
        );
      }

      _devices.add(deviceToStore);
      await _persistUserDevices();
      await MaintenanceCalendarService.saveTasks(_devices);
      _notificationService.scheduleAllMaintenanceNotifications(_devices);
      notifyListeners();

      if (shouldResolveManual) {
        _manualLinkResolver.resolveForDevice(this, deviceToStore);
      }
    } catch (e) {
      print('Error adding device: $e');
      rethrow;
    }
  }

  List<MaintenanceTask> _mergeMaintenanceTasks(
    List<MaintenanceTask> categoryTasks,
    List<MaintenanceTask> archetypeTasks,
  ) {
    final byId = <String, MaintenanceTask>{};
    for (final t in categoryTasks) {
      byId[t.taskId] = t;
    }
    for (final t in archetypeTasks) {
      byId.putIfAbsent(t.taskId, () => t);
    }
    return byId.values.toList();
  }

  Future<void> loadData() async {
    if (_isLoading) {
      var waitedMs = 0;
      const maxWaitMs = 30000;
      while (_isLoading && waitedMs < maxWaitMs) {
        await Future.delayed(const Duration(milliseconds: 50));
        waitedMs += 50;
      }
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 少し待機してUIが準備できるようにする
      await Future.delayed(const Duration(milliseconds: 100));

      // ユーザー追加デバイスを保持（シードデータ再注入時も消さない）
      final persistedUser = await _repository.loadPersistedUserDevices();
      final inMemoryUser = _devices
          .where((d) => !_repository.isSeedDevice(d.id))
          .toList();
      _devices = _repository.mergeUserDevices(
        persisted: persistedUser,
        inMemory: inMemoryUser,
      );

      // floor-plan.jsonから読み込み（floorPlanがnullの場合）
      if (_floorPlan == null) {
        try {
          final String floorPlanString =
              await rootBundle.loadString('assets/data/floor-plan.json');
          final Map<String, dynamic> floorPlanData =
              json.decode(floorPlanString);
          _floorPlan = FloorPlan.fromJson(floorPlanData);
        } catch (e) {
          print('Error loading floor-plan.json: $e');
          // フォールバック: 部屋データから間取り図を生成
          // (この時点では部屋がないので後で生成される)
        }
      }

      if (await OnboardingPrefs.includeDemoSeedDevices()) {
        _devices = await _repository.applySeedDevices(_devices, _rooms);
      }

      // (ダミーデータ注入後に実行することで、注入された部屋が反映される)
      if (_rooms.isNotEmpty &&
          (_floorPlan == null || _floorPlan!.rooms.isEmpty)) {
        _floorPlan = _generateFloorPlanFromRooms();
      }

      // メンテナンスタスク: 永続化データを優先、なければカテゴリデフォルトから割当
      for (int i = 0; i < _devices.length; i++) {
        final device = _devices[i];
        try {
          final persisted =
              await MaintenanceCalendarService.loadTasksForDevice(device.id);
          if (persisted.isNotEmpty) {
            _devices[i] = device.copyWith(maintenanceTasks: persisted);
            continue;
          }
          if (device.maintenanceTasks.isEmpty) {
            final tasks =
                await MaintenanceCalendarService.initializeTasksForDevice(
                    device);
            if (tasks.isNotEmpty) {
              _devices[i] = device.copyWith(maintenanceTasks: tasks);
            }
          }
        } catch (e) {
          print(
              'Error initializing maintenance tasks for ${device.name}: $e');
        }
      }

      await MaintenanceCalendarService.saveTasks(_devices);

      await _refreshAllDeviceAssetValues();

      // メンテナンス通知のスケジュール
      _notificationService.scheduleAllMaintenanceNotifications(_devices);
    } catch (e, stackTrace) {
      _errorMessage = 'データの読み込みに失敗しました: $e';
      print('Error loading data: $e');
      print('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persistUserDevices() async {
    await _repository.persistUserDevices(_devices);
  }

  /// 全デバイスの帳簿・市場・表示価値をローカル再計算（API コスト 0）
  Future<void> _refreshAllDeviceAssetValues() async {
    var changed = false;
    for (var i = 0; i < _devices.length; i++) {
      final device = _devices[i];
      try {
        final updated = await _assetRefresh.refresh(device);
        if (_assetValueChanged(device.assetValue, updated)) {
          _devices[i] = device.copyWith(assetValue: updated);
          changed = true;
        }
      } catch (e) {
        print('Asset refresh failed for ${device.id}: $e');
      }
    }
    if (changed) {
      await _persistUserDevices();
    }
  }

  bool _assetValueChanged(AssetValue? prev, AssetValue next) {
    if (prev == null) return true;
    return prev.bookValue != next.bookValue ||
        prev.marketValue != next.marketValue ||
        prev.currentUsedPrice != next.currentUsedPrice ||
        prev.lastPriceCheck != next.lastPriceCheck;
  }

  /// 1台の資産価値を再計算して永続化（L0〜L2）
  Future<AssetRefreshResult?> refreshDeviceAssetValue(
    String deviceId, {
    required ConfigService config,
    MarketRefreshMode mode = MarketRefreshMode.local,
  }) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index < 0) return null;
    final result = await _assetRefresh.refreshWithMode(
      _devices[index],
      config: config,
      mode: mode,
    );
    _devices[index] =
        _devices[index].copyWith(assetValue: result.assetValue);
    if (!_repository.isSeedDevice(deviceId)) {
      await _persistUserDevices();
    }
    notifyListeners();
    return result;
  }

  FloorPlan _generateFloorPlanFromRooms() {
    try {
      // 部屋データから簡易的な間取り図を生成
      final rooms = _rooms
          .map((room) {
            try {
              return room_models.FloorPlanRoom(
                id: room.id,
                name: room.name,
                type: room.type,
                coordinates: room.coordinates,
                color: '#FAFAFA',
                borderColor: '#E0E0E0',
                devices: [],
              );
            } catch (e) {
              print('Error creating FloorPlanRoom for ${room.id}: $e');
              return null;
            }
          })
          .whereType<room_models.FloorPlanRoom>()
          .toList();

      if (rooms.isEmpty) {
        // 部屋がない場合はデフォルトの間取り図を返す
        return FloorPlan(
          id: 'default-floor-plan',
          name: 'デフォルト間取り図',
          scale: 1.0,
          width: 800,
          height: 700,
          rooms: [],
        );
      }

      return FloorPlan(
        id: 'generated-floor-plan',
        name: '生成された間取り図',
        scale: 1.0,
        width: 800,
        height: 700,
        rooms: rooms,
      );
    } catch (e) {
      print('Error generating floor plan from rooms: $e');
      // エラー時は空の間取り図を返す
      return FloorPlan(
        id: 'error-floor-plan',
        name: 'エラー間取り図',
        scale: 1.0,
        width: 800,
        height: 700,
        rooms: [],
      );
    }
  }

  List<Device> getDevicesByRoom(String roomId) {
    return _devices.where((device) => device.room == roomId).toList();
  }

  int getDeviceCountForRoom(String roomId) {
    return _devices.where((device) => device.room == roomId).length;
  }

  Device? getDeviceById(String deviceId) {
    try {
      return _devices.firstWhere((device) => device.id == deviceId);
    } catch (e) {
      return null;
    }
  }

  int getAlertCount() {
    int count = 0;
    for (var device in _devices) {
      if (device.maintenance?.alerts != null) {
        count += device.maintenance!.alerts
            .where((alert) =>
                alert.priority == 'high' || alert.priority == 'medium')
            .length;
      }
    }
    return count;
  }

  /// 一覧表示用の名前・絵文字を更新（空文字でカスタムを解除）
  Future<void> updateDeviceAppearance(
    String deviceId, {
    String? displayName,
    String? icon,
    bool resetToDefault = false,
  }) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index < 0) return;
    final current = _devices[index];
    if (resetToDefault) {
      _devices[index] = current.copyWith(
        customDisplayName: '',
        customIcon: '',
      );
    } else {
      _devices[index] = current.copyWith(
        customDisplayName: displayName ?? current.customDisplayName,
        customIcon: icon ?? current.customIcon,
      );
    }
    await MaintenanceCalendarService.saveTasks(_devices);
    if (!_repository.isSeedDevice(deviceId)) {
      await _persistUserDevices();
    }
    notifyListeners();
  }

  Future<void> updateDevice(Device updatedDevice) async {
    final index = _devices.indexWhere((d) => d.id == updatedDevice.id);
    if (index >= 0) {
      _devices[index] = updatedDevice;
      await MaintenanceCalendarService.saveTasks(_devices);
      if (!_repository.isSeedDevice(updatedDevice.id)) {
        await _persistUserDevices();
      }
      _notificationService.scheduleAllMaintenanceNotifications(_devices);
      notifyListeners();
    }
  }

  /// メンテタスク完了後の永続化・通知更新
  Future<void> onMaintenanceTasksUpdated(String deviceId) async {
    final device = getDeviceById(deviceId);
    if (device == null) return;
    await MaintenanceCalendarService.saveTasks(_devices);
    if (!_repository.isSeedDevice(deviceId)) {
      await _persistUserDevices();
    }
    _notificationService.scheduleAllMaintenanceNotifications(_devices);
    notifyListeners();
  }

  /// マニュアル取得状態のみ更新
  Future<void> updateDeviceManualState(
    String deviceId,
    ManualFetchState state,
  ) async {
    final i = _devices.indexWhere((d) => d.id == deviceId);
    if (i < 0) return;
    _devices[i] = _devices[i].copyWith(manualState: state);
    if (!_repository.isSeedDevice(deviceId)) {
      await _persistUserDevices();
    }
    notifyListeners();
  }

  /// デバイスの説明書URLを更新（公式リンク解決完了時）
  Future<void> updateDeviceManual(String deviceId, Manual manual) async {
    final i = _devices.indexWhere((d) => d.id == deviceId);
    if (i < 0) return;
    final prev = _devices[i];
    _devices[i] = prev.copyWith(
      manual: manual,
      manualPdfUrl: manual.url,
      manualState: ManualFetchState.found,
    );
    if (!_repository.isSeedDevice(deviceId)) {
      await _persistUserDevices();
    }
    _pendingUserMessage = ManualSearchService.archiveCompleteMessage;
    notifyListeners();
  }

  int getMaintenanceCount() {
    int count = 0;
    final today = DateTime.now();
    for (var device in _devices) {
      if (device.maintenance?.nextMaintenance != null) {
        try {
          final nextDate = DateTime.parse(device.maintenance!.nextMaintenance!);
          final daysUntil = nextDate.difference(today).inDays;
          if (daysUntil >= 0 && daysUntil <= 30) {
            count++;
          }
        } catch (e) {
          // 日付パースエラーは無視
        }
      }
    }
    return count;
  }
}
