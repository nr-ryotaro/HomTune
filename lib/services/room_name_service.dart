import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_prefs.dart';

/// 部屋の表示名（ユーザーが変更可能）
class RoomNameService {
  RoomNameService._();
  static final RoomNameService instance = RoomNameService._();

  static const _keyDisplayNames = 'room_display_names_v1';

  final Map<String, String> _cache = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyDisplayNames);
    _cache.clear();
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final name = entry.value?.toString().trim() ?? '';
        if (name.isNotEmpty) {
          _cache[entry.key] = name;
        }
      }
    }
    _loaded = true;
  }

  String displayNameFor(String roomId) {
    final custom = _cache[roomId];
    if (custom != null && custom.isNotEmpty) return custom;
    return OnboardingRoomCatalog.fallbackTitleFor(roomId);
  }

  Future<void> setDisplayName(String roomId, String name) async {
    await load();
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _cache.remove(roomId);
    } else {
      _cache[roomId] = trimmed;
    }
    await _persist();
  }

  Future<void> saveFromRoomOptions(
    Iterable<({String id, String name})> rooms,
  ) async {
    await load();
    for (final room in rooms) {
      final trimmed = room.name.trim();
      if (trimmed.isNotEmpty) {
        _cache[room.id] = trimmed;
      }
    }
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDisplayNames, jsonEncode(_cache));
  }

  static String defaultNameForIndex(int index) => '部屋${index + 1}';
}
