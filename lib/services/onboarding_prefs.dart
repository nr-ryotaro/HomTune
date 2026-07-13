import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/appliance_archetype.dart';
import 'room_name_service.dart';

/// 初回LP（オンボーディング）の永続化キーと操作
class OnboardingPrefs {
  static const String keyCompleted = 'onboarding_completed';
  static const String keySelectedRooms = 'selected_rooms';
  static const String keySelectedArchetypes = 'selected_archetypes';
  static const String keyHousingType = 'housing_type';
  static const String keyShowOnLaunch = 'show_onboarding_on_launch';
  static const String keyIncludeDemoSeed = 'include_demo_seed_devices';
  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyCompleted) ?? false;
  }

  static Future<bool> shouldShowOnLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final forceShow = prefs.getBool(keyShowOnLaunch) ?? false;
    if (forceShow) return true;
    return !(prefs.getBool(keyCompleted) ?? false);
  }

  static Future<bool> isShowOnLaunchEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyShowOnLaunch) ?? false;
  }

  static Future<void> setShowOnLaunch(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyShowOnLaunch, value);
  }

  /// 次回起動時にLPを表示するよう設定（完了フラグは維持）
  static Future<void> enableShowOnNextLaunch() async {
    await setShowOnLaunch(true);
  }

  static Future<void> setCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyCompleted, value);
  }

  static Future<List<String>> getSelectedRoomIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(keySelectedRooms) ?? [];
  }

  static Future<void> setSelectedRoomIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = ids
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    await prefs.setStringList(keySelectedRooms, cleaned);
  }

  static Future<void> setSelectedArchetypes(
    List<SelectedArchetypeRef> refs,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = refs.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(keySelectedArchetypes, encoded);
  }

  static Future<List<SelectedArchetypeRef>> getSelectedArchetypes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(keySelectedArchetypes) ?? [];
    return raw
        .map((s) => SelectedArchetypeRef.fromJson(
            jsonDecode(s) as Map<String, dynamic>))
        .where((r) => r.archetypeId.isNotEmpty)
        .toList();
  }

  static Future<bool> includeDemoSeedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIncludeDemoSeed) ?? false;
  }

  static Future<void> setIncludeDemoSeedDevices(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIncludeDemoSeed, value);
  }
}
/// ホーム画面の部屋カード表示用メタデータ
class OnboardingRoomCatalog {
  OnboardingRoomCatalog._();

  static const defaultHomeRoomIds = [
    'living-room',
    'bedroom-01',
    'kitchen-01',
  ];

  static const Map<String, String> _japaneseTitles = {
    'living-room': 'リビング',
    'bedroom-01': '寝室',
    'kitchen-01': 'キッチン',
    'entrance': '玄関',
    'study': '書斎',
  };

  /// カスタム名称がないときのフォールバック（テンプレート向けの旧名称）
  static String fallbackTitleFor(String roomId) =>
      _japaneseTitles[roomId] ??
      cardById[roomId]?.title ??
      roomId;

  static String displayTitleFor(String roomId) =>
      RoomNameService.instance.displayNameFor(roomId);

  static const Map<String, ({String title, String imagePath})> cardById = {
    'living-room': (
      title: 'リビング',
      imagePath: 'assets/images/Living_sample.jpg',
    ),
    'bedroom-01': (
      title: '寝室',
      imagePath: 'assets/images/Bedroom_sample.jpg',
    ),
    'kitchen-01': (
      title: 'キッチン',
      imagePath: 'assets/images/Kitchen_sample.jpg',
    ),
    'entrance': (
      title: '玄関',
      imagePath: 'assets/images/Living_sample.jpg',
    ),
    'study': (
      title: '書斎',
      imagePath: 'assets/images/Bedroom_sample.jpg',
    ),
  };
}
