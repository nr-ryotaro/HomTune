import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ai_usage_policy.dart';
import '../../models/device.dart';
import '../../models/device_remote_link.dart';
import '../../models/remote_appliance.dart';
import '../../screens/remote_control_preview_screen.dart';
import '../../screens/remote_link_wizard_screen.dart';
import '../../services/config_service.dart';
import '../../services/device_service.dart';
import '../../services/remote_control/remote_control_policy.dart';
import '../../services/remote_control/remote_control_service.dart';
import '../../services/remote_control/remote_control_web_preview.dart';
import '../ads/pro_upgrade_dialog.dart';
import '../remote_control/remote_control_panel.dart';

class RemoteControlSection extends StatefulWidget {
  final Device device;

  const RemoteControlSection({super.key, required this.device});

  @override
  State<RemoteControlSection> createState() => _RemoteControlSectionState();
}

class _RemoteControlSectionState extends State<RemoteControlSection> {
  bool _sending = false;

  Device get _device {
    final svc = Provider.of<DeviceService>(context, listen: false);
    return svc.getDeviceById(widget.device.id) ?? widget.device;
  }

  Future<void> _runCommand(
    RemoteCommandType type, {
    String? signalId,
    Map<String, dynamic>? parameters,
  }) async {
    if (_sending) return;
    setState(() => _sending = true);

    if (RemoteControlWebPreview.isActive) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              RemoteControlWebPreview.commandPreviewMessage(
                type.name,
                signalId: signalId,
                parameters: parameters,
              ),
            ),
          ),
        );
      }
      if (mounted) setState(() => _sending = false);
      return;
    }

    final config = Provider.of<ConfigService>(context, listen: false);
    final remote = Provider.of<RemoteControlService>(context, listen: false);

    try {
      final result = await remote.sendCommand(
        config,
        _device,
        type,
        signalId: signalId,
        parameters: parameters,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                (result.success ? '操作を送信しました' : '操作に失敗しました'),
          ),
        ),
      );
    } on RemoteControlException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!RemoteControlPolicy.supportsRemoteControlUi) {
      return const SizedBox.shrink();
    }

    if (RemoteControlWebPreview.isActive) {
      return FutureBuilder<bool>(
        future: RemoteControlWebPreview.isEligibleDevice(_device),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          if (snapshot.data != true) {
            return const SizedBox.shrink();
          }
          return _buildPanel(
            device: _device,
            isPro: true,
            linkFuture: _resolveWebLink(_device),
          );
        },
      );
    }

    return Consumer2<ConfigService, DeviceService>(
      builder: (context, config, deviceService, _) {
        final device = deviceService.getDeviceById(widget.device.id) ?? widget.device;
        final isPro = config.subscriptionTier == SubscriptionTier.pro;
        final link = device.remoteLink;
        final remote = Provider.of<RemoteControlService>(context);
        final quota = remote.remoStatus?.remainingMonthlyQuota ??
            remote.switchbotStatus?.remainingMonthlyQuota;

        return _buildPanel(
          device: device,
          isPro: isPro,
          link: link,
          remainingMonthlyQuota: quota,
        );
      },
    );
  }

  Future<DeviceRemoteLink?> _resolveWebLink(Device device) async {
    if (device.remoteLink != null) return device.remoteLink;
    final profile = await RemoteControlWebPreview.profileFor(device);
    if (profile == null) return null;
    return RemoteControlWebPreview.demoLink(device: device, profile: profile);
  }

  Widget _buildPanel({
    required Device device,
    required bool isPro,
    DeviceRemoteLink? link,
    Future<DeviceRemoteLink?>? linkFuture,
    int? remainingMonthlyQuota,
  }) {
    final panel = RemoteControlPanel(
      isPro: isPro,
      device: device,
      link: link,
      remainingMonthlyQuota: remainingMonthlyQuota,
      sending: _sending,
      onProTap: () => showProUpgradeDialog(context),
      onLinkTap: RemoteControlWebPreview.isActive
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RemoteControlPreviewScreen(),
                ),
              );
            }
          : () async {
              final linked = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => RemoteLinkWizardScreen(device: device),
                ),
              );
              if (linked == true && mounted) setState(() {});
            },
      onCommand: _runCommand,
    );

    final content = linkFuture != null
        ? FutureBuilder<DeviceRemoteLink?>(
            future: linkFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done ||
                  snapshot.data == null) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return RemoteControlPanel(
                isPro: isPro,
                device: device,
                link: snapshot.data,
                sending: _sending,
                onProTap: () => showProUpgradeDialog(context),
                onLinkTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RemoteControlPreviewScreen(),
                    ),
                  );
                },
                onCommand: _runCommand,
              );
            },
          )
        : panel;

    if (!RemoteControlWebPreview.isActive) {
      return content;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.settings_remote, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Webプレビュー — ボタン操作は表示のみ（実機には送信されません）',
                  style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RemoteControlPreviewScreen(),
                    ),
                  );
                },
                child: const Text('一覧', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
        content,
      ],
    );
  }
}
