import 'package:flutter/material.dart';

import '../../models/device_remote_link.dart';
import '../../models/remote_appliance.dart';
import '../../models/remote_ui_skin.dart';
import '../../models/remote_ui_template.dart';
import 'skins/aircon_physical_remote.dart';
import 'skins/light_physical_remote.dart';
import 'skins/simple_physical_remote.dart';
import 'skins/tv_physical_remote.dart';

typedef RemoteCommandCallback = void Function(
  RemoteCommandType type, {
  String? signalId,
  Map<String, dynamic>? parameters,
});

/// メーカーテンプレートに基づくリモコンボタン UI
class RemoteControlTemplatePanel extends StatelessWidget {
  final RemoteUiResolvedLayout layout;
  final DeviceRemoteLink? link;
  final bool sending;
  final bool interactive;
  final RemoteCommandCallback? onCommand;
  final VoidCallback? onCustomize;

  const RemoteControlTemplatePanel({
    super.key,
    required this.layout,
    this.link,
    this.sending = false,
    this.interactive = true,
    this.onCommand,
    this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = RemoteSkinTheme.forTemplate(
      layout.templateId,
      themeKey: layout.themeKey,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                layout.templateLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              layout.skin == RemoteUiSkinType.grid
                  ? Icons.grid_view
                  : Icons.settings_remote,
              size: 14,
              color: const Color(0xFF94A3B8),
            ),
            const Spacer(),
            if (onCustomize != null && interactive)
              TextButton.icon(
                onPressed: onCustomize,
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('カスタマイズ'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildRemoteBody(theme),
        if (sending)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  Widget _buildRemoteBody(RemoteSkinTheme theme) {
    switch (layout.skin) {
      case RemoteUiSkinType.physicalAircon:
        return AirconPhysicalRemote(
          layout: layout,
          theme: theme,
          link: link,
          sending: sending,
          interactive: interactive,
          onCommand: onCommand,
        );
      case RemoteUiSkinType.physicalTv:
        return TvPhysicalRemote(
          layout: layout,
          theme: theme,
          link: link,
          sending: sending,
          interactive: interactive,
          onCommand: onCommand,
        );
      case RemoteUiSkinType.physicalLight:
        return LightPhysicalRemote(
          layout: layout,
          theme: theme,
          link: link,
          sending: sending,
          interactive: interactive,
          onCommand: onCommand,
        );
      case RemoteUiSkinType.physicalSimple:
        return SimplePhysicalRemote(
          layout: layout,
          theme: theme,
          link: link,
          sending: sending,
          interactive: interactive,
          onCommand: onCommand,
        );
      case RemoteUiSkinType.grid:
        return _GridRemoteLayout(
          layout: layout,
          link: link,
          sending: sending,
          interactive: interactive,
          onCommand: onCommand,
        );
    }
  }
}

class _GridRemoteLayout extends StatelessWidget {
  final RemoteUiResolvedLayout layout;
  final DeviceRemoteLink? link;
  final bool sending;
  final bool interactive;
  final RemoteCommandCallback? onCommand;

  const _GridRemoteLayout({
    required this.layout,
    this.link,
    this.sending = false,
    this.interactive = true,
    this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (layout.pinnedButtons.isNotEmpty) ...[
          const Text(
            'よく使う',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: layout.pinnedButtons
                  .map((b) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildButton(b, compact: true),
                      ))
                  .toList(),
            ),
          ),
        ],
        for (final group in layout.groups) ...[
          const SizedBox(height: 16),
          Text(
            group.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.buttons.map(_buildButton).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildButton(RemoteUiButtonDef button, {bool compact = false}) {
    final enabled = interactive && !sending;
    final colors = _colorsForVariant(button.variant);

    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(compact ? 20 : 12),
      child: InkWell(
        onTap: enabled ? () => _handleTap(button) : null,
        borderRadius: BorderRadius.circular(compact ? 20 : 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 8 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 20 : 12),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(button.icon, size: compact ? 16 : 18, color: colors.icon),
              const SizedBox(width: 6),
              Text(
                button.label,
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: colors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(RemoteUiButtonDef button) {
    final signalId = _resolveSignalId(button);
    onCommand?.call(
      button.commandType,
      signalId: signalId,
      parameters: button.parameters,
    );
  }

  String? _resolveSignalId(RemoteUiButtonDef button) {
    if (button.signalKey == null || link == null) return null;
    return link!.signalIds[button.signalKey!];
  }

  _ButtonColors _colorsForVariant(RemoteUiButtonVariant variant) {
    switch (variant) {
      case RemoteUiButtonVariant.primary:
        return const _ButtonColors(
          background: Color(0xFF1E293B),
          border: Color(0xFF1E293B),
          icon: Colors.white,
          text: Colors.white,
        );
      case RemoteUiButtonVariant.danger:
        return const _ButtonColors(
          background: Color(0xFFFFF1F2),
          border: Color(0xFFFECACA),
          icon: Color(0xFFB91C1C),
          text: Color(0xFFB91C1C),
        );
      case RemoteUiButtonVariant.cool:
        return const _ButtonColors(
          background: Color(0xFFEFF6FF),
          border: Color(0xFFBFDBFE),
          icon: Color(0xFF2563EB),
          text: Color(0xFF1D4ED8),
        );
      case RemoteUiButtonVariant.warm:
        return const _ButtonColors(
          background: Color(0xFFFFF7ED),
          border: Color(0xFFFED7AA),
          icon: Color(0xFFEA580C),
          text: Color(0xFFC2410C),
        );
      case RemoteUiButtonVariant.dry:
        return const _ButtonColors(
          background: Color(0xFFECFEFF),
          border: Color(0xFFA5F3FC),
          icon: Color(0xFF0891B2),
          text: Color(0xFF0E7490),
        );
      case RemoteUiButtonVariant.fan:
        return const _ButtonColors(
          background: Color(0xFFF0FDF4),
          border: Color(0xFFBBF7D0),
          icon: Color(0xFF16A34A),
          text: Color(0xFF15803D),
        );
      case RemoteUiButtonVariant.standard:
        return const _ButtonColors(
          background: Colors.white,
          border: Color(0xFFE2E8F0),
          icon: Color(0xFF334155),
          text: Color(0xFF334155),
        );
    }
  }
}

class _ButtonColors {
  final Color background;
  final Color border;
  final Color icon;
  final Color text;

  const _ButtonColors({
    required this.background,
    required this.border,
    required this.icon,
    required this.text,
  });
}
