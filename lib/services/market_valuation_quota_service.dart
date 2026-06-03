import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_usage_policy.dart';
import 'ai_usage_service.dart';
import 'config_service.dart';

class MarketValuationQuotaSnapshot {
  final int usedThisMonth;
  final int monthlyLimit;
  final bool isPro;

  const MarketValuationQuotaSnapshot({
    required this.usedThisMonth,
    required this.monthlyLimit,
    required this.isPro,
  });

  int get remaining =>
      (monthlyLimit - usedThisMonth).clamp(0, monthlyLimit);

  bool get canConsumeL1 => isPro && remaining > 0;
}

/// Pro L1 相場DB参照の月間クォータ（AIクレジットとは別枠）
class MarketValuationQuotaService {
  MarketValuationQuotaService._();
  static final MarketValuationQuotaService instance =
      MarketValuationQuotaService._();

  static const _keyPrefix = 'market_l1_usage_';

  String _monthKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

  Future<MarketValuationQuotaSnapshot> getSnapshot(
    ConfigService config,
  ) async {
    final policy = await AiUsageService.instance.getEffectivePolicy();
    final isPro = config.subscriptionTier == SubscriptionTier.pro;
    final limit = isPro ? policy.proMonthlyMarketLookups : 0;
    if (!isPro) {
      return MarketValuationQuotaSnapshot(
        usedThisMonth: 0,
        monthlyLimit: limit,
        isPro: false,
      );
    }
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${_monthKey(DateTime.now())}';
    final used = prefs.getInt(key) ?? 0;
    return MarketValuationQuotaSnapshot(
      usedThisMonth: used,
      monthlyLimit: limit,
      isPro: true,
    );
  }

  Future<bool> tryConsumeL1(ConfigService config) async {
    final snap = await getSnapshot(config);
    if (!snap.canConsumeL1) return false;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${_monthKey(DateTime.now())}';
    final next = snap.usedThisMonth + 1;
    await prefs.setInt(key, next);
    return true;
  }

  /// テスト用
  Future<void> resetForTest() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
