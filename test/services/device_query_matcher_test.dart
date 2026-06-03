import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/services/device_query_matcher.dart';

void main() {
  final tv = Device(
    id: 'tv_001',
    name: 'BRAVIA 65V型',
    modelNumber: 'XRJ-65A95K',
    category: 'テレビ',
    manufacturer: 'SONY',
    purchaseDate: '2023-01-01',
    purchasePrice: 100,
    yearsOwned: 1,
    room: 'living-room',
    location: '',
    status: 'active',
    consumables: [],
    photos: [],
    documents: [],
  );

  test('カテゴリキーワードでテレビをマッチ', () {
    final hit = DeviceQueryMatcher.findRelevant('リビングのテレビの型番', [tv]);
    expect(hit?.id, 'tv_001');
  });

  test('型番文字列でマッチ', () {
    expect(
      DeviceQueryMatcher.hasDeviceMatch('XRJ-65A95Kの保証', [tv]),
      isTrue,
    );
  });
}
