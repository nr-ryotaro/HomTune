import 'device_remote_link.dart';

class RemoteSignal {
  final String id;
  final String name;
  final String? image;

  const RemoteSignal({
    required this.id,
    required this.name,
    this.image,
  });

  factory RemoteSignal.fromJson(Map<String, dynamic> json) {
    return RemoteSignal(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
    );
  }
}

class RemoteAppliance {
  final String id;
  final RemoteProvider provider;
  final String nickname;
  final String? type;
  final String? model;
  final String? hubDeviceId;
  final RemoteCapabilityProfile profile;
  final List<RemoteSignal> signals;

  const RemoteAppliance({
    required this.id,
    required this.provider,
    required this.nickname,
    this.type,
    this.model,
    this.hubDeviceId,
    required this.profile,
    this.signals = const [],
  });

  factory RemoteAppliance.fromJson(Map<String, dynamic> json) {
    final provider = RemoteProvider.values.firstWhere(
      (e) => e.name == json['provider'],
      orElse: () => RemoteProvider.remo,
    );
    final type = json['type']?.toString();
    final model = json['model']?.toString();
    RemoteCapabilityProfile profile;
    if (json['profile'] != null) {
      profile = RemoteCapabilityProfile.values.firstWhere(
        (e) => e.name == json['profile'],
        orElse: () => RemoteCapabilityProfile.genericIr,
      );
    } else if (provider == RemoteProvider.remo) {
      profile = DeviceRemoteLink.inferFromRemoType(type, model);
    } else {
      profile = DeviceRemoteLink.inferFromSwitchBotType(type ?? '');
    }

    return RemoteAppliance(
      id: json['id']?.toString() ?? '',
      provider: provider,
      nickname: json['nickname']?.toString() ?? '',
      type: type,
      model: model,
      hubDeviceId: json['hubDeviceId']?.toString(),
      profile: profile,
      signals: (json['signals'] as List<dynamic>?)
              ?.map((e) => RemoteSignal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

enum RemoteCommandType {
  powerOn,
  powerOff,
  tempUp,
  tempDown,
  volumeUp,
  volumeDown,
  channelUp,
  channelDown,
  sendSignal,
  botPress,
  curtainOpen,
  curtainClose,
  airconCool,
  airconWarm,
  airconDry,
  airconFan,
  airconAuto,
  airconEco,
  airconTimer,
  airconSwing,
  tvMute,
  tvInput,
  tvApp,
}

class RemoteCommand {
  final String deviceId;
  final RemoteProvider provider;
  final String externalApplianceId;
  final RemoteCommandType type;
  final String? signalId;
  final String? hubDeviceId;
  final Map<String, dynamic>? parameters;

  const RemoteCommand({
    required this.deviceId,
    required this.provider,
    required this.externalApplianceId,
    required this.type,
    this.signalId,
    this.hubDeviceId,
    this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'provider': provider.name,
        'externalApplianceId': externalApplianceId,
        'type': type.name,
        if (signalId != null) 'signalId': signalId,
        if (hubDeviceId != null) 'hubDeviceId': hubDeviceId,
        if (parameters != null) 'parameters': parameters,
      };
}

class RemoteControlResult {
  final bool success;
  final String? message;
  final int? remainingMonthlyQuota;

  const RemoteControlResult({
    required this.success,
    this.message,
    this.remainingMonthlyQuota,
  });

  factory RemoteControlResult.fromJson(Map<String, dynamic> json) {
    return RemoteControlResult(
      success: json['success'] == true,
      message: json['message']?.toString(),
      remainingMonthlyQuota: (json['remainingMonthlyQuota'] as num?)?.toInt(),
    );
  }
}
