import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/device.dart';
import '../../models/device_remote_link.dart';
import '../../models/remote_ui_template.dart';
import 'remote_ui_preferences_service.dart';

class RemoteUiTemplateService {
  RemoteUiTemplateService._();
  static final RemoteUiTemplateService instance = RemoteUiTemplateService._();

  List<RemoteUiTemplate>? _templates;
  Future<void>? _loadingFuture;

  Future<void> _ensureLoaded() async {
    if (_templates != null) return;
    _loadingFuture ??= _load();
    await _loadingFuture;
  }

  Future<void> _load() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/remote-ui-templates.json');
      final raw = jsonDecode(jsonStr) as Map<String, dynamic>;
      _templates = (raw['templates'] as List<dynamic>? ?? [])
          .map((e) => RemoteUiTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _templates = [];
    }
  }

  void loadTemplatesForTest(List<RemoteUiTemplate> templates) {
    _templates = templates;
    _loadingFuture = null;
  }

  void resetForTest() {
    _templates = null;
    _loadingFuture = null;
  }

  Future<RemoteUiTemplate> resolveTemplate({
    required RemoteCapabilityProfile profile,
    String manufacturer = '',
    String modelNumber = '',
  }) async {
    await _ensureLoaded();
    final templates = _templates ?? [];
    final model = modelNumber.trim().toUpperCase();
    final mfr = manufacturer.trim().toLowerCase();

    RemoteUiTemplate? best;
    var bestScore = -1;

    for (final t in templates.where((t) => t.profile == profile)) {
      var score = 0;
      if (t.modelPatterns.isNotEmpty && model.isNotEmpty) {
        for (final pattern in t.modelPatterns) {
          try {
            if (RegExp(pattern, caseSensitive: false).hasMatch(model)) {
              score += 40;
              break;
            }
          } catch (_) {}
        }
      }
      if (t.manufacturers.isNotEmpty && mfr.isNotEmpty) {
        for (final name in t.manufacturers) {
          if (mfr == name.toLowerCase() || mfr.contains(name.toLowerCase())) {
            score += 30;
            break;
          }
        }
      }
      if (t.id.endsWith('_default')) score = score > 0 ? score : 1;
      if (score > bestScore) {
        bestScore = score;
        best = t;
      }
    }

    return best ??
        templates.firstWhere(
          (t) => t.profile == profile && t.id.contains('default'),
          orElse: () => _fallbackTemplate(profile),
        );
  }

  RemoteUiTemplate _fallbackTemplate(RemoteCapabilityProfile profile) {
    return RemoteUiTemplate(
      id: '${profile.name}_fallback',
      label: '標準リモコン',
      profile: profile,
      groups: const [],
    );
  }

  Future<RemoteUiResolvedLayout> resolveLayoutForDevice(Device device) async {
    final profile = device.remoteLink?.profile ??
        DeviceRemoteLink.inferFromCategory(device.category);
    final template = await resolveTemplate(
      profile: profile,
      manufacturer: device.manufacturer,
      modelNumber: device.modelNumber,
    );
    final prefs =
        await RemoteUiPreferencesService.instance.load(device.id, template);
    return _applyPreferences(template, prefs);
  }

  Future<RemoteUiResolvedLayout> resolveLayoutForProfile({
    required RemoteCapabilityProfile profile,
    String manufacturer = '',
    String modelNumber = '',
    String deviceId = 'preview',
  }) async {
    final template = await resolveTemplate(
      profile: profile,
      manufacturer: manufacturer,
      modelNumber: modelNumber,
    );
    final prefs =
        await RemoteUiPreferencesService.instance.load(deviceId, template);
    return _applyPreferences(template, prefs);
  }

  RemoteUiResolvedLayout _applyPreferences(
    RemoteUiTemplate template,
    RemoteUiUserPreferences prefs,
  ) {
    final all = template.allButtons;
    final pinned = <RemoteUiButtonDef>[];
    for (final id in prefs.pinnedButtonIds) {
      final btn = all.where((b) => b.id == id).toList();
      if (btn.isNotEmpty && !prefs.hiddenButtonIds.contains(id)) {
        pinned.add(btn.first);
      }
    }
    if (pinned.isEmpty) {
      pinned.addAll(
        all.where((b) => b.pinByDefault && !prefs.hiddenButtonIds.contains(b.id)),
      );
    }

    final groups = template.groups
        .map((group) {
          final visible = group.buttons
              .where((b) => !prefs.hiddenButtonIds.contains(b.id))
              .toList();
          if (visible.isEmpty) return null;
          return RemoteUiGroupDef(
            id: group.id,
            title: group.title,
            buttons: visible,
          );
        })
        .whereType<RemoteUiGroupDef>()
        .toList();

    return RemoteUiResolvedLayout(
      templateId: template.id,
      templateLabel: template.label,
      skin: template.skin,
      themeKey: template.themeKey,
      groups: groups,
      pinnedButtons: pinned,
    );
  }
}
