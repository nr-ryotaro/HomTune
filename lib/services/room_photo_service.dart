import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_prefs.dart';

/// 部屋カード画像（デフォルト → ユーザー写真）の管理
class RoomPhotoService {
  RoomPhotoService._();

  static const _keyApplianceSetupDone = 'appliance_setup_done';
  static const _keyRoomPhotosConfigured = 'room_photos_configured';
  static const _prefixCustomPath = 'room_custom_image_';

  static Future<bool> isApplianceSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyApplianceSetupDone) ?? false;
  }

  static Future<void> setApplianceSetupDone(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyApplianceSetupDone, value);
  }

  static Future<bool> isRoomPhotosConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRoomPhotosConfigured) ?? false;
  }

  static Future<void> setRoomPhotosConfigured(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRoomPhotosConfigured, value);
  }

  /// カスタム画像パス（未設定なら null → デフォルトサンプル画像を使用）
  static Future<String?> getCustomImagePath(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('$_prefixCustomPath$roomId');
    if (path == null || path.isEmpty) return null;
    return path;
  }

  static Future<void> setCustomImagePath(String roomId, String? filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefixCustomPath$roomId';
    if (filePath == null || filePath.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, filePath);
    }
  }

  /// ホームの部屋カード用画像（カスタム優先、なければデフォルト）
  static Future<String> imagePathForRoom(String roomId) async {
    final custom = await getCustomImagePath(roomId);
    if (custom != null) return custom;
    return OnboardingRoomCatalog.cardById[roomId]?.imagePath ??
        'assets/images/Living_sample.jpg';
  }

  static bool isAssetPath(String path) => path.startsWith('assets/');
}
