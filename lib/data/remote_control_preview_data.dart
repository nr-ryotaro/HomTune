import '../models/device.dart';
import '../models/device_remote_link.dart';
import '../models/remote_compatibility_assessment.dart';

/// リモコン UI プレビュー用のモックデータ
class RemoteControlPreviewData {
  RemoteControlPreviewData._();

  static Device sampleAircon() => Device(
        id: 'preview-ac',
        name: 'リビングエアコン',
        modelNumber: 'CS-ZX2811',
        category: 'エアコン',
        manufacturer: 'Panasonic',
        purchaseDate: '2024-04-01',
        purchasePrice: 180000,
        yearsOwned: 2,
        room: 'living-room',
        location: 'リビング',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
        archetypeId: 'living_ac',
      );

  static Device sampleTv() => Device(
        id: 'preview-tv',
        name: 'BRAVIA 65V型',
        modelNumber: 'XRJ-65A95K',
        category: 'テレビ',
        manufacturer: 'SONY',
        purchaseDate: '2023-01-15',
        purchasePrice: 350000,
        yearsOwned: 3,
        room: 'living-room',
        location: 'テレビボード',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
        archetypeId: 'living_tv',
      );

  static DeviceRemoteLink airconRemoLink() => DeviceRemoteLink(
        provider: RemoteProvider.remo,
        externalApplianceId: 'preview-remo-ac',
        externalNickname: 'リビングエアコン',
        profile: RemoteCapabilityProfile.aircon,
        linkedAt: DateTime.now().toIso8601String(),
      );

  static DeviceRemoteLink tvRemoLink() => DeviceRemoteLink(
        provider: RemoteProvider.remo,
        externalApplianceId: 'preview-remo-tv',
        externalNickname: 'リビングテレビ',
        profile: RemoteCapabilityProfile.tv,
        linkedAt: DateTime.now().toIso8601String(),
      );

  static DeviceRemoteLink lightSwitchBotLink() => DeviceRemoteLink(
        provider: RemoteProvider.switchbot,
        externalApplianceId: 'preview-sb-light',
        externalNickname: 'シーリングライト',
        profile: RemoteCapabilityProfile.light,
        signalIds: const {
          'powerOn': 'sig-on',
          'powerOff': 'sig-off',
        },
        linkedAt: DateTime.now().toIso8601String(),
      );

  static DeviceRemoteLink botLink() => DeviceRemoteLink(
        provider: RemoteProvider.switchbot,
        externalApplianceId: 'preview-sb-bot',
        externalNickname: 'Bot リビング',
        profile: RemoteCapabilityProfile.bot,
        linkedAt: DateTime.now().toIso8601String(),
      );

  static Device sampleLight() => Device(
        id: 'preview-light',
        name: 'シーリングライト',
        modelNumber: 'HH-CE0895A',
        category: '照明',
        manufacturer: 'Panasonic',
        purchaseDate: '2024-01-01',
        purchasePrice: 25000,
        yearsOwned: 2,
        room: 'living-room',
        location: 'リビング',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
        archetypeId: 'living_light',
      );

  static Device sampleCurtain() => Device(
        id: 'preview-curtain',
        name: 'リビングカーテン',
        modelNumber: 'SwitchBot Curtain',
        category: 'カーテン',
        manufacturer: 'SwitchBot',
        purchaseDate: '2024-06-01',
        purchasePrice: 12000,
        yearsOwned: 1,
        room: 'living-room',
        location: 'リビング',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
        archetypeId: 'living_curtain',
      );

  static Device sampleBot() => Device(
        id: 'preview-bot',
        name: 'Bot リビング',
        modelNumber: 'SwitchBot Bot',
        category: 'その他',
        manufacturer: 'SwitchBot',
        purchaseDate: '2024-03-01',
        purchasePrice: 4000,
        yearsOwned: 2,
        room: 'living-room',
        location: 'リビング',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
        archetypeId: 'living_bot',
      );

  static DeviceRemoteLink curtainLink() => DeviceRemoteLink(
        provider: RemoteProvider.switchbot,
        externalApplianceId: 'preview-sb-curtain',
        externalNickname: 'カーテン',
        profile: RemoteCapabilityProfile.curtain,
        linkedAt: DateTime.now().toIso8601String(),
      );

  static RemoteCompatibilityAssessment airconAssessment() =>
      const RemoteCompatibilityAssessment(
        isEligible: true,
        profile: RemoteCapabilityProfile.aircon,
        label: 'エアコン',
        source: RemoteCompatibilitySource.modelPattern,
        confidence: RemoteCompatibilityConfidence.high,
        userMessage: 'エアコンはスマートリモコンで操作できる可能性があります',
      );
}

enum RemoteControlPreviewScenario {
  freeLocked,
  proUnlinked,
  airconLinked,
  tvLinked,
  lightLinked,
  botLinked,
  curtainLinked,
}

extension RemoteControlPreviewScenarioX on RemoteControlPreviewScenario {
  String get label {
    switch (this) {
      case RemoteControlPreviewScenario.freeLocked:
        return 'Free（ロック）';
      case RemoteControlPreviewScenario.proUnlinked:
        return 'Pro・未紐付け';
      case RemoteControlPreviewScenario.airconLinked:
        return 'エアコン';
      case RemoteControlPreviewScenario.tvLinked:
        return 'テレビ';
      case RemoteControlPreviewScenario.lightLinked:
        return '照明';
      case RemoteControlPreviewScenario.botLinked:
        return 'Bot';
      case RemoteControlPreviewScenario.curtainLinked:
        return 'カーテン';
    }
  }

  bool get isPro {
    return this != RemoteControlPreviewScenario.freeLocked;
  }

  DeviceRemoteLink? get link {
    switch (this) {
      case RemoteControlPreviewScenario.freeLocked:
      case RemoteControlPreviewScenario.proUnlinked:
        return null;
      case RemoteControlPreviewScenario.airconLinked:
        return RemoteControlPreviewData.airconRemoLink();
      case RemoteControlPreviewScenario.tvLinked:
        return RemoteControlPreviewData.tvRemoLink();
      case RemoteControlPreviewScenario.lightLinked:
        return RemoteControlPreviewData.lightSwitchBotLink();
      case RemoteControlPreviewScenario.botLinked:
        return RemoteControlPreviewData.botLink();
      case RemoteControlPreviewScenario.curtainLinked:
        return RemoteControlPreviewData.curtainLink();
    }
  }

  Device baseDevice() {
    switch (this) {
      case RemoteControlPreviewScenario.tvLinked:
        return RemoteControlPreviewData.sampleTv();
      case RemoteControlPreviewScenario.lightLinked:
        return RemoteControlPreviewData.sampleLight();
      case RemoteControlPreviewScenario.botLinked:
        return RemoteControlPreviewData.sampleBot();
      case RemoteControlPreviewScenario.curtainLinked:
        return RemoteControlPreviewData.sampleCurtain();
      case RemoteControlPreviewScenario.freeLocked:
      case RemoteControlPreviewScenario.proUnlinked:
      case RemoteControlPreviewScenario.airconLinked:
        return RemoteControlPreviewData.sampleAircon();
    }
  }

  Device previewDevice() {
    final base = baseDevice();
    final remoteLink = link;
    if (remoteLink == null) return base;
    return base.copyWith(remoteLink: remoteLink);
  }
}
