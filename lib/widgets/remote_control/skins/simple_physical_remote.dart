import 'package:flutter/material.dart';

import '../../../models/device_remote_link.dart';
import '../../../models/remote_ui_skin.dart';
import '../../../models/remote_ui_template.dart';
import '../remote_control_template_panel.dart';
import 'remote_button_index.dart';
import 'remote_physical_shell.dart';

/// Bot / カーテンなど単純操作向けの小型リモコン
class SimplePhysicalRemote extends StatelessWidget {
  final RemoteUiResolvedLayout layout;
  final RemoteSkinTheme theme;
  final DeviceRemoteLink? link;
  final bool sending;
  final bool interactive;
  final RemoteCommandCallback? onCommand;

  const SimplePhysicalRemote({
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
    final buttons = layout.groups.expand((g) => g.buttons).toList();
    final enabled = interactive && !sending;

    return RemotePhysicalShell(
      theme: theme,
      maxWidth: 240,
      child: Column(
        children: [
          Text(
            layout.templateLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: theme.keyLabel.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 16),
          if (buttons.length == 1)
            RemotePhysicalKey(
              label: buttons.first.label,
              icon: buttons.first.icon,
              theme: theme,
              enabled: enabled,
              accent: true,
              onTap: () => _tap(buttons.first),
            )
          else
            Row(
              children: [
                for (var i = 0; i < buttons.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: RemotePhysicalKey(
                      label: buttons[i].label,
                      icon: buttons[i].icon,
                      theme: theme,
                      enabled: enabled,
                      accent: buttons[i].variant == RemoteUiButtonVariant.primary,
                      onTap: () => _tap(buttons[i]),
                    ),
                  ),
                ],
              ],
            ),
          if (index['press'] != null && buttons.length > 1) ...[
            const SizedBox(height: 10),
            RemotePhysicalKey(
              label: index['press']!.label,
              icon: index['press']!.icon,
              theme: theme,
              enabled: enabled,
              onTap: () => _tap(index['press']!),
            ),
          ],
        ],
      ),
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
