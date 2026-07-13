import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../config/remote_api_config.dart';
import '../models/ai_usage_policy.dart';
import '../models/device.dart';
import 'config_service.dart';

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

/// Pro L1: 同梱相場参照DB + オンライン API フォールバック
class ReferenceMarketCatalogService {
  ReferenceMarketCatalogService._({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  static ReferenceMarketCatalogService instance =
      ReferenceMarketCatalogService._();

  final http.Client _http;
  Map<String, ReferenceMarketEntry>? _byModelKey;
  double _defaultDecay = 0.012;
  Duration remoteTimeout = const Duration(seconds: 3);

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
        final entry = _entryFromJson(m, defaultDecay: _defaultDecay);
        if (entry == null) continue;
        map[_modelKey(entry.modelNumber)] = entry;
      }
      _byModelKey = map;
    } catch (_) {
      _byModelKey = {};
    }
  }

  static ReferenceMarketEntry? _entryFromJson(
    Map<String, dynamic> m, {
    required double defaultDecay,
  }) {
    final model = m['modelNumber']?.toString().trim() ?? '';
    if (model.isEmpty) return null;
    final asOfRaw = m['referenceAsOf']?.toString() ?? '2024-01-01';
    final asOf = DateTime.tryParse(asOfRaw) ?? DateTime(2024, 1, 1);
    return ReferenceMarketEntry(
      manufacturer: m['manufacturer']?.toString().trim() ?? '',
      modelNumber: model,
      referenceMarketYen: (m['referenceMarketYen'] as num?)?.toInt() ?? 0,
      referenceAsOf: asOf,
      monthlyDecayRate:
          (m['monthlyDecayRate'] as num?)?.toDouble() ??
              (m['monthlyDecayRateDefault'] as num?)?.toDouble() ??
              defaultDecay,
    );
  }

  static String _modelKey(String modelNumber) =>
      modelNumber.trim().toLowerCase();

  /// 型番一致で参照相場（経過月の減価適用後）を返す。
  /// [config] が Pro ならオンライン API を優先し、失敗時は同梱 JSON へフォールバック。
  Future<int?> lookupAdjustedPrice(
    Device device, {
    DateTime? asOf,
    ConfigService? config,
  }) async {
    await _ensureLoaded();
    final key = _modelKey(device.modelNumber);
    if (key.isEmpty) return null;

    ReferenceMarketEntry? entry;
    if (config != null && config.subscriptionTier == SubscriptionTier.pro) {
      entry = await _lookupRemoteEntry(device, config);
    }
    entry ??= _byModelKey![key];
    if (entry == null || entry.referenceMarketYen <= 0) return null;

    final now = asOf ?? DateTime.now();
    final months = _monthsBetween(entry.referenceAsOf, now);
    final factor = math.pow(1 - entry.monthlyDecayRate, months);
    final adjusted = (entry.referenceMarketYen * factor).round();
    return math.max(1000, adjusted);
  }

  Future<ReferenceMarketEntry?> _lookupRemoteEntry(
    Device device,
    ConfigService config,
  ) async {
    try {
      final uri = Uri.parse('${RemoteApiConfig.baseUrl}/v1/market/reference')
          .replace(queryParameters: {
        'manufacturer': device.manufacturer,
        'modelNumber': device.modelNumber,
      });
      final res = await _http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'X-HomTune-User-Id': RemoteApiConfig.devUserId,
              'X-HomTune-Pro': 'true',
            },
          )
          .timeout(remoteTimeout);
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final raw = decoded['entry'];
      if (raw is! Map) return null;
      final entry = _entryFromJson(
        raw.cast<String, dynamic>(),
        defaultDecay: _defaultDecay,
      );
      if (entry == null) return null;
      _byModelKey![_modelKey(entry.modelNumber)] = entry;
      return entry;
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasEntryFor(Device device) async {
    await _ensureLoaded();
    return _byModelKey!.containsKey(_modelKey(device.modelNumber));
  }

  int _monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + (to.month - from.month);
  }

  @visibleForTesting
  void resetForTest({http.Client? httpClient}) {
    _byModelKey = null;
    if (httpClient != null) {
      instance = ReferenceMarketCatalogService._(httpClient: httpClient);
    }
  }
}
