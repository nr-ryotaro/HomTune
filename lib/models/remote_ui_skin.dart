import 'package:flutter/material.dart';

/// リモコン UI の描画スタイル
enum RemoteUiSkinType {
  grid,
  physicalAircon,
  physicalTv,
  physicalLight,
  physicalSimple,
}

RemoteUiSkinType remoteUiSkinTypeFromJson(String? raw) {
  if (raw == null || raw.isEmpty) return RemoteUiSkinType.grid;
  return RemoteUiSkinType.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => RemoteUiSkinType.grid,
  );
}

/// メーカー別の物理リモコン配色・ブランド表現
class RemoteSkinTheme {
  final String brandLabel;
  final Color bodyTop;
  final Color bodyBottom;
  final Color borderColor;
  final Color accentColor;
  final Color accentMuted;
  final Color lcdBackground;
  final Color lcdText;
  final Color keyFace;
  final Color keyBorder;
  final Color keyLabel;
  final Color powerColor;
  final bool darkBody;

  const RemoteSkinTheme({
    required this.brandLabel,
    required this.bodyTop,
    required this.bodyBottom,
    required this.borderColor,
    required this.accentColor,
    required this.accentMuted,
    required this.lcdBackground,
    required this.lcdText,
    required this.keyFace,
    required this.keyBorder,
    required this.keyLabel,
    required this.powerColor,
    this.darkBody = false,
  });

  static RemoteSkinTheme forTemplate(String templateId, {String themeKey = ''}) {
    final key = themeKey.isNotEmpty ? themeKey : _themeKeyFromTemplateId(templateId);
    switch (key) {
      case 'panasonic':
        return panasonic;
      case 'daikin':
        return daikin;
      case 'mitsubishi':
        return mitsubishi;
      case 'hitachi':
        return hitachi;
      case 'toshiba':
        return toshiba;
      case 'sony':
        return sony;
      case 'sharp':
        return sharp;
      default:
        return generic;
    }
  }

  static String _themeKeyFromTemplateId(String templateId) {
    if (templateId.contains('panasonic')) return 'panasonic';
    if (templateId.contains('daikin')) return 'daikin';
    if (templateId.contains('mitsubishi')) return 'mitsubishi';
    if (templateId.contains('hitachi')) return 'hitachi';
    if (templateId.contains('toshiba')) return 'toshiba';
    if (templateId.contains('sony')) return 'sony';
    if (templateId.contains('sharp')) return 'sharp';
    if (templateId.contains('viera')) return 'panasonic';
    if (templateId.contains('aquos')) return 'sharp';
    if (templateId.contains('regza')) return 'toshiba';
    if (templateId.contains('bravia')) return 'sony';
    return 'generic';
  }

  static const panasonic = RemoteSkinTheme(
    brandLabel: 'Panasonic',
    bodyTop: Color(0xFFF8FAFC),
    bodyBottom: Color(0xFFE8EDF2),
    borderColor: Color(0xFFCBD5E1),
    accentColor: Color(0xFF0EA5E9),
    accentMuted: Color(0xFFBAE6FD),
    lcdBackground: Color(0xFF1E293B),
    lcdText: Color(0xFF7DD3FC),
    keyFace: Color(0xFFFFFFFF),
    keyBorder: Color(0xFFD1D5DB),
    keyLabel: Color(0xFF334155),
    powerColor: Color(0xFFDC2626),
  );

  static const daikin = RemoteSkinTheme(
    brandLabel: 'DAIKIN',
    bodyTop: Color(0xFFF0F9FF),
    bodyBottom: Color(0xFFE0F2FE),
    borderColor: Color(0xFF93C5FD),
    accentColor: Color(0xFF0284C7),
    accentMuted: Color(0xFFBFDBFE),
    lcdBackground: Color(0xFF0C4A6E),
    lcdText: Color(0xFF38BDF8),
    keyFace: Color(0xFFFFFFFF),
    keyBorder: Color(0xFFBAE6FD),
    keyLabel: Color(0xFF0C4A6E),
    powerColor: Color(0xFFDC2626),
  );

