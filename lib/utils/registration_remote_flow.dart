import 'package:flutter/material.dart';

import '../models/device.dart';
import '../models/remote_compatibility_assessment.dart';
import '../screens/device_registration_remote_prompt_screen.dart';
import '../services/remote_control/remote_compatibility_service.dart';
import '../services/remote_control/remote_control_policy.dart';

/// 登録完了後にリモコン設定プロンプトを表示（対象家電のみ）
Future<void> maybeShowRemoteRegistrationPrompt(
  BuildContext context, {
  required Device device,
  RemoteCompatibilityAssessment? assessment,
}) async {
  if (!RemoteControlPolicy.supportsRemoteControl) return;

  RemoteCompatibilityAssessment resolved;
  try {
    resolved = assessment ??
        await RemoteCompatibilityService.instance.assess(
          modelNumber: device.modelNumber,
          category: device.category,
          manufacturer: device.manufacturer,
          archetypeId: device.archetypeId,
        );
  } catch (_) {
    return;
  }

  if (!resolved.shouldPromptOnRegistration) return;
  if (!context.mounted) return;

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => DeviceRegistrationRemotePromptScreen(
        device: device,
        assessment: resolved,
      ),
    ),
  );
}
