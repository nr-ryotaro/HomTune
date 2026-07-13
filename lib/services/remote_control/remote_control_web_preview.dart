import '../../models/device.dart';
import '../../models/device_remote_link.dart';
import '../../utils/platform_support.dart';
import 'remote_compatibility_service.dart';
import 'remote_control_policy.dart';

/// Web（Netlify）向けリモコン UI プレビュー補助
class RemoteControlWebPreview {
  RemoteControlWebPreview._();

  static bool get isActive =>
      RemoteControlPolicy.simulatesCommands && PlatformSupport.isWebUiPreview;

  static Future<bool> isEligibleDevice(Device device) async {
    if (!isActive) return true;
    final assessment = await RemoteCompatibilityService.instance.assess(
      modelNumber: device.modelNumber,
      category: device.category,
      manufacturer: device.manufacturer,
      archetypeId: device.archetypeId,
    );
    return assessment.isEligible;
  }

  static DeviceRemoteLink demoLink({
    required Device device,
    required RemoteCapabilityProfile profile,
  }) {
    return DeviceRemoteLink(
      provider: RemoteProvider.remo,
      externalApplianceId: 'web-preview-${device.id}',
      externalNickname: device.customDisplayName?.isNotEmpty == true
          ? device.customDisplayName!
          : device.name,
      profile: profile,
      signalIds: _demoSignalIds(profile),
      linkedAt: DateTime.now().toIso8601String(),
    );
  }

  static Map<String, String> _demoSignalIds(RemoteCapabilityProfile profile) {
    switch (profile) {
      case RemoteCapabilityProfile.tv:
        return const {
          'netflix': 'demo-netflix',
          'youtube': 'demo-youtube',
          'prime': 'demo-prime',
          'hdmi1': 'demo-hdmi1',
          'hdmi2': 'demo-hdmi2',
        };
      case RemoteCapabilityProfile.aircon:
        return const {
          'timer': 'demo-timer',
          'swing': 'demo-swing',
          'nanoe': 'demo-nanoe',
        };
      default:
        return const {};
    }
  }

  static Future<RemoteCapabilityProfile?> profileFor(Device device) async {
    final assessment = await RemoteCompatibilityService.instance.assess(
      modelNumber: device.modelNumber,
      category: device.category,
      manufacturer: device.manufacturer,
      archetypeId: device.archetypeId,
    );
    if (!assessment.isEligible) return null;
    return assessment.profile;
  }

  static String commandPreviewMessage(
    String type, {
    String? signalId,
    Map<String, dynamic>? parameters,
  }) {
    final paramStr =
        parameters != null && parameters.isNotEmpty ? ' $parameters' : '';
    if (signalId != null) {
      return 'Webプレビュー: $type ($signalId$paramStr)';
    }
    return 'Webプレビュー: $type$paramStr（実機には送信されません）';
  }
}
