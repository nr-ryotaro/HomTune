import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device_remote_link.dart';
import 'package:homtune/models/remote_compatibility_assessment.dart';
import 'package:homtune/services/remote_control/remote_compatibility_service.dart';

void main() {
  final service = RemoteCompatibilityService.instance;

  setUp(() {
    service.resetForTest();
    service.loadCatalogForTest({
      'categoryRules': [
        {
          'categories': ['エアコン'],
          'eligible': true,
          'profile': 'aircon',
          'label': 'エアコン',
          'providers': ['remo'],
        },
        {
          'categories': ['冷蔵庫'],
          'eligible': false,
          'profile': null,
          'label': null,
          'providers': [],
        },
      ],
      'archetypeRules': [
        {
          'archetypeId': 'living_tv',
          'eligible': true,
          'profile': 'tv',
          'label': 'テレビ',
        },
      ],
      'modelPatterns': [
        {
          'manufacturer': 'SONY',
          'pattern': '^XRJ-',
          'eligible': true,
          'profile': 'tv',
          'label': 'SONY テレビ',
        },
        {
          'manufacturer': '',
          'pattern': '^CS-',
          'eligible': true,
          'profile': 'aircon',
          'label': 'エアコン（型番）',
        },
      ],
    });
  });

  test('型番パターンでエアコンを high 判定', () async {
    final result = await service.assess(
      modelNumber: 'CS-ZX2811',
      category: 'その他',
      manufacturer: 'Panasonic',
    );

    expect(result.isEligible, isTrue);
    expect(result.profile, RemoteCapabilityProfile.aircon);
    expect(result.source, RemoteCompatibilitySource.modelPattern);
    expect(result.confidence, RemoteCompatibilityConfidence.high);
  });

  test('カテゴリでエアコンを判定', () async {
    final result = await service.assess(
      modelNumber: '',
      category: 'エアコン',
    );

    expect(result.isEligible, isTrue);
    expect(result.profile, RemoteCapabilityProfile.aircon);
    expect(result.source, RemoteCompatibilitySource.category);
  });

  test('アーキタイプでテレビを判定', () async {
    final result = await service.assess(
      modelNumber: '',
      category: '',
      archetypeId: 'living_tv',
    );

    expect(result.isEligible, isTrue);
    expect(result.profile, RemoteCapabilityProfile.tv);
    expect(result.source, RemoteCompatibilitySource.archetype);
  });

  test('メーカー付き型番でテレビを判定', () async {
    final result = await service.assess(
      modelNumber: 'XRJ-65A95K',
      category: 'テレビ',
      manufacturer: 'SONY',
    );

    expect(result.isEligible, isTrue);
    expect(result.profile, RemoteCapabilityProfile.tv);
    expect(result.label, 'SONY テレビ');
  });

  test('非対応カテゴリは不可', () async {
    final result = await service.assess(
      modelNumber: '',
      category: '冷蔵庫',
      manufacturer: 'Panasonic',
    );

    expect(result.isEligible, isFalse);
  });

  test('型番が優先され非対応カテゴリでもエアコン判定', () async {
    final result = await service.assess(
      modelNumber: 'CS-TEST',
      category: '冷蔵庫',
    );

    expect(result.isEligible, isTrue);
    expect(result.profile, RemoteCapabilityProfile.aircon);
  });

  test('入力不足は不可', () async {
    final result = await service.assess(
      modelNumber: '',
      category: '',
    );

    expect(result.isEligible, isFalse);
  });
}
