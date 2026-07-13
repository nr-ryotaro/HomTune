import '../../models/device.dart';
import '../../models/remote_appliance.dart';
import '../device_query_matcher.dart';

class RemoteCommandIntent {
  final Device device;
  final RemoteCommandType commandType;
  final String? signalName;

  const RemoteCommandIntent({
    required this.device,
    required this.commandType,
    this.signalName,
  });
}

/// チャット等からの操作意図を解析
class RemoteCommandIntentParser {
  RemoteCommandIntentParser._();

  static const _powerOnPatterns = [
    'つけて',
    '付けて',
    'オン',
    'on',
    '起動',
    '電源入',
  ];
  static const _powerOffPatterns = [
    '消して',
    '消して',
    'オフ',
    'off',
    '止めて',
    '電源切',
  ];
  static const _tempUpPatterns = ['暖め', '暑く', '温度上', '上げて'];
  static const _tempDownPatterns = ['涼しく', '冷や', '温度下', '下げて'];
  static const _volumeUpPatterns = ['音量上', '大きく'];
  static const _volumeDownPatterns = ['音量下', '小さく'];

  static bool looksLikeRemoteCommand(String message) {
    final lower = message.toLowerCase();
    final verbs = [
      ..._powerOnPatterns,
      ..._powerOffPatterns,
      ..._tempUpPatterns,
      ..._tempDownPatterns,
      ..._volumeUpPatterns,
      ..._volumeDownPatterns,
      '操作',
      'リモコン',
    ];
    return verbs.any(lower.contains);
  }

  static RemoteCommandIntent? parse(String message, List<Device> devices) {
    if (!looksLikeRemoteCommand(message)) return null;

    final device = DeviceQueryMatcher.findRelevant(message, devices);
    if (device == null || device.remoteLink == null) return null;

    final lower = message.toLowerCase();
    RemoteCommandType? type;

    if (_powerOffPatterns.any(lower.contains)) {
      type = RemoteCommandType.powerOff;
    } else if (_powerOnPatterns.any(lower.contains)) {
      type = RemoteCommandType.powerOn;
    } else if (_tempUpPatterns.any(lower.contains)) {
      type = RemoteCommandType.tempUp;
    } else if (_tempDownPatterns.any(lower.contains)) {
      type = RemoteCommandType.tempDown;
    } else if (_volumeUpPatterns.any(lower.contains)) {
      type = RemoteCommandType.volumeUp;
    } else if (_volumeDownPatterns.any(lower.contains)) {
      type = RemoteCommandType.volumeDown;
    }

    if (type == null) return null;

    return RemoteCommandIntent(device: device, commandType: type);
  }

  static RemoteCommand toRemoteCommand(RemoteCommandIntent intent) {
    final link = intent.device.remoteLink!;
    String? signalId;

    if (intent.commandType == RemoteCommandType.sendSignal) {
      signalId = link.signalIds[intent.signalName ?? ''];
    } else if (intent.commandType == RemoteCommandType.powerOn) {
      signalId = link.signalIds['powerOn'];
    } else if (intent.commandType == RemoteCommandType.powerOff) {
      signalId = link.signalIds['powerOff'];
    }

    return RemoteCommand(
      deviceId: intent.device.id,
      provider: link.provider,
      externalApplianceId: link.externalApplianceId,
      type: intent.commandType,
      signalId: signalId,
      hubDeviceId: link.hubDeviceId,
    );
  }
}
