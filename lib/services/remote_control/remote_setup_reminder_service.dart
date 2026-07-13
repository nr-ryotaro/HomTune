import '../../models/device.dart';
import '../../models/remote_compatibility_assessment.dart';
import 'remote_compatibility_service.dart';
import 'remote_control_policy.dart';
import 'remote_setup_reminder_prefs.dart';

class RemoteSetupPendingDevice {
  final Device device;
  final RemoteCompatibilityAssessment assessment;

  const RemoteSetupPendingDevice({
    required this.device,
    required this.assessment,
  });
}

/// リモコン未設定の対象家電を列挙
class RemoteSetupReminderService {
  RemoteSetupReminderService._();
  static final RemoteSetupReminderService instance =
      RemoteSetupReminderService._();

  Future<List<RemoteSetupPendingDevice>> findPendingDevices(
    List<Device> devices,
  ) async {
    if (!RemoteControlPolicy.supportsRemoteControl) return [];

    final pending = <RemoteSetupPendingDevice>[];
    for (final device in devices) {
      if (device.remoteLink != null) continue;
      try {
        if (await RemoteSetupReminderPrefs.isSnoozed(device.id)) continue;

        final assessment = await RemoteCompatibilityService.instance.assess(
          modelNumber: device.modelNumber,
          category: device.category,
          manufacturer: device.manufacturer,
          archetypeId: device.archetypeId,
        );
        if (!assessment.isEligible) continue;

        pending.add(
          RemoteSetupPendingDevice(device: device, assessment: assessment),
        );
      } catch (_) {
        continue;
      }
    }
    return pending;
  }

  Future<RemoteSetupPendingDevice?> findPendingForDevice(Device device) async {
    final list = await findPendingDevices([device]);
    return list.isEmpty ? null : list.first;
  }
}
