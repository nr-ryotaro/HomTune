import 'package:flutter/material.dart';

import '../../../models/device_remote_link.dart';
import '../../../models/remote_appliance.dart';
import '../../../models/remote_ui_skin.dart';
import '../../../models/remote_ui_template.dart';
import '../remote_control_template_panel.dart';
import 'remote_button_index.dart';
import 'remote_physical_shell.dart';

/// テレビ物理リモコン風 UI（D-pad + ストリーミング色分け）
class TvPhysicalRemote extends StatelessWidget {
  final RemoteUiResolvedLayout layout;
  final RemoteSkinTheme theme;
  final DeviceRemoteLink? link;
  final bool sending;
  final bool interactive;
  final RemoteCommandCallback? onCommand;

  const TvPhysicalRemote({
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

    final hdmiButtons = index.byIds(['hdmi1', 'hdmi2', 'hdmi3', 'tv', 'google_tv']);
    final streaming = _streamingButtons(index, hdmiButtons);

    return RemotePhysicalShell(
      theme: theme,
      maxWidth: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                theme.brandLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: theme.darkBody ? theme.keyLabel : theme.accentColor,
                ),
              ),
              const Spacer(),
              if (index['power_on'] != null || index['power_off'] != null)
                RemotePowerKey(
                  theme: theme,
                  enabled: enabled,
                  onTap: () => _tap(index['power_on'] ?? index['power_off']!),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: _buildDpad(index, enabled),
          ),
          const SizedBox(height: 14),
          if (hdmiButtons.isNotEmpty) ...[
            Text(
              '入力切替',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.keyLabel.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (var i = 0; i < hdmiButtons.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: RemotePhysicalKey(
                      label: hdmiButtons[i].label,
                      icon: hdmiButtons[i].icon,
                      theme: theme,
                      enabled: enabled,
                      compact: true,
                      onTap: () => _tap(hdmiButtons[i]),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (streaming.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'アプリ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.keyLabel.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: streaming
                  .map(
                    (b) => SizedBox(
                      width: 118,
                      child: RemotePhysicalKey(
                        label: b.label,
                        icon: b.icon,
                        theme: theme,
                        enabled: enabled,
                        compact: true,
                        streaming: true,
                        streamingColor: streamingColorForLabel(b.label),
                        onTap: () => _tap(b),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  List<RemoteUiButtonDef> _streamingButtons(
    RemoteButtonIndex index,
    List<RemoteUiButtonDef> hdmiButtons,
  ) {
    for (final group in layout.groups) {
      if (group.id == 'streaming') return group.buttons;
    }
    final exclude = {
      'power_on',
      'power_off',
      'vol_up',
      'vol_down',
      'mute',
      'ch_up',
      'ch_down',
      ...hdmiButtons.map((b) => b.id),
    };
    return index.extras(excludeIds: exclude)
        .where((b) => b.commandType == RemoteCommandType.tvApp)
        .toList();
  }

  Widget _buildDpad(RemoteButtonIndex index, bool enabled) {
    Widget key(String? id, {IconData? fallbackIcon, String label = ''}) {
      final btn = id != null ? index[id] : null;
      if (btn == null && fallbackIcon == null) {
        return const SizedBox(width: 64, height: 44);
      }
      return SizedBox(
        width: 64,
        child: RemotePhysicalKey(
          label: label.isNotEmpty ? label : (btn?.label ?? ''),
          icon: btn?.icon ?? fallbackIcon,
          theme: theme,
          enabled: enabled && btn != null,
          compact: true,
          onTap: btn != null ? () => _tap(btn) : null,
        ),
      );
    }

    return Column(
      children: [
        key('ch_up', fallbackIcon: Icons.keyboard_arrow_up, label: 'CH'),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            key('vol_down', fallbackIcon: Icons.remove, label: 'VOL'),
            const SizedBox(width: 6),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.accentMuted.withValues(alpha: theme.darkBody ? 0.3 : 0.6),
                border: Border.all(color: theme.keyBorder),
              ),
              child: Icon(
                Icons.circle,
                size: 10,
                color: theme.keyLabel.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 6),
            key('vol_up', fallbackIcon: Icons.add, label: 'VOL'),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 64),
            const SizedBox(width: 6),
            key('mute', label: '消音'),
            const SizedBox(width: 6),
            const SizedBox(width: 64),
          ],
        ),
        const SizedBox(height: 4),
        key('ch_down', fallbackIcon: Icons.keyboard_arrow_down, label: 'CH'),
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