  static const mitsubishi = RemoteSkinTheme(
    brandLabel: 'MITSUBISHI',
    bodyTop: Color(0xFFFFF5F5),
    bodyBottom: Color(0xFFFEE2E2),
    borderColor: Color(0xFFFECACA),
    accentColor: Color(0xFFDC2626),
    accentMuted: Color(0xFFFECACA),
    lcdBackground: Color(0xFF450A0A),
    lcdText: Color(0xFFF87171),
    keyFace: Color(0xFFFFFFFF),
    keyBorder: Color(0xFFFECACA),
    keyLabel: Color(0xFF7F1D1D),
    powerColor: Color(0xFFB91C1C),
  );

  static const hitachi = RemoteSkinTheme(
    brandLabel: 'HITACHI',
    bodyTop: Color(0xFFF8FAFC),
    bodyBottom: Color(0xFFE2E8F0),
    borderColor: Color(0xFFCBD5E1),
    accentColor: Color(0xFFDC2626),
    accentMuted: Color(0xFFE2E8F0),
    lcdBackground: Color(0xFF1E293B),
    lcdText: Color(0xFF94A3B8),
    keyFace: Color(0xFFFFFFFF),
    keyBorder: Color(0xFFCBD5E1),
    keyLabel: Color(0xFF334155),
    powerColor: Color(0xFFDC2626),
  );

  static const toshiba = RemoteSkinTheme(
    brandLabel: 'TOSHIBA',
    bodyTop: Color(0xFFF9FAFB),
    bodyBottom: Color(0xFFE5E7EB),
    borderColor: Color(0xFFD1D5DB),
    accentColor: Color(0xFFDC2626),
    accentMuted: Color(0xFFE5E7EB),
    lcdBackground: Color(0xFF111827),
    lcdText: Color(0xFFF87171),
    keyFace: Color(0xFFFFFFFF),
    keyBorder: Color(0xFFD1D5DB),
    keyLabel: Color(0xFF374151),
    powerColor: Color(0xFFDC2626),
  );

  static const sony = RemoteSkinTheme(
    brandLabel: 'BRAVIA',
    bodyTop: Color(0xFF1F2937),
    bodyBottom: Color(0xFF111827),
    borderColor: Color(0xFF374151),
    accentColor: Color(0xFFF8FAFC),
    accentMuted: Color(0xFF4B5563),
    lcdBackground: Color(0xFF030712),
    lcdText: Color(0xFF9CA3AF),
    keyFace: Color(0xFF374151),
    keyBorder: Color(0xFF4B5563),
    keyLabel: Color(0xFFF9FAFB),
    powerColor: Color(0xFFEF4444),
    darkBody: true,
  );

  static const sharp = RemoteSkinTheme(
    brandLabel: 'AQUOS',
    bodyTop: Color(0xFFEFF6FF),
    bodyBottom: Color(0xFFDBEAFE),
    borderColor: Color(0xFF93C5FD),
    accentColor: Color(0xFF2563EB),
    accentMuted: Color(0xFFBFDBFE),
    lcdBackground: Color(0xFF1E3A8A),
    lcdText: Color(0xFF93C5FD),
    keyFace: Color(0xFFFFFFFF),
    keyBorder: Color(0xFFBFDBFE),
    keyLabel: Color(0xFF1E40AF),
    powerColor: Color(0xFFDC2626),
  );

  static const generic = RemoteSkinTheme(
    brandLabel: 'REMOTE',
    bodyTop: Color(0xFFF8FAFC),
    bodyBottom: Color(0xFFE2E8F0),
    borderColor: Color(0xFFCBD5E1),
    accentColor: Color(0xFF475569),
    accentMuted: Color(0xFFE2E8F0),
    lcdBackground: Color(0xFF1E293B),
    lcdText: Color(0xFF94A3B8),
    keyFace: Color(0xFFFFFFFF),
    keyBorder: Color(0xFFCBD5E1),
    keyLabel: Color(0xFF334155),
    powerColor: Color(0xFFDC2626),
  );
}
