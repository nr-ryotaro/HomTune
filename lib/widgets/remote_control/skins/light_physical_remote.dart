import 'package:flutter/material.dart';

import '../../../models/device_remote_link.dart';
import '../../../models/remote_ui_skin.dart';
import '../../../models/remote_ui_template.dart';
import '../remote_control_template_panel.dart';
import 'remote_button_index.dart';
import 'remote_physical_shell.dart';

/// 照明リモコン風 UI（シンプルな横長ボディ）
class LightPhysicalRemote extends StatelessWidget {
  final RemoteUiResolvedLayout layout;
  final RemoteSkinTheme theme;
  final DeviceRemoteLink? link;
  final bool sending;
  final bool interactive;
  final RemoteCommandCallback? onCommand;

  const LightPhysicalRemote({
    super.key,
    required this.layout,
    required this.theme,
    this.link,
    this.sending = false,
    this.interactive = true,
    this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    final index = RemoteButtonIndex(layout);
    final enabled = interactive && !sending;
    final on = index['power_on'];
    final off = index['power_off'];

    return RemotePhysicalShell(
      theme: theme,
      maxWidth: 260,
      child: Column(
        children: [
          Text(
            'LIGHTING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: theme.keyLabel.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (on != null)
                _roundToggle(
                  label: on.label,
                  icon: Icons.lightbulb,
                  active: true,
                  enabled: enabled,
                  onTap: () => _tap(on),
                ),
              if (on != null && off != null) const SizedBox(width: 20),
              if (off != null)
                _roundToggle(
                  label: off.label,
                  icon: Icons.lightbulb_outline,
                  active: false,
                  enabled: enabled,
                  onTap: () => _tap(off),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundToggle({
    required String label,
    required IconData icon,
    required bool active,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final color = active ? const Color(0xFFFBBF24) : theme.keyLabel;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            customBorder: const CircleBorder(),
            child: AnimatedOpacity(
              opacity: enabled ? 1 : 0.45,
              duration: const Duration(milliseconds: 120),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? const Color(0xFFFEF3C7)
                      : theme.keyFace,
                  border: Border.all(
                    color: active ? const Color(0xFFF59E0B) : theme.keyBorder,
                    width: active ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 32),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.keyLabel,
          ),
        ),
      ],
    );
  }

  void _tap(RemoteUiButtonDef button) {
    final signalId = button.signalKey != null && link != null
        ? link!.signalIds[button.signalKey!]
        : null;
    onCommand?.call(
      button.commandType,
      signalId: signalId,
      parameters: button.parameters,
    );
  }
}
