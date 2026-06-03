import '../models/device.dart';
import '../utils/category_mapper.dart';

/// 質問文と登録デバイスのマッチング（チャット・ルーティング共通）
class DeviceQueryMatcher {
  DeviceQueryMatcher._();

  static const Map<String, List<String>> categoryKeywords = {
    'エアコン': ['エアコン', 'air', 'クーラー', '冷房', '暖房'],
    'テレビ': ['テレビ', 'tv', 'ブラビア', 'bravia', 'モニター'],
    '冷蔵庫': ['冷蔵庫', '冷凍', '冷蔵', 'refrigerator'],
    'オーディオ': [
      'スピーカー',
      'speaker',
      'オーディオ',
      'ホームポッド',
      'homepod',
      'レコード',
      'ターンテーブル',
    ],
    '加湿器': ['加湿器', 'humidifier', 'cado'],
    '掃除機': ['掃除機', 'ルンバ', 'クリーナー', 'vacuum'],
    '洗濯機': ['洗濯', '乾燥機', 'washer'],
    '炊飯器': ['炊飯', 'ライスポット', 'rice cooker'],
    'コンロ': ['オーブン', 'oven', 'コンロ', 'コンベクション'],
    'PC': ['パソコン', 'pc', 'macbook', 'mac', 'ノート', 'デスクトップ'],
    'その他': ['ソファ', 'ベッド', '照明', 'ペンダント', 'ライト'],
  };

  static const Map<String, List<String>> roomKeywords = {
    'living-room': ['リビング', 'living'],
    'study': ['書斎', 'study', '仕事部屋'],
    'bedroom': ['寝室', 'bedroom'],
    'bedroom-01': ['寝室', 'bedroom'],
    'kitchen': ['キッチン', 'kitchen', '台所'],
    'kitchen-01': ['キッチン', 'kitchen', '台所'],
    'entrance': ['玄関', 'entrance', 'genkan'],
  };

  static bool hasDeviceMatch(String message, List<Device> devices) {
    return findRelevant(message, devices) != null ||
        _matchesAnyRegisteredNameOrModel(message, devices);
  }

  static bool _matchesAnyRegisteredNameOrModel(
    String message,
    List<Device> devices,
  ) {
    final lower = message.toLowerCase();
    for (final d in devices) {
      final name = d.name.trim().toLowerCase();
      if (name.isNotEmpty && lower.contains(name)) return true;
      final model = d.modelNumber.trim().toLowerCase();
      if (model.isNotEmpty && lower.contains(model)) return true;
    }
    return false;
  }

  static Device? findRelevant(String message, List<Device> devices) {
    if (devices.isEmpty) return null;
    final lower = message.toLowerCase();

    for (final device in devices) {
      final name = device.name.trim().toLowerCase();
      if (name.isNotEmpty && lower.contains(name)) return device;
      final model = device.modelNumber.trim().toLowerCase();
      if (model.isNotEmpty && lower.contains(model)) return device;
      final maker = device.manufacturer.trim().toLowerCase();
      if (maker.length >= 3 && lower.contains(maker)) return device;
    }

    for (final entry in categoryKeywords.entries) {
      if (entry.value.any((kw) => lower.contains(kw))) {
        final hit = _firstInCategory(devices, entry.key);
        if (hit != null) return hit;
      }
    }

    for (final entry in roomKeywords.entries) {
      if (entry.value.any((kw) => lower.contains(kw))) {
        final hit = _firstInRoom(devices, entry.key);
        if (hit != null) return hit;
      }
    }

    return null;
  }

  static Device? findAirConditioner(List<Device> devices) {
    for (final d in devices) {
      final cat = CategoryMapper.normalize(d.category);
      if (cat == 'エアコン') return d;
    }
    return null;
  }

  static Device? _firstInCategory(List<Device> devices, String categoryKey) {
    for (final d in devices) {
      if (CategoryMapper.normalize(d.category) == categoryKey) return d;
    }
    return null;
  }

  static Device? _firstInRoom(List<Device> devices, String roomId) {
    for (final d in devices) {
      if (d.room == roomId || d.room == '${roomId.split('-').first}-01') {
        return d;
      }
    }
    for (final d in devices) {
      if (d.room.contains(roomId.split('-').first)) return d;
    }
    return null;
  }
}
