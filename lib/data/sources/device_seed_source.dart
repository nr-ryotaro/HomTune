import '../../models/device.dart';
import '../../models/room.dart';
import '../../services/asset_valuation_service.dart';

/// Demo seed devices merged into the device list.
class DeviceSeedSource {
  Future<List<Device>> mergeSeedDevices(
    List<Device> devices,
    List<Room> rooms,
  ) async {
    final result = List<Device>.from(devices);
      // リビングルームのダミーデータを注入
      final livingRoomId = rooms
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
            category: 'テレビ',
            archetypeId: 'living_tv',
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
            modelNumber: 'OBERON 1 LO',
            category: 'オーディオ',
            archetypeId: 'living_audio',
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
            category: 'オーディオ',
            archetypeId: 'living_record_player',
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
            modelNumber: 'SH-C300',
            category: '加湿器',
            archetypeId: 'living_humidifier',
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
            category: 'その他',
            archetypeId: 'living_sofa',
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
          final index = result.indexWhere((d) => d.id == dummy.id);
          if (index >= 0) {
            result[index] = dummy;
          } else {
            result.add(dummy);
          }
        }
      }

      // 寝室のダミーデータを注入
      final bedroomId = rooms
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
            modelNumber: 'QA55LS03BW',
            category: 'テレビ',
            archetypeId: 'living_tv',
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
            category: 'その他',
            archetypeId: 'bedroom_bed',
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
            modelNumber: 'FLOS IC Lights S1',
            category: 'その他',
            archetypeId: 'bedroom_light',
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
            category: 'オーディオ',
            archetypeId: 'living_audio',
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
            category: 'その他',
            archetypeId: 'bedroom_storage',
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
          final index = result.indexWhere((d) => d.id == dummy.id);
          if (index >= 0) {
            result[index] = dummy;
          } else {
            result.add(dummy);
          }
        }
      }

      // キッチンのダミーデータを注入
      final kitchenId = rooms
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
            category: '冷蔵庫',
            archetypeId: 'kitchen_fridge',
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
            category: 'コンロ',
            archetypeId: 'kitchen_stove',
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
            modelNumber: 'BES875SST',
            category: 'その他',
            archetypeId: 'kitchen_coffee',
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
            category: '炊飯器',
            archetypeId: 'kitchen_rice_cooker',
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
            category: 'その他',
            archetypeId: 'kitchen_light',
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

          final index = result.indexWhere((d) => d.id == device.id);
          if (index >= 0) {
            result[index] = device;
          } else {
            result.add(device);
          }
        }
      }
    return result;
  }
}
