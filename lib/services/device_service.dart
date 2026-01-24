import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/device.dart';
import '../models/room.dart';
import '../models/room.dart' as room_models;
import 'valuation_service.dart';

class DeviceService extends ChangeNotifier {
  List<Device> _devices = [];
  FloorPlan? _floorPlan;
  List<Room> _rooms = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Device> get devices => _devices;
  FloorPlan? get floorPlan => _floorPlan;
  List<Room> get rooms => _rooms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// デバイスを追加（モック実装）
  Future<void> addDevice(Device device) async {
    try {
      // 資産価値を計算
      final valuationService = ValuationService();
      final calculatedAssetValue = await valuationService.calculateAssetValue(device);
      
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
      );
      
      // モック実装: 実際の実装では、ローカルストレージまたはAPIに保存
      _devices.add(deviceWithAssetValue);
      notifyListeners();
      
      // 実際の実装では、以下を実行:
      // 1. SharedPreferencesまたはローカルDBに保存
      // 2. またはAPIにPOSTリクエスト
      // 3. 成功後にリストを更新
    } catch (e) {
      print('Error adding device: $e');
      rethrow;
    }
  }

  Future<void> loadData() async {
    if (_isLoading) return; // 既に読み込み中の場合は何もしない
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 少し待機してUIが準備できるようにする
      await Future.delayed(const Duration(milliseconds: 100));
      
      // モックデータを読み込み
      String mockDataString;
      try {
        mockDataString = await rootBundle.loadString('assets/data/mock-data.json');
      } catch (e) {
        throw Exception('アセットファイルの読み込みに失敗しました: $e');
      }
      
      Map<String, dynamic> mockData;
      try {
        mockData = json.decode(mockDataString) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('JSONの解析に失敗しました: $e');
      }

      // デバイスを読み込み
      if (mockData['devices'] != null && mockData['devices'] is List) {
        _devices = (mockData['devices'] as List<dynamic>)
            .map((e) {
              try {
                return Device.fromJson(e as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing device: $e');
                return null;
              }
            })
            .whereType<Device>()
            .toList();
      } else {
        _devices = [];
      }

      // 部屋を読み込み
      if (mockData['rooms'] != null && mockData['rooms'] is List) {
        _rooms = (mockData['rooms'] as List<dynamic>)
            .map((e) {
              try {
                return Room.fromJson(e as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing room: $e');
                return null;
              }
            })
            .whereType<Room>()
            .toList();
      } else {
        _rooms = [];
      }

      // 間取り図を読み込み
      if (mockData['floorPlan'] != null) {
        try {
          _floorPlan = FloorPlan.fromJson(mockData['floorPlan']);
        } catch (e) {
          print('Error parsing floorPlan from mock-data: $e');
          _floorPlan = null;
        }
      }
      
      // floor-plan.jsonから読み込み（floorPlanがnullの場合）
      if (_floorPlan == null) {
        try {
          final String floorPlanString =
              await rootBundle.loadString('assets/data/floor-plan.json');
          final Map<String, dynamic> floorPlanData = json.decode(floorPlanString);
          _floorPlan = FloorPlan.fromJson(floorPlanData);
        } catch (e) {
          print('Error loading floor-plan.json: $e');
          // フォールバック: 部屋データから間取り図を生成
          if (_rooms.isNotEmpty) {
            _floorPlan = _generateFloorPlanFromRooms();
          }
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      _isLoading = false;
      _errorMessage = 'データの読み込みに失敗しました: $e';
      print('Error loading data: $e');
      print('Stack trace: $stackTrace');
      notifyListeners();
    }
  }

  FloorPlan _generateFloorPlanFromRooms() {
    try {
      // 部屋データから簡易的な間取り図を生成
      final rooms = _rooms.map((room) {
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
      }).whereType<room_models.FloorPlanRoom>().toList();

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

  /// デバイスの説明書URLを更新（Smart Ingester バックグラウンド検索完了時）
  Future<void> updateDeviceManual(String deviceId, Manual manual) async {
    final i = _devices.indexWhere((d) => d.id == deviceId);
    if (i < 0) return;
    final prev = _devices[i];
    _devices[i] = prev.copyWith(manual: manual);
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
