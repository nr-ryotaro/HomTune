import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// リモコン設定リマインダーのスヌーズ管理
class RemoteSetupReminderPrefs {
  static const String _keySnoozeMap = 'remote_setup_snooze_until';

  static Future<void> snoozeDevice(String deviceId, {int days = 7}) async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(Duration(days: days)).toIso8601String();
    final map = await _readSnoozeMap(prefs);
    map[deviceId] = until;
    await prefs.setString(_keySnoozeMap, jsonEncode(map));
  }

  static Future<void> clearSnooze(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _readSnoozeMap(prefs);
    map.remove(deviceId);
    await prefs.setString(_keySnoozeMap, jsonEncode(map));
  }

  static Future<bool> isSnoozed(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _readSnoozeMap(prefs);
    final raw = map[deviceId];
    if (raw == null || raw.isEmpty) return false;
    final until = DateTime.tryParse(raw);
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    map.remove(deviceId);
    await prefs.setString(_keySnoozeMap, jsonEncode(map));
    return false;
  }

  static Future<Map<String, String>> _readSnoozeMap(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_keySnoozeMap);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return {};
    }
  }

  /// テスト用
  static Future<void> clearAllForTest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySnoozeMap);
  }
}
