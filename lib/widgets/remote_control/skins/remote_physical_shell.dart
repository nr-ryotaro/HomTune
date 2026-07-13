import 'package:flutter/material.dart';

import '../../../models/remote_ui_skin.dart';

/// 物理リモコンの外殻（グラデーション本体・ブランド帯）
class RemotePhysicalShell extends StatelessWidget {
  final RemoteSkinTheme theme;
  final Widget child;
  final double maxWidth;

  const RemotePhysicalShell({
    super.key,
    required this.theme,
    required this.child,
    this.maxWidth = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [theme.bodyTop, theme.bodyBottom],
            ),
            border: Border.all(color: theme.borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// 押し込み感のある物理キー
class RemotePhysicalKey extends StatelessWidget {
  final String label;
  final IconData? icon;
  final RemoteSkinTheme theme;
  final bool enabled;
  final bool compact;
  final bool accent;
  final bool danger;
  final bool streaming;
  final Color? streamingColor;
  final VoidCallback? onTap;

  const RemotePhysicalKey({
    super.key,
    required this.label,
    this.icon,
    required this.theme,
    this.enabled = true,
    this.compact = false,
    this.accent = false,
    this.danger = false,
    this.streaming = false,
    this.streamingColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final face = danger
        ? const Color(0xFFFFF1F2)
        : streaming
            ? (streamingColor ?? theme.accentColor).withValues(alpha: 0.15)
            : accent
                ? theme.accentMuted.withValues(alpha: theme.darkBody ? 0.35 : 1)
                : theme.keyFace;
    final border = danger
        ? const Color(0xFFFECACA)
        : streaming
            ? (streamingColor ?? theme.accentColor).withValues(alpha: 0.5)
            : accent
                ? theme.accentColor.withValues(alpha: 0.45)
                : theme.keyBorder;
    final labelColor = danger
        ? theme.powerColor
        : streaming
            ? (streamingColor ?? theme.accentColor)
            : theme.keyLabel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: enabled ? 1 : 0.45,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 10,
              vertical: compact ? 6 : 11,
            ),
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(compact ? 10 : 12),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: theme.darkBody ? 0.35 : 0.08),
                  blurRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: compact ? 15 : 18, color: labelColor),
                  if (label.isNotEmpty) SizedBox(height: compact ? 2 : 4),
                ],
                if (label.isNotEmpty)
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 9 : 11,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                      height: 1.0,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 丸型電源キー
class RemotePowerKey extends StatelessWidget {
  final RemoteSkinTheme theme;
  final bool enabled;
  final VoidCallback? onTap;

  const RemotePowerKey({
    super.key,
    required this.theme,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: enabled ? 1 : 0.45,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.powerColor.withValues(alpha: 0.12),
              border: Border.all(color: theme.powerColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: theme.powerColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.power_settings_new, color: theme.powerColor, size: 26),
          ),
        ),
      ),
    );
  }
}

/// 擬似 LCD ディスプレイ
class RemoteLcdDisplay extends StatelessWidget {
  final RemoteSkinTheme theme;
  final String line1;
  final String line2;

  const RemoteLcdDisplay({
    super.key,
    required this.theme,
    required this.line1,
    this.line2 = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.lcdBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.darkBody
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line1,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.lcdText,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 1.2,
            ),
          ),
          if (line2.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              line2,
              style: TextStyle(
                fontSize: 11,
                color: theme.lcdText.withValues(alpha: 0.85),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Color streamingColorForLabel(String label) {
  final lower = label.toLowerCase();
  if (lower.contains('netflix')) return const Color(0xFFE50914);
  if (lower.contains('youtube')) return const Color(0xFFFF0000);
  if (lower.contains('prime')) return const Color(0xFF00A8E1);
  if (lower.contains('disney')) return const Color(0xFF113CCF);
  if (lower.contains('google')) return const Color(0xFF34A853);
  return const Color(0xFF6366F1);
}
