import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../models/ai_usage_policy.dart';
import '../models/asset_refresh_result.dart';
import '../models/device.dart';
import '../models/market_refresh_mode.dart';
import 'asset_valuation_service.dart';
import 'config_service.dart';
import 'market_price_cache_service.dart';
import 'market_price_gemini_service.dart';
import 'market_valuation_quota_service.dart';
import 'reference_market_catalog_service.dart';

/// 帳簿・市場・表示価値の更新方針
class AssetRefreshOptions {
  /// キャッシュ済み市場価格を優先（TTL 内）
  final bool preferMarketCache;

  /// 数式シミュレーションとカタログ参照のブレンド
  final bool useCatalogBlend;

  /// 市場価値キャッシュへ書き込む
  final bool writeMarketCache;

  /// L1/L2 で確定した市場価格（指定時は数式をスキップ）
  final int? forcedMarketPriceYen;
  final MarketValueSource? forcedMarketSource;

  const AssetRefreshOptions({
    this.preferMarketCache = true,
    this.useCatalogBlend = true,
    this.writeMarketCache = true,
    this.forcedMarketPriceYen,
    this.forcedMarketSource,
  });

  static const localRealtime = AssetRefreshOptions();
}

/// 低コストで「できるだけリアルタイム」な資産評価を提供
class AssetValuationRefreshService {
  AssetValuationRefreshService({
    AssetValuationService? valuation,
    MarketPriceCacheService? marketCache,
    ReferenceMarketCatalogService? referenceCatalog,
    MarketValuationQuotaService? quotaService,
    MarketPriceGeminiService? geminiService,
  })  : _valuation = valuation ?? AssetValuationService(),
        _marketCache = marketCache ?? MarketPriceCacheService.instance,
        _referenceCatalog =
            referenceCatalog ?? ReferenceMarketCatalogService.instance,
        _quota = quotaService ?? MarketValuationQuotaService.instance,
        _gemini = geminiService ?? MarketPriceGeminiService();

  final AssetValuationService _valuation;
  final MarketPriceCacheService _marketCache;
  final ReferenceMarketCatalogService _referenceCatalog;
  final MarketValuationQuotaService _quota;
  final MarketPriceGeminiService _gemini;

  Set<String>? _catalogModelKeys;

  Future<AssetValue> refresh(
    Device device, {
    AssetRefreshOptions options = AssetRefreshOptions.localRealtime,
  }) async {
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    final bookValue = await _computeBookValue(device);
    final marketResult = await _resolveMarketValue(
      device,
      options: options,
    );

    final displayValue = math.max(bookValue, marketResult.price);
    final usefulLife = await _valuation.getUsefulLife(device.category);

    String? insight;
    if (marketResult.price > bookValue * 1.1) {
      insight = '市場価値が帳簿価値を上回っています。売却の良いタイミングかもしれません。';
    } else if (bookValue < device.purchasePrice * 0.5) {
      insight = '購入価格の50%を下回りました。メンテナンスや買い替えの検討時期です。';
    }

    final history = _appendPriceHistory(
      existing: device.assetValue?.priceHistory ?? [],
      at: now,
      displayPrice: displayValue,
    );

    if (options.writeMarketCache &&
        marketResult.source != MarketValueSource.cached) {
      await _marketCache.put(
        device,
        priceYen: marketResult.price,
        source: marketResult.source.name,
      );
    }

    return AssetValue(
      purchasePrice: device.purchasePrice,
      currentUsedPrice: displayValue,
      depreciationRate: device.purchasePrice > 0
          ? (device.purchasePrice - bookValue) / device.purchasePrice
          : 0.0,
      lastPriceCheck: nowIso,
      bookValueUpdatedAt: nowIso,
      priceHistory: history,
      bookValue: bookValue,
      marketValue: marketResult.price,
      hasSellOpportunity: marketResult.price > bookValue,
      usefulLife: usefulLife,
      valuationInsight: insight,
      marketValueSource: marketResult.source.name,
    );
  }

