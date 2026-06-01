import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/appliance_archetype.dart';

/// 初回LP（オンボーディング）の永続化キーと操作
class OnboardingPrefs {
  static const String keyCompleted = 'onboarding_completed';
  static const String keySelectedRooms = 'selected_rooms';
  static const String keySelectedArchetypes = 'selected_archetypes';
  static const String keyHousingType = 'housing_type';
  static const String keyShowOnLaunch = 'show_onboarding_on_launch';
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
}
/// ホーム画面の部屋カード表示用メタデータ
class OnboardingRoomCatalog {
  OnboardingRoomCatalog._();

  static const defaultHomeRoomIds = [
    'living-room',
    'bedroom-01',
    'kitchen-01',
  ];

  static const Map<String, ({String title, String imagePath})> cardById = {
    'living-room': (
      title: 'Living Room',
      imagePath: 'assets/images/Living_sample.jpg',
    ),
    'bedroom-01': (
      title: 'Bedroom',
      imagePath: 'assets/images/Bedroom_sample.jpg',
    ),
    'kitchen-01': (
      title: 'Kitchen',
      imagePath: 'assets/images/Kitchen_sample.jpg',
    ),
    'entrance': (
      title: 'Entrance',
      imagePath: 'assets/images/Living_sample.jpg',
    ),
    'study': (
      title: 'Study',
      imagePath: 'assets/images/Bedroom_sample.jpg',
    ),
  };
}
