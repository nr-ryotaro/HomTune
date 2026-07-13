import 'package:flutter/material.dart';

import '../../../models/device_remote_link.dart';
import '../../../models/remote_ui_skin.dart';
import '../../../models/remote_ui_template.dart';
import '../remote_control_template_panel.dart';
import 'remote_button_index.dart';
import 'remote_physical_shell.dart';

/// エアコン物理リモコン風 UI
class AirconPhysicalRemote extends StatelessWidget {
  final RemoteUiResolvedLayout layout;
  final RemoteSkinTheme theme;
  final DeviceRemoteLink? link;
  final bool sending;
  final bool interactive;
  final RemoteCommandCallback? onCommand;

  const AirconPhysicalRemote({
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

    final modeIds = ['cool', 'warm', 'dry', 'fan', 'auto'];
    final modeButtons = index.byIds(modeIds);
    final usedIds = {
      ...modeIds,
      'power_off',
      'power_on',
      'temp_up',
      'temp_down',
    };
    final extras = index.extras(excludeIds: usedIds);

    final lcdMode = modeButtons.isNotEmpty ? modeButtons.first.label : '待機中';
    final lcdSub = layout.templateLabel;

    return RemotePhysicalShell(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                theme.brandLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: theme.darkBody ? theme.keyLabel : theme.accentColor,
                ),
              ),
              const Spacer(),
              if (index['power_off'] != null || index['power_on'] != null)
                RemotePowerKey(
                  theme: theme,
                  enabled: enabled,
                  onTap: () => _tap(index['power_off'] ?? index['power_on']!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          RemoteLcdDisplay(
            theme: theme,
            line1: '26°C',
            line2: '$lcdMode  ·  $lcdSub',
          ),
          const SizedBox(height: 16),
          if (modeButtons.isNotEmpty)
            Row(
              children: [
                for (var i = 0; i < modeButtons.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: RemotePhysicalKey(
                      label: _shortModeLabel(modeButtons[i].label),
                      icon: modeButtons[i].icon,
                      theme: theme,
                      enabled: enabled,
                      compact: true,
                      accent: _isModeAccent(modeButtons[i].variant),
                      onTap: () => _tap(modeButtons[i]),
                    ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    if (index['temp_up'] != null)
                      RemotePhysicalKey(
                        label: '温度',
                        icon: Icons.keyboard_arrow_up,
                        theme: theme,
                        enabled: enabled,
                        accent: true,
                        onTap: () => _tap(index['temp_up']!),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.accentMuted.withValues(
                          alpha: theme.darkBody ? 0.25 : 0.55,
                        ),
                        border: Border.all(
                          color: theme.accentColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        '26',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: theme.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (index['temp_down'] != null)
                      RemotePhysicalKey(
                        label: '温度',
                        icon: Icons.keyboard_arrow_down,
                        theme: theme,
                        enabled: enabled,
                        accent: true,
                        onTap: () => _tap(index['temp_down']!),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth =
                        constraints.maxWidth > 0 ? (constraints.maxWidth - 6) / 2 : 72.0;
                    return Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: extras
                          .map(
                            (b) => SizedBox(
                              width: itemWidth,
                              child: RemotePhysicalKey(
                                label: b.label,
                                icon: b.icon,
                                theme: theme,
                                enabled: enabled,
                                compact: true,
                                onTap: () => _tap(b),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _shortModeLabel(String label) {
    if (label.length <= 3) return label;
    return label.replaceAll('房', '').replaceAll('湿', '除湿').replaceAll('風', '送風');
  }

  bool _isModeAccent(RemoteUiButtonVariant variant) {
    return variant == RemoteUiButtonVariant.cool ||
        variant == RemoteUiButtonVariant.warm ||
        variant == RemoteUiButtonVariant.dry ||
        variant == RemoteUiButtonVariant.fan;
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