  /// L0〜L2 と Free/Pro ポリシーに沿った更新
  Future<AssetRefreshResult> refreshWithMode(
    Device device, {
    required ConfigService config,
    required MarketRefreshMode mode,
  }) async {
    switch (mode) {
      case MarketRefreshMode.local:
        final av = await refresh(
          device,
          options: const AssetRefreshOptions(
            preferMarketCache: false,
            writeMarketCache: true,
          ),
        );
        return AssetRefreshResult(
          assetValue: av,
          mode: mode,
          message: '端末内で帳簿・市場を再計算しました',
        );

      case MarketRefreshMode.proReference:
        if (config.subscriptionTier != SubscriptionTier.pro) {
          throw AssetRefreshPolicyException('相場DBは Pro プラン専用です');
        }
        final quotaSnap = await _quota.getSnapshot(config);
        if (!quotaSnap.canConsumeL1) {
          throw AssetRefreshPolicyException(
            '今月の相場DB参照は上限（${quotaSnap.monthlyLimit}回）に達しました',
          );
        }

        final cached = await _marketCache.get(device);
        if (cached != null && !cached.isExpired()) {
          final av = await refresh(
            device,
            options: AssetRefreshOptions(
              preferMarketCache: true,
              forcedMarketPriceYen: cached.priceYen,
              forcedMarketSource: MarketValueSource.cached,
            ),
          );
          return AssetRefreshResult(
            assetValue: av,
            mode: mode,
            message: 'キャッシュ済み相場を適用しました（クォータ消費なし）',
          );
        }

        final refPrice = await _referenceCatalog.lookupAdjustedPrice(device);
        if (refPrice == null) {
          throw AssetRefreshPolicyException(
            'この型番は相場DBに未登録です。AI相場推定をお試しください',
          );
        }

        final consumed = await _quota.tryConsumeL1(config);
        if (!consumed) {
          throw AssetRefreshPolicyException('相場DBの利用枠を確保できませんでした');
        }

        final avRef = await refresh(
          device,
          options: AssetRefreshOptions(
            preferMarketCache: false,
            useCatalogBlend: false,
            forcedMarketPriceYen: refPrice,
            forcedMarketSource: MarketValueSource.referenceCatalog,
          ),
        );
        final remaining = (await _quota.getSnapshot(config)).remaining;
        return AssetRefreshResult(
          assetValue: avRef,
          mode: mode,
          message: '相場DBを適用しました（今月残り $remaining 回）',
        );

      case MarketRefreshMode.proAi:
        if (config.subscriptionTier != SubscriptionTier.pro) {
          throw AssetRefreshPolicyException('AI相場推定は Pro プラン専用です');
        }
        int aiPrice;
        try {
          aiPrice = await _gemini.estimateUsedPriceYen(device, config);
        } on MarketPriceEstimateException catch (e) {
          throw AssetRefreshPolicyException(e.message);
        }

        final avAi = await refresh(
          device,
          options: AssetRefreshOptions(
            preferMarketCache: false,
            useCatalogBlend: false,
            forcedMarketPriceYen: aiPrice,
            forcedMarketSource: MarketValueSource.geminiEstimate,
          ),
        );
        final suffix = config.isCloudAiEnabled
            ? '（AIクレジット ${MarketPriceGeminiService.creditCost} 消費）'
            : '（開発モード・モック推定）';
        return AssetRefreshResult(
          assetValue: avAi,
          mode: mode,
          message: 'AI相場推定を適用しました$suffix',
        );
    }
  }

  Future<int> _computeBookValue(Device device) async {
    final timeline = _valuation.calculateBookValue(device);
    final usefulLife = await _valuation.getUsefulLife(device.category);
    final elapsed =
        _valuation.calculateElapsedTimeFromString(device.purchaseDate);
    final statutory = _valuation.calculateStatutoryBookValue(
      device.purchasePrice,
      usefulLife,
      elapsed,
    );
    return ((timeline + statutory) / 2).round();
  }

  Future<({int price, MarketValueSource source})> _resolveMarketValue(
    Device device, {
    required AssetRefreshOptions options,
  }) async {
    if (options.forcedMarketPriceYen != null &&
        options.forcedMarketSource != null) {
      return (
        price: options.forcedMarketPriceYen!,
        source: options.forcedMarketSource!,
      );
    }

    if (options.preferMarketCache) {
      final cached = await _marketCache.get(device);
      if (cached != null && !cached.isExpired()) {
        return (
          price: cached.priceYen,
          source: MarketValueSource.cached,
        );
      }
    }

    var formula = _valuation.simulateMarketValue(device);
    var source = MarketValueSource.formula;

    if (options.useCatalogBlend) {
      final catalogPrice = await _catalogAdjustedMarket(device, formula);
      if (catalogPrice != null) {
        formula = catalogPrice;
        source = MarketValueSource.catalogBlend;
      }
    }

    return (price: formula, source: source);
  }

  Future<int?> _catalogAdjustedMarket(Device device, int formulaPrice) async {
    await _ensureCatalogKeys();
    final modelKey = device.modelNumber.trim().toLowerCase();
    if (modelKey.isEmpty || !_catalogModelKeys!.contains(modelKey)) {
      return null;
    }
    return ((formulaPrice * 0.7) + (device.purchasePrice * 0.35)).round();
  }

  Future<void> _ensureCatalogKeys() async {
    if (_catalogModelKeys != null) return;
    try {
      final raw = await rootBundle
          .loadString('assets/data/demo-device-catalog.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final list = json['devices'] as List<dynamic>? ?? [];
      _catalogModelKeys = list
          .map((e) => (e as Map)['modelNumber']?.toString().trim().toLowerCase())
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toSet();
    } catch (_) {
      _catalogModelKeys = {};
    }
  }

  List<PriceHistory> _appendPriceHistory({
    required List<PriceHistory> existing,
    required DateTime at,
    required int displayPrice,
  }) {
    final dateKey = '${at.year}-${at.month.toString().padLeft(2, '0')}-${at.day.toString().padLeft(2, '0')}';
    final next = List<PriceHistory>.from(existing);
    final idx = next.indexWhere((h) => h.date == dateKey);
    final point = PriceHistory(date: dateKey, price: displayPrice);
    if (idx >= 0) {
      next[idx] = point;
    } else {
      next.add(point);
    }
    next.sort((a, b) => a.date.compareTo(b.date));
    while (next.length > 24) {
      next.removeAt(0);
    }
    return next;
  }
}

class AssetRefreshPolicyException implements Exception {
  final String message;
  const AssetRefreshPolicyException(this.message);
  @override
  String toString() => message;
}
