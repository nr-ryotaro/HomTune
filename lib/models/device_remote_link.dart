enum RemoteProvider {
  remo,
  switchbot,
}

enum RemoteCapabilityProfile {
  aircon,
  tv,
  light,
  genericIr,
  bot,
  curtain,
  plug,
}

class DeviceRemoteLink {
  final RemoteProvider provider;
  final String externalApplianceId;
  final String? externalNickname;
  final String? hubDeviceId;
  final RemoteCapabilityProfile profile;
  final Map<String, String> signalIds;
  final String linkedAt;

  const DeviceRemoteLink({
    required this.provider,
    required this.externalApplianceId,
    this.externalNickname,
    this.hubDeviceId,
    required this.profile,
    this.signalIds = const {},
    required this.linkedAt,
  });

  factory DeviceRemoteLink.fromJson(Map<String, dynamic> json) {
    return DeviceRemoteLink(
      provider: RemoteProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => RemoteProvider.remo,
      ),
      externalApplianceId: json['externalApplianceId']?.toString() ?? '',
      externalNickname: json['externalNickname']?.toString(),
      hubDeviceId: json['hubDeviceId']?.toString(),
      profile: RemoteCapabilityProfile.values.firstWhere(
        (e) => e.name == json['profile'],
        orElse: () => RemoteCapabilityProfile.genericIr,
      ),
      signalIds: (json['signalIds'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          {},
      linkedAt: json['linkedAt']?.toString() ??
          DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'externalApplianceId': externalApplianceId,
        if (externalNickname != null) 'externalNickname': externalNickname,
        if (hubDeviceId != null) 'hubDeviceId': hubDeviceId,
        'profile': profile.name,
        'signalIds': signalIds,
        'linkedAt': linkedAt,
      };

  DeviceRemoteLink copyWith({
    RemoteProvider? provider,
    String? externalApplianceId,
    String? externalNickname,
    String? hubDeviceId,
    RemoteCapabilityProfile? profile,
    Map<String, String>? signalIds,
    String? linkedAt,
  }) {
    return DeviceRemoteLink(
      provider: provider ?? this.provider,
      externalApplianceId: externalApplianceId ?? this.externalApplianceId,
      externalNickname: externalNickname ?? this.externalNickname,
      hubDeviceId: hubDeviceId ?? this.hubDeviceId,
      profile: profile ?? this.profile,
      signalIds: signalIds ?? this.signalIds,
      linkedAt: linkedAt ?? this.linkedAt,
    );
  }

  static RemoteCapabilityProfile inferFromCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('エアコン') || c.contains('air')) {
      return RemoteCapabilityProfile.aircon;
    }
    if (c.contains('テレビ') || c.contains('tv')) {
      return RemoteCapabilityProfile.tv;
    }
    if (c.contains('照明') || c.contains('ライト')) {
      return RemoteCapabilityProfile.light;
    }
    return RemoteCapabilityProfile.genericIr;
  }

  static RemoteCapabilityProfile inferFromRemoType(String? type, String? model) {
    final t = (type ?? '').toUpperCase();
    final m = (model ?? '').toUpperCase();
    if (t.contains('AC') || m.contains('AC')) {
      return RemoteCapabilityProfile.aircon;
    }
    if (t.contains('TV') || m.contains('TV')) {
      return RemoteCapabilityProfile.tv;
    }
    if (t.contains('LIGHT') || m.contains('LIGHT')) {
      return RemoteCapabilityProfile.light;
    }
    return RemoteCapabilityProfile.genericIr;
  }

  static RemoteCapabilityProfile inferFromSwitchBotType(String deviceType) {
    final t = deviceType.toLowerCase();
    if (t.contains('air') || t.contains('ac')) {
      return RemoteCapabilityProfile.aircon;
    }
    if (t.contains('tv')) return RemoteCapabilityProfile.tv;
    if (t.contains('light')) return RemoteCapabilityProfile.light;
    if (t.contains('curtain') || t.contains('blind')) {
      return RemoteCapabilityProfile.curtain;
    }
    if (t == 'bot') return RemoteCapabilityProfile.bot;
    if (t.contains('plug')) return RemoteCapabilityProfile.plug;
    return RemoteCapabilityProfile.genericIr;
  }
}
