import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/models/device_remote_link.dart';
import 'package:homtune/models/remote_appliance.dart';
import 'package:homtune/models/remote_compatibility_assessment.dart';
import 'package:homtune/services/remote_control/remote_appliance_ranker.dart';

void main() {
  final device = Device(
    id: 'd1',
    name: 'リビングエアコン',
    modelNumber: 'CS-ZX2811',
    category: 'エアコン',
    manufacturer: 'Panasonic',
    purchaseDate: '2024-01-01',
    purchasePrice: 100000,
    yearsOwned: 1,
    room: 'living-room',
    location: '',
    status: 'active',
    consumables: [],
    photos: [],
    documents: [],
  );

  List<RemoteAppliance> sampleAppliances() => [
        const RemoteAppliance(
          id: 'a1',
          provider: RemoteProvider.remo,
          nickname: 'キッチン照明',
          profile: RemoteCapabilityProfile.light,
        ),
        const RemoteAppliance(
          id: 'a2',
          provider: RemoteProvider.remo,
          nickname: 'リビングエアコン',
          profile: RemoteCapabilityProfile.aircon,
        ),
        const RemoteAppliance(
          id: 'a3',
          provider: RemoteProvider.remo,
          nickname: '寝室テレビ',
          profile: RemoteCapabilityProfile.tv,
        ),
      ];

  test('部屋・カテゴリ・型番でリビングエアコンを最上位に推薦', () {
    final ranked = RemoteApplianceRanker.rank(
      device: device,
      appliances: sampleAppliances(),
      assessment: const RemoteCompatibilityAssessment(
        isEligible: true,
        profile: RemoteCapabilityProfile.aircon,
        label: 'エアコン',
      ),
    );

    expect(ranked.first.appliance.id, 'a2');
    expect(ranked.first.isRecommended, isTrue);
    expect(ranked.first.score, greaterThan(ranked[1].score));
  });

  test('スコアが低い場合はおすすめバッジを付けない', () {
    final ranked = RemoteApplianceRanker.rank(
      device: Device(
        id: 'd2',
        name: '加湿器',
        modelNumber: 'SH-C300',
        category: '加湿器',
        manufacturer: 'cado',
        purchaseDate: '2024-01-01',
        purchasePrice: 10000,
        yearsOwned: 1,
        room: 'living-room',
        location: '',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
      ),
      appliances: sampleAppliances(),
    );

    expect(ranked.every((r) => !r.isRecommended), isTrue);
  });
}
