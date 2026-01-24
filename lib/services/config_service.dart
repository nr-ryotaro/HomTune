import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 機能確認用の API / ダミーデータ切り替え設定
/// リリース前に削除予定（RELEASE_CHECKLIST.md 参照）
class ConfigService extends ChangeNotifier {
  static const String _keyUseRealApi = 'use_real_api';

  bool _useRealApi = false;
  bool _loaded = false;

  bool get isUsingRealApi => _useRealApi;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _useRealApi = prefs.getBool(_keyUseRealApi) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setUseRealApi(bool value) async {
    if (_useRealApi == value) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseRealApi, value);
    _useRealApi = value;
    notifyListeners();
  }
}
