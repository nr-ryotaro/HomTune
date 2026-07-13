import 'dart:convert';

import '../models/ai_usage_policy.dart';
import '../models/device.dart';
import 'ai_api_client.dart';
import 'ai_usage_service.dart';
import 'asset_valuation_service.dart';
import 'config_service.dart';
import 'reference_market_catalog_service.dart';

class MarketPriceEstimateException implements Exception {
  final String message;
  const MarketPriceEstimateException(this.message);
  @override
  String toString() => message;
}

/// Pro L2: AI による中古相場推定（Gemini プロキシ経由）
class MarketPriceGeminiService {
  MarketPriceGeminiService({
    ReferenceMarketCatalogService? referenceCatalog,
    AssetValuationService? valuation,
    AiApiClient? aiApiClient,
  })  : _referenceCatalog =
            referenceCatalog ?? ReferenceMarketCatalogService.instance,
        _valuation = valuation ?? AssetValuationService(),
        _aiApi = aiApiClient ?? AiApiClient();

  final ReferenceMarketCatalogService _referenceCatalog;
  final AssetValuationService _valuation;
  final AiApiClient _aiApi;

  static const int creditCost = 2;

  Future<int> estimateUsedPriceYen(
    Device device,
    ConfigService config,
  ) async {
    if (!_configAllowsPro(config)) {
      throw const MarketPriceEstimateException('Proプランが必要です');
    }

    if (!config.isCloudAiEnabled) {
      return _mockEstimate(device);
    }

    final budget = await AiUsageService.instance.canRunFeature(
      config,
      feature: AiFeature.marketValuation,
      requestedCredits: creditCost,
    );
    if (!budget.allowed) {
      throw MarketPriceEstimateException(budget.reason);
    }

    final prompt = _buildPrompt(device);
    try {
      final result = await _aiApi.generate(
        config: config,
        feature: AiFeature.marketValuation,
        responseFormat: 'json',
        requestedCredits: creditCost,
        contents: [AiContentMessage(role: 'user', text: prompt)],
      );
      final yen = _parseYenFromResponse(result.text.trim());
      if (yen == null || yen <= 0) {
        throw const MarketPriceEstimateException('相場金額を解析できませんでした');
      }

      await AiUsageService.instance.recordUsage(
        config,
        feature: AiFeature.marketValuation,
        consumedCredits: result.usage.creditsCharged > 0
            ? result.usage.creditsCharged
            : creditCost,
      );
      return yen;
    } on AiApiException catch (e) {
      // プロキシ未起動・テスト環境ではローカル推定へフォールバック
      if (!config.isUsingRealApi) {
        return _mockEstimate(device);
      }
      throw MarketPriceEstimateException(e.message);
    } catch (e) {
      if (e is MarketPriceEstimateException) rethrow;
      if (!config.isUsingRealApi) {
        return _mockEstimate(device);
      }
      throw MarketPriceEstimateException('AI相場推定に失敗しました: $e');
    }
  }

  bool _configAllowsPro(ConfigService config) =>
      config.subscriptionTier == SubscriptionTier.pro;

  Future<int> _mockEstimate(Device device) async {
    final ref = await _referenceCatalog.lookupAdjustedPrice(device);
    if (ref != null) {
      final jitter = _stableJitter(device.modelNumber, 0.92, 1.08);
      return (ref * jitter).round();
    }
    final formula = _valuation.simulateMarketValue(device);
    final jitter = _stableJitter(device.modelNumber, 0.88, 1.12);
    return (formula * jitter).round();
  }

  double _stableJitter(String seed, double min, double max) {
    var hash = 0;
    for (final c in seed.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    final t = (hash % 1000) / 1000.0;
    return min + (max - min) * t;
  }

  String _buildPrompt(Device device) {
    final purchase = device.purchasePrice > 0
        ? '購入価格: ¥${device.purchasePrice}'
        : '購入価格: 不明';
    return '''
あなたは日本の中古家電・家具市場に詳しい査定アシスタントです。
以下の製品について、**現在（2025年頃）の中古販売相場の目安**を日本円の整数1つだけで答えてください。

メーカー: ${device.manufacturer}
型番: ${device.modelNumber}
カテゴリ: ${device.category}
購入日: ${device.purchaseDate}
$purchase

回答は次のJSONのみ（説明文不要）:
{"usedPriceYen": 12345}
''';
  }

  int? _parseYenFromResponse(String text) {
    final jsonMatch = RegExp(r'\{[\s\S]*?\}').firstMatch(text);
    if (jsonMatch != null) {
      try {
        final map = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        final v = map['usedPriceYen'] ?? map['priceYen'] ?? map['price'];
        if (v is num) return v.round();
      } catch (_) {}
    }
    final numMatch = RegExp(r'(\d{4,9})').firstMatch(text.replaceAll(',', ''));
    if (numMatch != null) {
      return int.tryParse(numMatch.group(1)!);
    }
    return null;
  }
}
