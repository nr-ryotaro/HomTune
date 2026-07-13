import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/remote_ui_template.dart';

/// デバイスごとのリモコン UI カスタマイズ（表示/非表示・ピン留め）
class RemoteUiPreferencesService {
  RemoteUiPreferencesService._();
  static final RemoteUiPreferencesService instance =
      RemoteUiPreferencesService._();

  static const _keyPrefix = 'remote_ui_prefs_';

  Future<RemoteUiUserPreferences> load(
    String deviceId,
    RemoteUiTemplate template,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$deviceId');
    if (raw == null || raw.isEmpty) {
      return RemoteUiUserPreferences(
        pinnedButtonIds: template.allButtons
            .where((b) => b.pinByDefault)
            .map((b) => b.id)
            .toList(),
      );
    }
    try {
      return RemoteUiUserPreferences.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const RemoteUiUserPreferences();
    }
  }

  Future<void> save(String deviceId, RemoteUiUserPreferences prefs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('$_keyPrefix$deviceId', jsonEncode(prefs.toJson()));
  }

  Future<void> clearForTest(String deviceId) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('$_keyPrefix$deviceId');
  }
}
