import '../../models/device.dart';
import '../../models/device_remote_link.dart';
import '../../models/remote_appliance.dart';
import '../../models/remote_compatibility_assessment.dart';

class RankedRemoteAppliance {
  final RemoteAppliance appliance;
  final int score;
  final bool isRecommended;

  const RankedRemoteAppliance({
    required this.appliance,
    required this.score,
    required this.isRecommended,
  });
}

/// 登録済み Device と外部家電一覧のマッチングスコア
class RemoteApplianceRanker {
  RemoteApplianceRanker._();

  static const int recommendThreshold = 35;

  static List<RankedRemoteAppliance> rank({
    required Device device,
    required List<RemoteAppliance> appliances,
    RemoteCompatibilityAssessment? assessment,
  }) {
    if (appliances.isEmpty) return [];

    final expectedProfile = assessment?.profile ??
        DeviceRemoteLink.inferFromCategory(device.category);

    final ranked = appliances.map((appliance) {
      final score = _scoreAppliance(
        device: device,
        appliance: appliance,
        expectedProfile: expectedProfile,
        assessment: assessment,
      );
      return RankedRemoteAppliance(
        appliance: appliance,
        score: score,
        isRecommended: false,
      );
    }).toList();

    ranked.sort((a, b) => b.score.compareTo(a.score));

    final topScore = ranked.first.score;
    return ranked
        .map(
          (r) => RankedRemoteAppliance(
            appliance: r.appliance,
            score: r.score,
            isRecommended:
                r.score >= recommendThreshold && r.score == topScore && topScore > 0,
          ),
        )
        .toList();
  }

  static int _scoreAppliance({
    required Device device,
    required RemoteAppliance appliance,
    required RemoteCapabilityProfile expectedProfile,
    RemoteCompatibilityAssessment? assessment,
  }) {
    var score = 0;
    final nickname = appliance.nickname.toLowerCase();
    final model = (appliance.model ?? '').toLowerCase();
    final deviceModel = device.modelNumber.trim().toLowerCase();
    final deviceName = device.name.trim().toLowerCase();
    final manufacturer = device.manufacturer.trim().toLowerCase();
    final category = device.category.trim().toLowerCase();
    final room = device.room.trim().toLowerCase();

    if (deviceModel.isNotEmpty) {
      if (nickname.contains(deviceModel) || model.contains(deviceModel)) {
        score += 40;
      } else {
        final prefix = deviceModel.length >= 4
            ? deviceModel.substring(0, 4)
            : deviceModel;
        if (nickname.contains(prefix) || model.contains(prefix)) {
          score += 25;
        }
      }
    }

    if (manufacturer.isNotEmpty && nickname.contains(manufacturer)) {
      score += 20;
    }

    if (category.isNotEmpty) {
      if (nickname.contains(category)) score += 25;
      for (final keyword in _categoryKeywords(category)) {
        if (nickname.contains(keyword)) {
          score += 15;
          break;
        }
      }
    }

    if (deviceName.isNotEmpty) {
      for (final token in deviceName.split(RegExp(r'\s+'))) {
        if (token.length >= 2 && nickname.contains(token)) {
          score += 10;
          break;
        }
      }
    }

    score += _roomScore(room, nickname);

    if (appliance.profile == expectedProfile) {
      score += 30;
    } else if (_profilesCompatible(appliance.profile, expectedProfile)) {
      score += 12;
    }

    if (assessment?.label != null) {
      final label = assessment!.label!.toLowerCase();
      if (nickname.contains(label)) score += 10;
    }

    return score;
  }

  static int _roomScore(String room, String nickname) {
    if (room.isEmpty) return 0;
    const roomKeywords = {
      'living': ['リビング', 'living'],
      'kitchen': ['キッチン', 'kitchen', '台所'],
      'bed': ['寝室', 'ベッド', 'bedroom'],
      'bath': ['浴室', 'バス', 'bath'],
    };
    for (final entry in roomKeywords.entries) {
      if (!room.contains(entry.key)) continue;
      for (final kw in entry.value) {
        if (nickname.contains(kw)) return 20;
      }
    }
    return 0;
  }

  static List<String> _categoryKeywords(String category) {
    final c = category.toLowerCase();
    if (c.contains('エアコン')) {
      return ['エアコン', 'aircon', 'ac', 'クーラー'];
    }
    if (c.contains('テレビ') || c == 'tv') {
      return ['テレビ', 'tv', 'ブラビア', 'bravia', 'viera'];
    }
    if (c.contains('照明') || c.contains('ライト')) {
      return ['照明', 'ライト', 'light'];
    }
    return [];
  }

  static bool _profilesCompatible(
    RemoteCapabilityProfile a,
    RemoteCapabilityProfile b,
  ) {
    if (a == b) return true;
    if (a == RemoteCapabilityProfile.genericIr ||
        b == RemoteCapabilityProfile.genericIr) {
      return true;
    }
    return false;
  }
}
