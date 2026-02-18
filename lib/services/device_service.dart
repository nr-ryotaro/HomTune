import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/device.dart';
import '../models/room.dart';
import '../models/room.dart' as room_models;
import 'asset_valuation_service.dart';

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
      // 資産価値を計算 (Double Timeline Logic)
      final valuationService = AssetValuationService();
      final calculatedAssetValue =
          await valuationService.calculateAssetValue(device);

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

      // assets/data/mock-data.json からの読み込みを無効化し、
      // 今回実装したダミーデータのみを使用するように変更
      _devices = [];
      _rooms = [];

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

      _isLoading = false;

      // リビングルームのダミーデータを注入
      final livingRoomId = _rooms
          .firstWhere((r) => r.name.contains('リビング') || r.id.contains('living'),
              orElse: () => Room(
                  id: 'living-room',
                  name: 'リビング',
                  type: 'living_room',
                  floor: 1,
                  coordinates: RoomCoordinates(x: 0, y: 0, width: 0, height: 0),
                  devices: []))
          .id;

      if (livingRoomId.isNotEmpty) {
        final dummyDevices = [
          Device(
            id: 'tv_001',
            name: 'BRAVIA 65V型 有機ELテレビ',
            modelNumber: 'XRJ-65A95K',
            category: 'TV',
            manufacturer: 'SONY',
            purchaseDate: '2023-06-15',
            purchasePrice: 450000,
            yearsOwned: 2.5,
            room: livingRoomId,
            location: 'リビングボード',
            status: 'active',
            consumables: [],
            photos: [],
            documents: [],
            assetValue: AssetValue(
              purchasePrice: 450000,
              currentUsedPrice: 320000,
              depreciationRate: 0.1,
              lastPriceCheck: DateTime.now().toIso8601String(),
              priceHistory: [],
            ),
          ),
          Device(
            id: 'speaker_001',
            name: 'ブックシェルフスピーカー ライトオーク',
            modelNumber: 'OBERON1 LO',
            category: 'Speaker',
            manufacturer: 'DALI',
            purchaseDate: '2023-01-20',
            purchasePrice: 75000,
            yearsOwned: 3.0,
            room: livingRoomId,
            location: 'リビングボード',
            status: 'active',
            consumables: [],
            photos: [],
            documents: [],
            assetValue: AssetValue(
              purchasePrice: 75000,
              currentUsedPrice: 50000,
              depreciationRate: 0.1,
              lastPriceCheck: DateTime.now().toIso8601String(),
              priceHistory: [],
            ),
          ),
          Device(
            id: 'record_player_001',
            name: 'Bluetoothトランスミッター搭載 アナログターンテーブル',
            modelNumber: 'TN-400BT-WA',
            category: 'Record Player',
            manufacturer: 'TEAC',
            purchaseDate: '2022-11-10',
            purchasePrice: 58000,
            yearsOwned: 3.2,
            room: livingRoomId,
            location: 'サイドテーブル',
            status: 'active',
            consumables: [],
            photos: [],
            documents: [],
            assetValue: AssetValue(
              purchasePrice: 58000,
              currentUsedPrice: 42000,
              depreciationRate: 0.1,
              lastPriceCheck: DateTime.now().toIso8601String(),
              priceHistory: [],
            ),
          ),
          Device(
            id: 'humidifier_001',
            name: '超音波式加湿器 クールグレー',
            modelNumber: 'STEM 300 CG',
            category: 'Humidifier',
            manufacturer: 'cado',
            purchaseDate: '2023-12-01',
            purchasePrice: 29800,
            yearsOwned: 1.2,
            room: livingRoomId,
            location: '床',
            status: 'active',
            consumables: [],
            photos: [],
            documents: [],
            assetValue: AssetValue(
              purchasePrice: 29800,
              currentUsedPrice: 15000,
              depreciationRate: 0.2,
              lastPriceCheck: DateTime.now().toIso8601String(),
              priceHistory: [],
            ),
          ),
          Device(
            id: 'sofa_001',
            name: '2人掛けソファ ピュアオーク',
            modelNumber: 'ZU46',
            category: 'Furniture',
            manufacturer: 'Karimoku',
            purchaseDate: '2021-05-20',
            purchasePrice: 245000,
            yearsOwned: 4.5,
            room: livingRoomId,
            location: '中央',
            status: 'active',
            consumables: [],
            photos: [],
            documents: [],
            assetValue: AssetValue(
              purchasePrice: 245000,
              currentUsedPrice: 180000,
              depreciationRate: 0.05,
              lastPriceCheck: DateTime.now().toIso8601String(),
              priceHistory: [],
            ),
          ),
        ];

        // 既存のデータをフィルタリングして、IDが重複しないように追加
        for (var dummy in dummyDevices) {
          final index = _devices.indexWhere((d) => d.id == dummy.id);
          if (index >= 0) {
            _devices[index] = dummy;
          } else {
            _devices.add(dummy);
          }
        }
      }

      // 寝室のダミーデータを注入
      final bedroomId = _rooms
          .firstWhere((r) => r.name.contains('寝室') || r.id.contains('bed'),
              orElse: () => Room(
                  id: 'bedroom-01',
                  name: '寝室',
                  type: 'bedroom',
                  floor: 1,
                  coordinates: RoomCoordinates(x: 0, y: 0, width: 0, height: 0),
                  devices: []))
          .id;

      if (bedroomId.isNotEmpty) {
        final dummyBedroomDevices = [
          Device(
            id: 'tv_bed_001',
            name: 'The Frame 55V型 (壁掛けアートTV)',
            modelNumber: 'QA55LS03B',
            category: 'TV',
            manufacturer: 'SAMSUNG',
            purchaseDate: '2023-09-10',
            purchasePrice: 180000,
            yearsOwned: 2.3,
            room: bedroomId,
            location: '壁',
            status: 'active',
            consumables: [],
            photos: [],
            documents: [],
            assetValue: AssetValue(
              purchasePrice: 180000,
              currentUsedPrice: 110000,
              depreciationRate: 0.15,
              lastPriceCheck: DateTime.now().toIso8601String(),
              priceHistory: [],
            ),
          ),
          Device(
            id: 'bed_001',
            name: 'Arlington ベッド オーク・ファブリック張り',
            modelNumber: 'Arlington',
            category: 'Furniture',
            manufacturer: 'BoConcept',
            purchaseDate: '2022-04-05',
            purchasePrice: 285000,
            yearsOwned: 3.8,
            room: bedroomId,
            location: '中央',
            status: 'active',
            consumables: [],
            photos: [],
            documents: [],
            assetValue: AssetValue(
              purchasePrice: 285000,
              currentUsedPrice: 160000,
              depreciationRate: 0.1,
              lastPriceCheck: DateTime.now().toIso8601String(),
              priceHistory: [],
            ),
          ),
          Device(
            id: 'light_bed_001',
            name: 'IC Lights S1 (真鍮/フロストガラス)',
            modelNumber: 'IC Lights S1',
            category: 'Lighting',
            manufacturer: 'FLOS',
            purchaseDate: '2023-02-14',
            purchasePrice: 85000,
            yearsOwned: 3.0,
            room: bedroomId,
            location: '天井',
            status: 'active',
            consumables: [],
            photos: [],
            documents: [],
            assetValue: AssetValue(
              purchasePrice: 85000,
              currentUsedPrice: 60000,
              depreciationRate: 0.05,
              lastPriceCheck: DateTime.now().toIso8601String(),
              priceHistory: [],
            ),
          ),
          Device(
            id: 'smart_speaker_bed_001',
            name: 'HomePod (第2世代) ホワイト',
            modelNumber: 'MQJ73J/A',
            category: 'Smart Speaker',
            manufacturer: 'Apple',
            purchaseDate: '2024-01-15',
            purchasePrice: 44800,
            yearsOwned: 1.0,
            room: bedroomId,
            location: 'サイドテーブル',
            status: 'active',
            consumables: [],
            photos: [],
            documents: [],
            assetValue: AssetValue(
              purchasePrice: 44800,
              currentUsedPrice: 32000,
              depreciationRate: 0.2,
              lastPriceCheck: DateTime.now().toIso8601String(),
              priceHistory: [],
            ),
          ),
          Device(
            id: 'cabinet_bed_001',
            name: 'フロートTVボード オーク',
            modelNumber: 'Margin Cabinet MA-180',
            category: 'Furniture',
            manufacturer: 'Pamouna',
            purchaseDate: '2023-08-20',
            purchasePrice: 125000,
            yearsOwned: 2.5,
            room: bedroomId,
            location: '壁',
            status: 'active',
            consumables: [],
            photos: [],
            documents: [],
            assetValue: AssetValue(
              purchasePrice: 125000,
              currentUsedPrice: 75000,
              depreciationRate: 0.1,
              lastPriceCheck: DateTime.now().toIso8601String(),
              priceHistory: [],
            ),
          ),
        ];

        // 既存のデータをフィルタリングして、IDが重複しないように追加
        for (var dummy in dummyBedroomDevices) {
          final index = _devices.indexWhere((d) => d.id == dummy.id);
          if (index >= 0) {
            _devices[index] = dummy;
          } else {
            _devices.add(dummy);
          }
        }
      }

      // キッチンのダミーデータを注入
      final kitchenId = _rooms
          .firstWhere(
              (r) => r.name.contains('キッチン') || r.id.contains('kitchen'),
              orElse: () => Room(
                  id: 'kitchen-01',
                  name: 'キッチン',
                  type: 'kitchen',
                  floor: 1,
                  coordinates: RoomCoordinates(x: 0, y: 0, width: 0, height: 0),
                  devices: []))
          .id;

      if (kitchenId.isNotEmpty) {
        final dummyKitchenDevices = [
          Device(
            id: 'fridge_001',
            name: 'IoT対応 フルスペック冷蔵庫 600L',
            modelNumber: 'NR-F608WPX',
            category: 'Refrigerator',
            manufacturer: 'Panasonic',
            purchaseDate: '2022-03-10', // 発売日直後に購入と仮定
            purchasePrice: 350000,
            yearsOwned: 3.9,
            room: kitchenId,
            location: '冷蔵庫置き場',
            status: 'active',
            condition: ItemCondition.newItem,
            releaseDate: DateTime(2022, 2, 25),
            originalPrice: 380000,
            consumables: [],
            photos: [],
            documents: [],
            assetValue: AssetValue(
              purchasePrice: 350000,
              currentUsedPrice: 180000,
              depreciationRate: 0.1,
              lastPriceCheck: DateTime.now().toIso8601String(),
              priceHistory: [],
            ),
          ),
          Device(
            id: 'oven_001',
            name: 'ビルトインコンベクションオーブン',
            modelNumber: 'H 7164 B',
            category: 'Oven',
            manufacturer: 'Miele',
            purchaseDate: '2021-01-20',
            purchasePrice: 385000,
            yearsOwned: 5.0,
            room: kitchenId,
            location: 'ビルトイン',
            status: 'active',
            condition: ItemCondition.newItem,
            releaseDate: DateTime(2020, 12, 1),
            originalPrice: 385000,
            consumables: [],
            photos: [],
            documents: [],
            assetValue: AssetValue(
              purchasePrice: 385000,
              currentUsedPrice: 250000,
              depreciationRate: 0.08,
              lastPriceCheck: DateTime.now().toIso8601String(),
              priceHistory: [],
            ),
          ),
          Device(
            id: 'espresso_001',
            name: 'the Barista Express シーソルト',
            modelNumber: 'BES875',
            category: 'Coffee Maker',
            manufacturer: 'Breville',
            purchaseDate: '2023-05-15', // 中古購入
            purchasePrice: 75000,
            yearsOwned: 2.7,
            room: kitchenId,
            location: 'カウンター',
            status: 'active',
            condition: ItemCondition.usedItem,
            releaseDate: DateTime(2021, 6, 1),
            originalPrice: 130000,
            consumables: [],
            photos: [],
            documents: [],
            assetValue: AssetValue(
              purchasePrice: 75000,
              currentUsedPrice: 68000,
              depreciationRate: 0.15,
              lastPriceCheck: DateTime.now().toIso8601String(),
              priceHistory: [],
            ),
          ),
          Device(
            id: 'rice_cooker_001',
            name: 'ライスポット 5合炊き ホワイト',
            modelNumber: 'PH23A-WH',
            category: 'Rice Cooker',
            manufacturer: 'Vermicular',
            purchaseDate: '2017-01-10',
            purchasePrice: 98800,
            yearsOwned: 9.0,
            room: kitchenId,
            location: 'カウンター',
            status: 'active',
            condition: ItemCondition.newItem,
            releaseDate: DateTime(2016, 12, 1),
            originalPrice: 98800,
            consumables: [],
            photos: [],
            documents: [],
            assetValue: AssetValue(
              purchasePrice: 98800,
              currentUsedPrice: 50000,
              depreciationRate: 0.1,
              lastPriceCheck: DateTime.now().toIso8601String(),
              priceHistory: [],
            ),
          ),
          Device(
            id: 'light_kitchen_001',
            name: 'アンビット ペンダントランプ',
            modelNumber: 'Ambit Pendant',
            category: 'Lighting',
            manufacturer: 'Muuto',
            purchaseDate: '2024-02-01', // 中古購入
            purchasePrice: 25000,
            yearsOwned: 2.0,
            room: kitchenId,
            location: '天井',
            status: 'active',
            condition: ItemCondition.usedItem,
            releaseDate: DateTime(2015, 1, 1), // ロングセラー
            originalPrice: 48000,
            consumables: [],
            photos: [],
            documents: [],
            assetValue: AssetValue(
              purchasePrice: 25000, // 中古購入価格
              currentUsedPrice: 20000,
              depreciationRate: 0.05,
              lastPriceCheck: DateTime.now().toIso8601String(),
              priceHistory: [],
            ),
          ),
        ];

        // 既存のデータをフィルタリングして、IDが重複しないように追加
        for (var i = 0; i < dummyKitchenDevices.length; i++) {
          var device = dummyKitchenDevices[i];
          // AssetValuationServiceを使って資産価値を再計算
          try {
            final valuationService = AssetValuationService();
            // 発売日がnullの場合は、仮の発売日を設定（購入日の1年前など）して計算精度を確保
            // ※本来はマスタデータから取得すべき
            if (device.condition == ItemCondition.usedItem &&
                device.releaseDate == null) {
              device = device.copyWith(
                  releaseDate: DateTime.parse(device.purchaseDate)
                      .subtract(const Duration(days: 365)));
            }

            final calculatedValue =
                await valuationService.calculateAssetValue(device);
            device = device.copyWith(assetValue: calculatedValue);
            dummyKitchenDevices[i] = device;
          } catch (e) {
            print('Error calculating asset value for ${device.name}: $e');
            // エラー時はハードコードされた値をそのまま使用
          }

          final index = _devices.indexWhere((d) => d.id == device.id);
          if (index >= 0) {
            _devices[index] = device;
          } else {
            _devices.add(device);
          }
        }
      }

      // フォールバック: 部屋データから間取り図を生成
      // (ダミーデータ注入後に実行することで、注入された部屋が反映される)
      if (_rooms.isNotEmpty &&
          (_floorPlan == null || _floorPlan!.rooms.isEmpty)) {
        _floorPlan = _generateFloorPlanFromRooms();
      }

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
