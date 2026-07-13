import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../models/device_remote_link.dart';
import '../../models/remote_appliance.dart';
import '../../models/remote_ui_template.dart';
import '../../services/remote_control/remote_ui_preferences_service.dart';
import '../../services/remote_control/remote_ui_template_service.dart';
import 'remote_control_template_panel.dart';
import 'remote_ui_customize_sheet.dart';

typedef RemoteCommandHandler = void Function(
  RemoteCommandType type, {
  String? signalId,
  Map<String, dynamic>? parameters,
});

/// リモコン操作 UI（テンプレートベース）
class RemoteControlPanel extends StatefulWidget {
  final bool isPro;
  final DeviceRemoteLink? link;
  final Device? device;
  final RemoteUiResolvedLayout? layoutOverride;
  final int? remainingMonthlyQuota;
  final bool sending;
  final bool interactive;
  final VoidCallback? onProTap;
  final VoidCallback? onLinkTap;
  final RemoteCommandHandler? onCommand;

  const RemoteControlPanel({
    super.key,
    required this.isPro,
    this.link,
    this.device,
    this.layoutOverride,
    this.remainingMonthlyQuota,
    this.sending = false,
    this.interactive = true,
    this.onProTap,
    this.onLinkTap,
    this.onCommand,
  });

  @override
  State<RemoteControlPanel> createState() => _RemoteControlPanelState();
}

class _RemoteControlPanelState extends State<RemoteControlPanel> {
  RemoteUiResolvedLayout? _layout;
  RemoteUiTemplate? _template;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLayout();
  }

  @override
  void didUpdateWidget(covariant RemoteControlPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device?.id != widget.device?.id ||
        oldWidget.device?.modelNumber != widget.device?.modelNumber ||
        oldWidget.link?.profile != widget.link?.profile ||
        oldWidget.layoutOverride != widget.layoutOverride) {
      _loadLayout();
    }
  }

  Future<void> _loadLayout() async {
    if (widget.layoutOverride != null) {
      setState(() {
        _layout = widget.layoutOverride;
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      RemoteUiResolvedLayout layout;
      RemoteUiTemplate template;
      if (widget.device != null) {
        layout = await RemoteUiTemplateService.instance
            .resolveLayoutForDevice(widget.device!);
        template = await RemoteUiTemplateService.instance.resolveTemplate(
          profile: widget.link?.profile ??
              DeviceRemoteLink.inferFromCategory(widget.device!.category),
          manufacturer: widget.device!.manufacturer,
          modelNumber: widget.device!.modelNumber,
        );
      } else if (widget.link != null) {
        template = await RemoteUiTemplateService.instance.resolveTemplate(
          profile: widget.link!.profile,
        );
        layout = await RemoteUiTemplateService.instance.resolveLayoutForProfile(
          profile: widget.link!.profile,
          deviceId: 'unknown',
        );
      } else {
        layout = const RemoteUiResolvedLayout(
          templateId: 'empty',
          templateLabel: '—',
          groups: [],
        );
        template = RemoteUiTemplate(
          id: 'empty',
          label: '—',
          profile: RemoteCapabilityProfile.genericIr,
          groups: const [],
        );
      }
      if (!mounted) return;
      setState(() {
        _layout = layout;
        _template = template;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCustomize() async {
    final device = widget.device;
    final template = _template;
    if (device == null || template == null || _layout == null) return;

    final prefs = await RemoteUiPreferencesService.instance.load(
      device.id,
      template,
    );
    if (!mounted) return;

    final updated = await RemoteUiCustomizeSheet.show(
      context,
      deviceId: device.id,
      template: template,
      initialPrefs: prefs,
    );
    if (updated != null) await _loadLayout();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Remote Control',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'リモコン',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        if (!widget.isPro)
          _buildProLock()
        else if (widget.link == null)
          _buildUnlinked()
        else
          _buildLinkedPanel(),
      ],
    );
  }

  Widget _buildProLock() {
    return OutlinedButton.icon(
      onPressed: widget.interactive ? widget.onProTap : null,
      icon: const Icon(Icons.lock_outline, size: 18),
      label: const Text('Proでリモコン操作'),
    );
  }

  Widget _buildUnlinked() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Remo / SwitchBot と紐付けると、この家電を操作できます。',
          style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: widget.interactive ? widget.onLinkTap : null,
          icon: const Icon(Icons.link, size: 18),
          label: const Text('リモコンを紐付ける'),
        ),
      ],
    );
  }

  Widget _buildLinkedPanel() {
    final link = widget.link!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                link.provider == RemoteProvider.remo
                    ? Icons.sensors
                    : Icons.smart_toy_outlined,
                size: 18,
                color: const Color(0xFF333333),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  link.externalNickname ?? '連携済み',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (widget.remainingMonthlyQuota != null)
                Text(
                  '残り ${widget.remainingMonthlyQuota} 回/月',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_layout != null)
            RemoteControlTemplatePanel(
              layout: _layout!,
              link: link,
              sending: widget.sending,
              interactive: widget.interactive,
              onCommand: widget.onCommand,
              onCustomize:
                  widget.device != null && widget.interactive ? _openCustomize : null,
            ),
        ],
      ),
    );
  }
}