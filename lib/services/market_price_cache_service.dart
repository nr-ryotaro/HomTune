import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/device.dart';

/// 型番ベースの市場価値キャッシュ（API コスト削減用）
class MarketPriceCacheEntry {
  final int priceYen;
  final String source;
  final String fetchedAtIso;

  const MarketPriceCacheEntry({
    required this.priceYen,
    required this.source,
    required this.fetchedAtIso,
  });

  DateTime? get fetchedAt => DateTime.tryParse(fetchedAtIso);

  bool isExpired({int ttlDays = 30}) {
    final at = fetchedAt;
    if (at == null) return true;
    return DateTime.now().difference(at).inDays >= ttlDays;
  }
}

class MarketPriceCacheService {
  MarketPriceCacheService._();
  static final MarketPriceCacheService instance = MarketPriceCacheService._();

  static const _prefsKey = 'market_price_cache_v1';

  Future<Map<String, dynamic>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static String cacheKey(Device device) =>
      '${device.manufacturer.trim().toLowerCase()}|${device.modelNumber.trim().toLowerCase()}';

  Future<MarketPriceCacheEntry?> get(Device device) async {
    final key = cacheKey(device);
    if (key == '|' || device.modelNumber.trim().isEmpty) return null;
    final all = await _loadAll();
    final raw = all[key];
    if (raw is! Map) return null;
    final price = (raw['priceYen'] as num?)?.toInt();
    final source = raw['source']?.toString();
    final fetchedAt = raw['fetchedAt']?.toString();
    if (price == null || source == null || fetchedAt == null) return null;
    return MarketPriceCacheEntry(
      priceYen: price,
      source: source,
      fetchedAtIso: fetchedAt,
    );
  }

  Future<void> put(
    Device device, {
    required int priceYen,
    required String source,
  }) async {
    final key = cacheKey(device);
    if (key == '|') return;
    final all = await _loadAll();
    all[key] = {
      'priceYen': priceYen,
      'source': source,
      'fetchedAt': DateTime.now().toIso8601String(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(all));
  }

  void resetForTest() {}
}
