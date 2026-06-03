import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/services/appliance_template_service.dart';

/// シード相当の登録内容がアイコン・型番表示に反映されること
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final seedFixtures = <({
    String label,
    Device device,
    String expectedIcon,
    String expectedTitle,
    String expectedModel,
  })>[
    (
      label: 'リビングTV',
      device: Device(
        id: 'tv_001',
        name: 'BRAVIA 65V型 有機ELテレビ',
        modelNumber: 'XRJ-65A95K',
        category: 'テレビ',
        archetypeId: 'living_tv',
        manufacturer: 'SONY',
        purchaseDate: '2023-06-15',
        purchasePrice: 450000,
        yearsOwned: 2.5,
        room: 'living-room',
        location: '',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
      ),
      expectedIcon: '📺',
      expectedTitle: 'テレビ',
      expectedModel: 'XRJ-65A95K',
    ),
    (
      label: 'リビングスピーカー',
      device: Device(
        id: 'speaker_001',
        name: 'ブックシェルフスピーカー',
        modelNumber: 'OBERON 1 LO',
        category: 'オーディオ',
        archetypeId: 'living_audio',
        manufacturer: 'DALI',
        purchaseDate: '2023-01-20',
        purchasePrice: 75000,
        yearsOwned: 3,
        room: 'living-room',
        location: '',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
      ),
      expectedIcon: '🔊',
      expectedTitle: 'スピーカー / AV機器',
      expectedModel: 'OBERON 1 LO',
    ),
    (
      label: 'キッチン冷蔵庫',
      device: Device(
        id: 'fridge_001',
        name: 'IoT対応 フルスペック冷蔵庫 600L',
        modelNumber: 'NR-F608WPX',
        category: '冷蔵庫',
        archetypeId: 'kitchen_fridge',
        manufacturer: 'Panasonic',
        purchaseDate: '2022-03-10',
        purchasePrice: 350000,
        yearsOwned: 3.9,
        room: 'kitchen-01',
        location: '',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
      ),
      expectedIcon: '🧊',
      expectedTitle: '冷蔵庫',
      expectedModel: 'NR-F608WPX',
    ),
    (
      label: 'レコードプレーヤー',
      device: Device(
        id: 'record_player_001',
        name: 'アナログターンテーブル',
        modelNumber: 'TN-400BT-WA',
        category: 'オーディオ',
        archetypeId: 'living_record_player',
        manufacturer: 'TEAC',
        purchaseDate: '2022-11-10',
        purchasePrice: 58000,
        yearsOwned: 3.2,
        room: 'living-room',
        location: '',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
      ),
      expectedIcon: '💿',
      expectedTitle: 'レコードプレーヤー',
      expectedModel: 'TN-400BT-WA',
    ),
  ];

  for (final fixture in seedFixtures) {
    test('${fixture.label} shows archetype icon and model number', () async {
      final presentation = await ApplianceTemplateService.instance
          .resolvePresentation(fixture.device);

      expect(presentation.icon, fixture.expectedIcon);
      expect(presentation.title, fixture.expectedTitle);
      expect(presentation.subtitle, fixture.expectedModel);
    });
  }
}
