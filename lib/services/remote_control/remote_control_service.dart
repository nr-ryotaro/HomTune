import 'package:flutter/foundation.dart';

import '../../models/device.dart';
import '../../models/device_remote_link.dart';
import '../../models/remote_appliance.dart';
import '../analytics_service.dart';
import '../config_service.dart';
import 'remote_api_client.dart';
import 'remote_command_intent_parser.dart';
import 'remote_control_policy.dart';

class RemoteControlService extends ChangeNotifier {
  RemoteControlService({RemoteApiClient? apiClient})
      : _api = apiClient ?? RemoteApiClient();

  final RemoteApiClient _api;

  IntegrationStatus? _remoStatus;
  IntegrationStatus? _switchbotStatus;
  List<RemoteAppliance> _cachedRemo = [];
  List<RemoteAppliance> _cachedSwitchBot = [];
  bool _loading = false;
  String? _error;

  IntegrationStatus? get remoStatus => _remoStatus;
  IntegrationStatus? get switchbotStatus => _switchbotStatus;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> refreshIntegrationStatus(ConfigService config) async {
    if (!RemoteControlPolicy.supportsRemoteControlApi) return;
    try {
      _remoStatus = await _api.getRemoStatus(config);
      _switchbotStatus = await _api.getSwitchBotStatus(config);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> linkRemo(ConfigService config, String token) async {
    _requirePro(config);
    _setLoading(true);
    try {
      await _api.linkRemo(config, token);
      await refreshIntegrationStatus(config);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> unlinkRemo(ConfigService config) async {
    await _api.unlinkRemo(config);
    _cachedRemo = [];
    await refreshIntegrationStatus(config);
  }

  Future<void> linkSwitchBot(
    ConfigService config, {
    required String token,
    required String secret,
  }) async {
    _requirePro(config);
    _setLoading(true);
    try {
      await _api.linkSwitchBot(config, token: token, secret: secret);
      await refreshIntegrationStatus(config);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> unlinkSwitchBot(ConfigService config) async {
    await _api.unlinkSwitchBot(config);
    _cachedSwitchBot = [];
    await refreshIntegrationStatus(config);
  }

  Future<List<RemoteAppliance>> fetchRemoAppliances(
    ConfigService config,
  ) async {
    _requirePro(config);
    _cachedRemo = await _api.listRemoAppliances(config);
    return _cachedRemo;
  }

  Future<List<RemoteAppliance>> fetchSwitchBotAppliances(
    ConfigService config,
  ) async {
    _requirePro(config);
    _cachedSwitchBot = await _api.listSwitchBotAppliances(config);
    return _cachedSwitchBot;
  }

  DeviceRemoteLink buildLinkFromAppliance(RemoteAppliance appliance) {
    final signalIds = <String, String>{};
    for (final s in appliance.signals) {
      final name = s.name.toLowerCase();
      if (name.contains('on') || name.contains('つけ')) {
        signalIds['powerOn'] = s.id;
      } else if (name.contains('off') || name.contains('消')) {
        signalIds['powerOff'] = s.id;
      }
    }

    return DeviceRemoteLink(
      provider: appliance.provider,
      externalApplianceId: appliance.id,
      externalNickname: appliance.nickname,
      hubDeviceId: appliance.hubDeviceId,
      profile: appliance.profile,
      signalIds: signalIds,
      linkedAt: DateTime.now().toIso8601String(),
    );
  }

  /// 紐付け前の安全なテスト送信（電源 OFF 等）
  Future<RemoteControlResult> sendTestCommandForAppliance(
    ConfigService config,
    Device device,
    RemoteAppliance appliance,
  ) async {
    _requirePro(config);
    final testType = _safeTestCommandType(appliance.profile);
    if (testType == null) {
      throw RemoteControlException('この家電は安全なテスト送信に対応していません');
    }

    final tempLink = buildLinkFromAppliance(appliance);
    final tempDevice = device.copyWith(remoteLink: tempLink);
    return sendCommand(config, tempDevice, testType);
  }

  RemoteCommandType? safeTestCommandType(RemoteCapabilityProfile profile) =>
      _safeTestCommandType(profile);

  RemoteCommandType? _safeTestCommandType(RemoteCapabilityProfile profile) {
    switch (profile) {
      case RemoteCapabilityProfile.aircon:
      case RemoteCapabilityProfile.tv:
      case RemoteCapabilityProfile.light:
      case RemoteCapabilityProfile.genericIr:
        return RemoteCommandType.powerOff;
      case RemoteCapabilityProfile.curtain:
      case RemoteCapabilityProfile.bot:
      case RemoteCapabilityProfile.plug:
        return null;
    }
  }

  Future<RemoteControlResult> sendCommand(
    ConfigService config,
    Device device,
    RemoteCommandType type, {
    String? signalId,
    Map<String, dynamic>? parameters,
  }) async {
    _requirePro(config);
    final link = device.remoteLink;
    if (link == null) {
      throw RemoteControlException('リモコンが紐付けされていません');
    }

    final resolvedSignalId = signalId ?? link.signalIds[_signalKeyForType(type)];
    if (type == RemoteCommandType.sendSignal &&
        (resolvedSignalId == null || resolvedSignalId.isEmpty)) {
      throw RemoteControlException('このボタンは学習済み信号の登録が必要です');
    }
    if ((type == RemoteCommandType.airconTimer ||
            type == RemoteCommandType.airconSwing ||
            type == RemoteCommandType.tvInput ||
            type == RemoteCommandType.tvApp) &&
        (resolvedSignalId == null || resolvedSignalId.isEmpty)) {
      throw RemoteControlException('Remo で信号を学習して紐付けてください');
    }

    final debounceKey = '${device.id}:${type.name}:$resolvedSignalId';
    if (!RemoteControlPolicy.canDebounceCommand(debounceKey)) {
      throw RemoteControlException('操作が早すぎます。少し待ってください');
    }

    final command = RemoteCommand(
      deviceId: device.id,
      provider: link.provider,
      externalApplianceId: link.externalApplianceId,
      type: type,
      signalId: resolvedSignalId,
      hubDeviceId: link.hubDeviceId,
      parameters: parameters,
    );

    final result = await _api.sendCommand(config, command);
    await AnalyticsService.logEvent(
      event: 'remote_command_sent',
      properties: {
        'provider': link.provider.name,
        'type': type.name,
        'deviceId': device.id,
        'success': result.success,
      },
    );
    await refreshIntegrationStatus(config);
    return result;
  }

  Future<String?> executeChatIntent(
    ConfigService config,
    String message,
    List<Device> devices,
  ) async {
    if (!RemoteControlPolicy.canUseRemoteControl(config)) {
      return 'リモコン操作は Pro プランで利用できます';
    }

    final intent = RemoteCommandIntentParser.parse(message, devices);
    if (intent == null) return null;

    try {
      final command = RemoteCommandIntentParser.toRemoteCommand(intent);
      final result = await _api.sendCommand(config, command);
      await AnalyticsService.logEvent(
        event: 'remote_command_sent',
        properties: {
          'source': 'chat',
          'type': intent.commandType.name,
          'deviceId': intent.device.id,
          'success': result.success,
        },
      );
      final name = intent.device.customDisplayName?.isNotEmpty == true
          ? intent.device.customDisplayName!
          : intent.device.name;
      return result.success
          ? '$name に操作を送信しました'
          : (result.message ?? '操作に失敗しました');
    } on RemoteApiException catch (e) {
      return 'リモコン操作エラー: ${e.message}';
    }
  }

  String? _signalKeyForType(RemoteCommandType type) {
    switch (type) {
      case RemoteCommandType.powerOn:
        return 'powerOn';
      case RemoteCommandType.powerOff:
        return 'powerOff';
      default:
        return null;
    }
  }

  void _requirePro(ConfigService config) {
    if (!RemoteControlPolicy.canUseRemoteControl(config)) {
      throw RemoteControlException('Proプランが必要です');
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}

class RemoteControlException implements Exception {
  final String message;
  const RemoteControlException(this.message);
  @override
  String toString() => message;
}
