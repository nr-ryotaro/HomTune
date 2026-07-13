import 'package:flutter/material.dart';

import 'device_remote_link.dart';
import 'remote_appliance.dart';
import 'remote_ui_skin.dart';

/// リモコン UI ボタンの見た目
enum RemoteUiButtonVariant {
  standard,
  primary,
  danger,
  cool,
  warm,
  dry,
  fan,
}

class RemoteUiButtonDef {
  final String id;
  final String label;
  final IconData icon;
  final RemoteCommandType commandType;
  final RemoteUiButtonVariant variant;
  final String? signalKey;
  final Map<String, dynamic>? parameters;
  final bool customizable;
  final bool pinByDefault;

  const RemoteUiButtonDef({
    required this.id,
    required this.label,
    required this.icon,
    required this.commandType,
    this.variant = RemoteUiButtonVariant.standard,
    this.signalKey,
    this.parameters,
    this.customizable = true,
    this.pinByDefault = false,
  });

  factory RemoteUiButtonDef.fromJson(Map<String, dynamic> json) {
    return RemoteUiButtonDef(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      icon: _iconFromName(json['icon']?.toString() ?? 'touch_app'),
      commandType: RemoteCommandType.values.firstWhere(
        (e) => e.name == json['commandType'],
        orElse: () => RemoteCommandType.sendSignal,
      ),
      variant: RemoteUiButtonVariant.values.firstWhere(
        (e) => e.name == json['variant'],
        orElse: () => RemoteUiButtonVariant.standard,
      ),
      signalKey: json['signalKey']?.toString(),
      parameters: (json['parameters'] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      customizable: json['customizable'] != false,
      pinByDefault: json['pinByDefault'] == true,
    );
  }

  static IconData _iconFromName(String name) {
    const map = {
      'power_settings_new': Icons.power_settings_new,
      'power_off': Icons.power_off,
      'ac_unit': Icons.ac_unit,
      'whatshot': Icons.whatshot,
      'water_drop': Icons.water_drop,
      'air': Icons.air,
      'eco': Icons.eco,
      'timer': Icons.timer_outlined,
      'swap_vert': Icons.swap_vert,
      'volume_up': Icons.volume_up,
      'volume_down': Icons.volume_down,
      'volume_off': Icons.volume_off,
      'keyboard_arrow_up': Icons.keyboard_arrow_up,
      'keyboard_arrow_down': Icons.keyboard_arrow_down,
      'input': Icons.input,
      'tv': Icons.tv,
      'play_circle': Icons.play_circle_outline,
      'movie': Icons.movie_outlined,
      'shopping_bag': Icons.shopping_bag_outlined,
      'cast': Icons.cast,
      'settings': Icons.settings,
      'add': Icons.add,
      'remove': Icons.remove,
      'touch_app': Icons.touch_app,
    };
    return map[name] ?? Icons.touch_app;
  }
}

class RemoteUiGroupDef {
  final String id;
  final String title;
  final List<RemoteUiButtonDef> buttons;

  const RemoteUiGroupDef({
    required this.id,
    required this.title,
    required this.buttons,
  });

  factory RemoteUiGroupDef.fromJson(Map<String, dynamic> json) {
    return RemoteUiGroupDef(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      buttons: (json['buttons'] as List<dynamic>? ?? [])
          .map((e) => RemoteUiButtonDef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RemoteUiTemplate {
  final String id;
  final String label;
  final RemoteCapabilityProfile profile;
  final RemoteUiSkinType skin;
  final String themeKey;
  final List<String> manufacturers;
  final List<String> modelPatterns;
  final List<RemoteUiGroupDef> groups;

  const RemoteUiTemplate({
    required this.id,
    required this.label,
    required this.profile,
    this.skin = RemoteUiSkinType.grid,
    this.themeKey = '',
    this.manufacturers = const [],
    this.modelPatterns = const [],
    required this.groups,
  });

  factory RemoteUiTemplate.fromJson(Map<String, dynamic> json) {
    return RemoteUiTemplate(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      profile: RemoteCapabilityProfile.values.firstWhere(
        (e) => e.name == json['profile'],
        orElse: () => RemoteCapabilityProfile.genericIr,
      ),
      skin: remoteUiSkinTypeFromJson(json['skin']?.toString()),
      themeKey: json['themeKey']?.toString() ?? '',
      manufacturers: (json['manufacturers'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      modelPatterns: (json['modelPatterns'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      groups: (json['groups'] as List<dynamic>? ?? [])
          .map((e) => RemoteUiGroupDef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  List<RemoteUiButtonDef> get allButtons =>
      groups.expand((g) => g.buttons).toList();
}

/// ユーザー設定を反映した表示用レイアウト
class RemoteUiResolvedLayout {
  final String templateId;
  final String templateLabel;
  final RemoteUiSkinType skin;
  final String themeKey;
  final List<RemoteUiGroupDef> groups;
  final List<RemoteUiButtonDef> pinnedButtons;

  const RemoteUiResolvedLayout({
    required this.templateId,
    required this.templateLabel,
    this.skin = RemoteUiSkinType.grid,
    this.themeKey = '',
    required this.groups,
    this.pinnedButtons = const [],
  });
}

class RemoteUiUserPreferences {
  final Set<String> hiddenButtonIds;
  final List<String> pinnedButtonIds;

  const RemoteUiUserPreferences({
    this.hiddenButtonIds = const {},
    this.pinnedButtonIds = const [],
  });

  factory RemoteUiUserPreferences.fromJson(Map<String, dynamic> json) {
    return RemoteUiUserPreferences(
      hiddenButtonIds: (json['hiddenButtonIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toSet(),
      pinnedButtonIds: (json['pinnedButtonIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'hiddenButtonIds': hiddenButtonIds.toList(),
        'pinnedButtonIds': pinnedButtonIds,
      };

  RemoteUiUserPreferences copyWith({
    Set<String>? hiddenButtonIds,
    List<String>? pinnedButtonIds,
  }) {
    return RemoteUiUserPreferences(
      hiddenButtonIds: hiddenButtonIds ?? this.hiddenButtonIds,
      pinnedButtonIds: pinnedButtonIds ?? this.pinnedButtonIds,
    );
  }
}
