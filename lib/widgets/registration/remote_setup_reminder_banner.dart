import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ai_usage_policy.dart';
import '../../models/device.dart';
import '../../screens/device_registration_remote_prompt_screen.dart';
import '../../screens/remote_account_screen.dart';
import '../../screens/remote_link_wizard_screen.dart';
import '../../services/analytics_service.dart';
import '../../services/config_service.dart';
import '../../services/remote_control/remote_control_policy.dart';
import '../../services/remote_control/remote_control_service.dart';
import '../../services/remote_control/remote_setup_reminder_prefs.dart';
import '../../services/remote_control/remote_setup_reminder_service.dart';
import '../ads/pro_upgrade_dialog.dart';

/// リモコン未設定の対象家電向けリマインダー
class RemoteSetupReminderBanner extends StatefulWidget {
  final Device? device;
  final List<Device>? allDevices;
  final String placement;

  const RemoteSetupReminderBanner({
    super.key,
    this.device,
    this.allDevices,
    required this.placement,
  }) : assert(device != null || allDevices != null);

  @override
  State<RemoteSetupReminderBanner> createState() =>
      _RemoteSetupReminderBannerState();
}

class _RemoteSetupReminderBannerState extends State<RemoteSetupReminderBanner> {
  RemoteSetupPendingDevice? _pending;
  bool _loading = true;
  bool _dismissed = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RemoteSetupReminderBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSignature = _deviceSignature(oldWidget);
    final newSignature = _deviceSignature(widget);
    if (oldSignature != newSignature) {
      _load();
    }
  }

  String _deviceSignature(RemoteSetupReminderBanner w) {
    if (w.device != null) {
      return '${w.device!.id}:${w.device!.remoteLink != null}';
    }
    final devices = w.allDevices ?? const <Device>[];
    return devices
        .map((d) => '${d.id}:${d.remoteLink != null}:${d.modelNumber}')
        .join('|');
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    if (!RemoteControlPolicy.supportsRemoteControl) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (mounted) setState(() => _loading = true);

    RemoteSetupPendingDevice? pending;
    try {
      if (widget.device != null) {
        pending = await RemoteSetupReminderService.instance
            .findPendingForDevice(widget.device!);
      } else {
        final list = await RemoteSetupReminderService.instance
            .findPendingDevices(widget.allDevices ?? const []);
        if (list.isNotEmpty) pending = list.first;
      }
    } catch (_) {
      pending = null;
    }

    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _pending = pending;
      _loading = false;
    });
  }

  Future<void> _onLater() async {
    final target = _pending?.device;
    if (target == null) return;
    await RemoteSetupReminderPrefs.snoozeDevice(target.id);
    await AnalyticsService.logEvent(
      event: 'remote_reminder_later',
      properties: {'deviceId': target.id, 'placement': widget.placement},
    );
    if (mounted) setState(() => _dismissed = true);
  }

  Future<void> _onSetup() async {
    final pending = _pending;
    if (pending == null) return;
    final targetDevice = pending.device;
    final navigator = Navigator.of(context);

    await AnalyticsService.logEvent(
      event: 'remote_reminder_tap',
      properties: {
        'deviceId': targetDevice.id,
        'placement': widget.placement,
      },
    );

    if (!mounted) return;

    final config = context.read<ConfigService>();
    final isPro = config.subscriptionTier == SubscriptionTier.pro;

    if (!isPro) {
      await showProUpgradeDialog(
        context,
        upsellContext: ProUpsellContext.remoteControl,
        deviceName: targetDevice.name,
        deviceCategoryLabel: pending.assessment.label,
      );
      return;
    }

    final remote = context.read<RemoteControlService>();
    try {
      await remote.refreshIntegrationStatus(config);
    } catch (_) {}

    final hasIntegration = remote.remoStatus?.linked == true ||
        remote.switchbotStatus?.linked == true;

    if (!mounted) return;

    if (!hasIntegration) {
      await navigator.push(
        MaterialPageRoute(builder: (_) => const RemoteAccountScreen()),
      );
    } else {
      final linked = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (_) => RemoteLinkWizardScreen(device: targetDevice),
        ),
      );
      if (linked == true) {
        await RemoteSetupReminderPrefs.clearSnooze(targetDevice.id);
      }
    }

    await _load();
  }

  Future<void> _onOpenPrompt() async {
    final pending = _pending;
    if (pending == null) return;
    final targetDevice = pending.device;
    final targetAssessment = pending.assessment;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => DeviceRegistrationRemotePromptScreen(
          device: targetDevice,
          assessment: targetAssessment,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _dismissed || _pending == null) {
      return const SizedBox.shrink();
    }

    final pending = _pending!;
    final label = pending.assessment.label ?? pending.device.category;
    final isHome = widget.device == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sensors, size: 20, color: Color(0xFF2563EB)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHome ? 'リモコン設定が未完了です' : 'リモコンを設定できます',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isHome
                            ? '${pending.device.name}（$label）ほか、スマートリモコン連携が可能です'
                            : '$label（${pending.device.modelNumber.isNotEmpty ? pending.device.modelNumber : pending.device.name}）を Remo / SwitchBot と紐付けられます',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: _onLater,
                  child: const Text('あとで'),
                ),
                const Spacer(),
                if (isHome)
                  TextButton(
                    onPressed: _onOpenPrompt,
                    child: const Text('詳細'),
                  ),
                FilledButton(
                  onPressed: _onSetup,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('今すぐ設定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
