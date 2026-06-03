import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/models/local_response_plan.dart';
import 'package:homtune/services/local_response_planner.dart';

void main() {
  final livingTv = Device(
    id: 'tv_001',
    name: 'BRAVIA 65V型 有機ELテレビ',
    modelNumber: 'XRJ-65A95K',
    category: 'テレビ',
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
  );

  final devices = [livingTv];

  test('型番質問は modelNumber で高信頼', () {
    final plan = LocalResponsePlanner.plan(
      'リビングのテレビの型番を教えて',
      devices,
    );
    expect(plan.canAnswer, isTrue);
    expect(plan.confidence, greaterThanOrEqualTo(0.7));
    expect(plan.topic, LocalResponseTopic.modelNumber);
    expect(plan.matchedDevice?.id, 'tv_001');
  });

  test('何台質問は deviceCount', () {
    final plan = LocalResponsePlanner.plan('登録してる家電は何台？', devices);
    expect(plan.topic, LocalResponseTopic.deviceCount);
    expect(plan.canAnswer, isTrue);
    expect(plan.confidence, greaterThanOrEqualTo(0.9));
  });

  test('比較質問は canAnswer false', () {
    final plan = LocalResponsePlanner.plan(
      'エアコンと冷房の電気代を比較して最適化して',
      devices,
    );
    expect(plan.canAnswer, isFalse);
    expect(plan.topic, LocalResponseTopic.none);
  });
}
