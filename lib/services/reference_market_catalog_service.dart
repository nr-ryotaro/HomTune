import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

import '../models/device.dart';

class ReferenceMarketEntry {
  final String manufacturer;
  final String modelNumber;
  final int referenceMarketYen;
  final DateTime referenceAsOf;
  final double monthlyDecayRate;

  const ReferenceMarketEntry({
    required this.manufacturer,
    required this.modelNumber,
    required this.referenceMarketYen,
    required this.referenceAsOf,
    required this.monthlyDecayRate,
  });
}

/// Pro L1: 同梱相場参照DB（将来サーバー配信に差し替え可能）
class ReferenceMarketCatalogService {
  ReferenceMarketCatalogService._();
  static final ReferenceMarketCatalogService instance =
      ReferenceMarketCatalogService._();

  Map<String, ReferenceMarketEntry>? _byModelKey;
  double _defaultDecay = 0.012;

  Future<void> _ensureLoaded() async {
    if (_byModelKey != null) return;
    try {
      final raw = await rootBundle
          .loadString('assets/data/market-reference-prices.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _defaultDecay =
          (json['monthlyDecayRateDefault'] as num?)?.toDouble() ?? 0.012;
      final list = json['entries'] as List<dynamic>? ?? [];
      final map = <String, ReferenceMarketEntry>{};
      for (final item in list) {
        if (item is! Map) continue;
        final m = item.cast<String, dynamic>();
        final model = m['modelNumber']?.toString().trim() ?? '';
        if (model.isEmpty) continue;
        final asOfRaw = m['referenceAsOf']?.toString() ?? '2024-01-01';
        final asOf = DateTime.tryParse(asOfRaw) ?? DateTime(2024, 1, 1);
        final entry = ReferenceMarketEntry(
          manufacturer: m['manufacturer']?.toString().trim() ?? '',
          modelNumber: model,
          referenceMarketYen: (m['referenceMarketYen'] as num?)?.toInt() ?? 0,
          referenceAsOf: asOf,
          monthlyDecayRate:
              (m['monthlyDecayRate'] as num?)?.toDouble() ?? _defaultDecay,
        );
        map[_modelKey(model)] = entry;
      }
      _byModelKey = map;
    } catch (_) {
      _byModelKey = {};
    }
  }

  static String _modelKey(String modelNumber) =>
      modelNumber.trim().toLowerCase();

  /// 型番一致で参照相場（経過月の減価適用後）を返す
  Future<int?> lookupAdjustedPrice(Device device, {DateTime? asOf}) async {
    await _ensureLoaded();
    final key = _modelKey(device.modelNumber);
    if (key.isEmpty) return null;
    final entry = _byModelKey![key];
    if (entry == null || entry.referenceMarketYen <= 0) return null;

    final now = asOf ?? DateTime.now();
    final months = _monthsBetween(entry.referenceAsOf, now);
    final factor = math.pow(1 - entry.monthlyDecayRate, months);
    final adjusted = (entry.referenceMarketYen * factor).round();
    return math.max(1000, adjusted);
  }

  Future<bool> hasEntryFor(Device device) async {
    await _ensureLoaded();
    return _byModelKey!.containsKey(_modelKey(device.modelNumber));
  }

  int _monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + (to.month - from.month);
  }

  @visibleForTesting
  void resetForTest() {
    _byModelKey = null;
  }
}
