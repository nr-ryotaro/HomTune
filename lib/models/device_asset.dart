/// 市場価値の算出元（UI表示・課金設計用）
enum MarketValueSource {
  formula,
  catalogBlend,
  cached,
  manual,
  /// Pro L1: 同梱相場参照DB（将来サーバーAPI）
  referenceCatalog,
  /// Pro L2: Gemini による中古相場推定
  geminiEstimate,
}

extension MarketValueSourceLabel on MarketValueSource {
  String get label {
    switch (this) {
      case MarketValueSource.formula:
        return '推定（数式）';
      case MarketValueSource.catalogBlend:
        return '推定（カタログ補正）';
      case MarketValueSource.cached:
        return 'キャッシュ相場';
      case MarketValueSource.manual:
        return '手動登録';
      case MarketValueSource.referenceCatalog:
        return '相場DB（Pro）';
      case MarketValueSource.geminiEstimate:
        return 'AI相場推定（Pro）';
    }
  }
}

class AssetValue {
  final int purchasePrice;
  final int currentUsedPrice;
  final double depreciationRate;
  final String lastPriceCheck;
  final List<PriceHistory> priceHistory;
  final int? bookValue;
  final int? marketValue;
  final bool? hasSellOpportunity;
  final double? usefulLife;
  final String? valuationInsight;
  /// [MarketValueSource.name] を保存
  final String? marketValueSource;
  final String? bookValueUpdatedAt;

  AssetValue({
    required this.purchasePrice,
    required this.currentUsedPrice,
    required this.depreciationRate,
    required this.lastPriceCheck,
    required this.priceHistory,
    this.bookValue,
    this.marketValue,
    this.hasSellOpportunity,
    this.usefulLife,
    this.valuationInsight,
    this.marketValueSource,
    this.bookValueUpdatedAt,
  });

  MarketValueSource get marketSourceParsed {
    final raw = marketValueSource;
    if (raw == null) return MarketValueSource.formula;
    return MarketValueSource.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => MarketValueSource.formula,
    );
  }

  AssetValue copyWith({
    int? purchasePrice,
    int? currentUsedPrice,
    double? depreciationRate,
    String? lastPriceCheck,
    List<PriceHistory>? priceHistory,
    int? bookValue,
    int? marketValue,
    bool? hasSellOpportunity,
    double? usefulLife,
    String? valuationInsight,
    String? marketValueSource,
    String? bookValueUpdatedAt,
  }) {
    return AssetValue(
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentUsedPrice: currentUsedPrice ?? this.currentUsedPrice,
      depreciationRate: depreciationRate ?? this.depreciationRate,
      lastPriceCheck: lastPriceCheck ?? this.lastPriceCheck,
      priceHistory: priceHistory ?? this.priceHistory,
      bookValue: bookValue ?? this.bookValue,
      marketValue: marketValue ?? this.marketValue,
      hasSellOpportunity: hasSellOpportunity ?? this.hasSellOpportunity,
      usefulLife: usefulLife ?? this.usefulLife,
      valuationInsight: valuationInsight ?? this.valuationInsight,
      marketValueSource: marketValueSource ?? this.marketValueSource,
      bookValueUpdatedAt: bookValueUpdatedAt ?? this.bookValueUpdatedAt,
    );
  }

  factory AssetValue.fromJson(Map<String, dynamic> json) {
    try {
      return AssetValue(
        purchasePrice: (json['purchasePrice'] as num?)?.toInt() ?? 0,
        currentUsedPrice: (json['currentUsedPrice'] as num?)?.toInt() ?? 0,
        depreciationRate: ((json['depreciationRate'] as num?) ?? 0).toDouble(),
        lastPriceCheck: json['lastPriceCheck']?.toString() ?? '',
        priceHistory: (json['priceHistory'] as List<dynamic>?)
                ?.map((e) {
                  try {
                    return PriceHistory.fromJson(e as Map<String, dynamic>);
                  } catch (e) {
                    print('Error parsing PriceHistory: $e');
                    return null;
                  }
                })
                .whereType<PriceHistory>()
                .toList() ??
            [],
        bookValue: (json['bookValue'] as num?)?.toInt(),
        marketValue: (json['marketValue'] as num?)?.toInt(),
        hasSellOpportunity: json['hasSellOpportunity'] as bool?,
        usefulLife: (json['usefulLife'] as num?)?.toDouble(),
        valuationInsight: json['valuationInsight']?.toString(),
        marketValueSource: json['marketValueSource']?.toString(),
        bookValueUpdatedAt: json['bookValueUpdatedAt']?.toString(),
      );
    } catch (e) {
      print('Error parsing AssetValue: $e');
      return AssetValue(
        purchasePrice: 0,
        currentUsedPrice: 0,
        depreciationRate: 0.0,
        lastPriceCheck: '',
        priceHistory: [],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'purchasePrice': purchasePrice,
      'currentUsedPrice': currentUsedPrice,
      'depreciationRate': depreciationRate,
      'lastPriceCheck': lastPriceCheck,
      'priceHistory': priceHistory.map((e) => e.toJson()).toList(),
      if (bookValue != null) 'bookValue': bookValue,
      if (marketValue != null) 'marketValue': marketValue,
      if (hasSellOpportunity != null) 'hasSellOpportunity': hasSellOpportunity,
      if (usefulLife != null) 'usefulLife': usefulLife,
      if (valuationInsight != null) 'valuationInsight': valuationInsight,
      if (marketValueSource != null) 'marketValueSource': marketValueSource,
      if (bookValueUpdatedAt != null) 'bookValueUpdatedAt': bookValueUpdatedAt,
    };
  }
}

class PriceHistory {
  final String date;
  final int price;

  PriceHistory({
    required this.date,
    required this.price,
  });

  factory PriceHistory.fromJson(Map<String, dynamic> json) {
    try {
      return PriceHistory(
        date: json['date']?.toString() ?? '',
        price: (json['price'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      print('Error parsing PriceHistory: $e');
      return PriceHistory(
        date: '',
        price: 0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'price': price,
    };
  }
}
