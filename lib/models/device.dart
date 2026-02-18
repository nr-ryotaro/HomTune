import 'safety_info.dart';

enum ItemCondition { newItem, usedItem }

enum ManualFetchState { notFetched, fetching, found, notFound }

class Device {
  final String id;
  final String name;
  final String modelNumber;
  final String category;
  final String manufacturer;
  final String purchaseDate;
  final int purchasePrice;
  final double yearsOwned;
  final String room;
  final String location;
  final String status;
  // マニュアル取得状態
  final String? manualPdfUrl;
  final ManualFetchState manualState;

  // 新規追加フィールド
  final ItemCondition condition;
  final DateTime? releaseDate;
  final int? originalPrice;

  final Maintenance? maintenance;
  final Manual? manual;

  /// 説明書PDFのURL（Manual.url と同じ。Smart Ingester で自動検索した場合に保存）
  // String? get manualUrl => manual?.url; // 既存のmanualUrlゲッターはmanualPdfUrlと重複するため削除または統合

  /// JANコード（バーコードスキャンで取得。Smart Ingester 用）
  final String? janCode;
  final List<Consumable> consumables;
  final Warranty? warranty;
  final AssetValue? assetValue;
  final SafetyInfo? safetyInfo;
  final List<String> photos;
  final List<String> documents;

  Device({
    required this.id,
    required this.name,
    required this.modelNumber,
    required this.category,
    required this.manufacturer,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.yearsOwned,
    required this.room,
    required this.location,
    required this.status,
    this.maintenance,
    this.manual,
    this.janCode,
    required this.consumables,
    this.warranty,
    this.assetValue,
    this.safetyInfo,
    required this.photos,
    required this.documents,
    this.condition = ItemCondition.newItem,
    this.releaseDate,
    this.originalPrice,
    this.manualPdfUrl,
    this.manualState = ManualFetchState.notFetched,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    try {
      return Device(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        modelNumber: json['modelNumber']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        manufacturer: json['manufacturer']?.toString() ?? '',
        purchaseDate: json['purchaseDate']?.toString() ?? '',
        purchasePrice: (json['purchasePrice'] as num?)?.toInt() ?? 0,
        yearsOwned: ((json['yearsOwned'] as num?) ?? 0).toDouble(),
        room: json['room']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        status: json['status']?.toString() ?? 'active',
        maintenance: json['maintenance'] != null
            ? (() {
                try {
                  return Maintenance.fromJson(
                      json['maintenance'] as Map<String, dynamic>);
                } catch (e) {
                  print(
                      'Error parsing maintenance for device ${json['id']}: $e');
                  return null;
                }
              })()
            : null,
        manual: json['manual'] != null
            ? (() {
                try {
                  return Manual.fromJson(
                      json['manual'] as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing manual for device ${json['id']}: $e');
                  return null;
                }
              })()
            : null,
        janCode: json['janCode']?.toString(),
        consumables: (json['consumables'] as List<dynamic>?)
                ?.map((e) => Consumable.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        warranty: json['warranty'] != null
            ? (() {
                try {
                  return Warranty.fromJson(
                      json['warranty'] as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing warranty for device ${json['id']}: $e');
                  return null;
                }
              })()
            : null,
        assetValue: json['assetValue'] != null
            ? (() {
                try {
                  return AssetValue.fromJson(
                      json['assetValue'] as Map<String, dynamic>);
                } catch (e) {
                  print(
                      'Error parsing assetValue for device ${json['id']}: $e');
                  return null;
                }
              })()
            : null,
        safetyInfo: json['safetyInfo'] != null
            ? (() {
                try {
                  return SafetyInfo.fromJson(
                      json['safetyInfo'] as Map<String, dynamic>);
                } catch (e) {
                  print(
                      'Error parsing safetyInfo for device ${json['id']}: $e');
                  return null;
                }
              })()
            : null,
        photos: (json['photos'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        documents: (json['documents'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        condition: json['condition'] == 'usedItem'
            ? ItemCondition.usedItem
            : ItemCondition.newItem,
        releaseDate: json['releaseDate'] != null
            ? DateTime.tryParse(json['releaseDate'].toString())
            : null,
        originalPrice: (json['originalPrice'] as num?)?.toInt(),
        manualPdfUrl: json['manualPdfUrl']?.toString(),
        manualState: json['manualState'] != null
            ? ManualFetchState.values.firstWhere(
                (e) => e.name == json['manualState'],
                orElse: () => ManualFetchState.notFetched)
            : ManualFetchState.notFetched,
      );
    } catch (e) {
      print('Error parsing Device: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'modelNumber': modelNumber,
      'category': category,
      'manufacturer': manufacturer,
      'purchaseDate': purchaseDate,
      'purchasePrice': purchasePrice,
      'yearsOwned': yearsOwned,
      'room': room,
      'location': location,
      'status': status,
      'maintenance': maintenance?.toJson(),
      'manual': manual?.toJson(),
      'janCode': janCode,
      'consumables': consumables.map((e) => e.toJson()).toList(),
      'warranty': warranty?.toJson(),
      'assetValue': assetValue?.toJson(),
      'safetyInfo': safetyInfo?.toJson(),
      'photos': photos,
      'documents': documents,
      'condition': condition.name,
      'releaseDate': releaseDate?.toIso8601String(),
      'originalPrice': originalPrice,
      'manualPdfUrl': manualPdfUrl,
      'manualState': manualState.name,
    };
  }

  Device copyWith({
    String? id,
    String? name,
    String? modelNumber,
    String? category,
    String? manufacturer,
    String? purchaseDate,
    int? purchasePrice,
    double? yearsOwned,
    String? room,
    String? location,
    String? status,
    Maintenance? maintenance,
    Manual? manual,
    String? janCode,
    List<Consumable>? consumables,
    Warranty? warranty,
    AssetValue? assetValue,
    SafetyInfo? safetyInfo,
    List<String>? photos,
    List<String>? documents,
    ItemCondition? condition,
    DateTime? releaseDate,
    int? originalPrice,
    String? manualPdfUrl,
    ManualFetchState? manualState,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      modelNumber: modelNumber ?? this.modelNumber,
      category: category ?? this.category,
      manufacturer: manufacturer ?? this.manufacturer,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      yearsOwned: yearsOwned ?? this.yearsOwned,
      room: room ?? this.room,
      location: location ?? this.location,
      status: status ?? this.status,
      maintenance: maintenance ?? this.maintenance,
      manual: manual ?? this.manual,
      janCode: janCode ?? this.janCode,
      consumables: consumables ?? this.consumables,
      warranty: warranty ?? this.warranty,
      assetValue: assetValue ?? this.assetValue,
      safetyInfo: safetyInfo ?? this.safetyInfo,
      photos: photos ?? this.photos,
      documents: documents ?? this.documents,
      condition: condition ?? this.condition,
      releaseDate: releaseDate ?? this.releaseDate,
      originalPrice: originalPrice ?? this.originalPrice,
      manualPdfUrl: manualPdfUrl ?? this.manualPdfUrl,
      manualState: manualState ?? this.manualState,
    );
  }
}

class Maintenance {
  final String? lastMaintenance;
  final String? nextMaintenance;
  final int? maintenanceInterval;
  final List<Alert> alerts;
  final List<MaintenanceHistory> history;

  Maintenance({
    this.lastMaintenance,
    this.nextMaintenance,
    this.maintenanceInterval,
    required this.alerts,
    required this.history,
  });

  factory Maintenance.fromJson(Map<String, dynamic> json) {
    try {
      return Maintenance(
        lastMaintenance: json['lastMaintenance']?.toString(),
        nextMaintenance: json['nextMaintenance']?.toString(),
        maintenanceInterval: (json['maintenanceInterval'] as num?)?.toInt(),
        alerts: (json['alerts'] as List<dynamic>?)
                ?.map((e) {
                  try {
                    return Alert.fromJson(e as Map<String, dynamic>);
                  } catch (e) {
                    print('Error parsing Alert: $e');
                    return null;
                  }
                })
                .whereType<Alert>()
                .toList() ??
            [],
        history: (json['history'] as List<dynamic>?)
                ?.map((e) {
                  try {
                    return MaintenanceHistory.fromJson(
                        e as Map<String, dynamic>);
                  } catch (e) {
                    print('Error parsing MaintenanceHistory: $e');
                    return null;
                  }
                })
                .whereType<MaintenanceHistory>()
                .toList() ??
            [],
      );
    } catch (e) {
      print('Error parsing Maintenance: $e');
      // エラー時は空のMaintenanceを返す
      return Maintenance(
        alerts: [],
        history: [],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'lastMaintenance': lastMaintenance,
      'nextMaintenance': nextMaintenance,
      'maintenanceInterval': maintenanceInterval,
      'alerts': alerts.map((e) => e.toJson()).toList(),
      'history': history.map((e) => e.toJson()).toList(),
    };
  }
}

class Alert {
  final String type;
  final String message;
  final String priority;
  final String createdAt;

  Alert({
    required this.type,
    required this.message,
    required this.priority,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    try {
      return Alert(
        type: json['type']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        priority: json['priority']?.toString() ?? 'low',
        createdAt: json['createdAt']?.toString() ?? '',
      );
    } catch (e) {
      print('Error parsing Alert: $e');
      return Alert(
        type: '',
        message: '',
        priority: 'low',
        createdAt: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
      'priority': priority,
      'createdAt': createdAt,
    };
  }
}

class MaintenanceHistory {
  final String date;
  final String type;
  final String notes;

  MaintenanceHistory({
    required this.date,
    required this.type,
    required this.notes,
  });

  factory MaintenanceHistory.fromJson(Map<String, dynamic> json) {
    try {
      return MaintenanceHistory(
        date: json['date']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
      );
    } catch (e) {
      print('Error parsing MaintenanceHistory: $e');
      return MaintenanceHistory(
        date: '',
        type: '',
        notes: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'type': type,
      'notes': notes,
    };
  }
}

class Manual {
  /// URLまたはローカルファイルパス
  /// - 外部URL: `https://example.com/manual.pdf`
  /// - ローカルファイル: `file:///path/to/manual.pdf`
  final String url;
  final bool autoGenerated;
  final String lastUpdated;

  /// マニュアルのソース: 'official' (公式サイト), 'scanned' (スキャン生成), 'uploaded' (アップロード)
  final String source;

  Manual({
    required this.url,
    required this.autoGenerated,
    required this.lastUpdated,
    this.source = 'official',
  });

  factory Manual.fromJson(Map<String, dynamic> json) {
    try {
      return Manual(
        url: json['url']?.toString() ?? '',
        autoGenerated: json['autoGenerated'] == true,
        lastUpdated: json['lastUpdated']?.toString() ?? '',
        source: json['source']?.toString() ?? 'official',
      );
    } catch (e) {
      print('Error parsing Manual: $e');
      return Manual(
        url: '',
        autoGenerated: false,
        lastUpdated: '',
        source: 'official',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'autoGenerated': autoGenerated,
      'lastUpdated': lastUpdated,
      'source': source,
    };
  }

  /// ローカルファイルかどうかを判定
  bool get isLocalFile => url.startsWith('file://');

  /// 外部URLかどうかを判定
  bool get isExternalUrl => !isLocalFile && url.isNotEmpty;
}

class Consumable {
  final String id;
  final String name;
  final String modelNumber;
  final String purchaseUrl;
  final String lastReplaced;
  final int replacementInterval;
  final String stockLocation;
  final bool inStock;

  Consumable({
    required this.id,
    required this.name,
    required this.modelNumber,
    required this.purchaseUrl,
    required this.lastReplaced,
    required this.replacementInterval,
    required this.stockLocation,
    required this.inStock,
  });

  factory Consumable.fromJson(Map<String, dynamic> json) {
    try {
      return Consumable(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        modelNumber: json['modelNumber']?.toString() ?? '',
        purchaseUrl: json['purchaseUrl']?.toString() ?? '',
        lastReplaced: json['lastReplaced']?.toString() ?? '',
        replacementInterval:
            (json['replacementInterval'] as num?)?.toInt() ?? 0,
        stockLocation: json['stockLocation']?.toString() ?? '',
        inStock: json['inStock'] == true,
      );
    } catch (e) {
      print('Error parsing Consumable: $e');
      return Consumable(
        id: '',
        name: '',
        modelNumber: '',
        purchaseUrl: '',
        lastReplaced: '',
        replacementInterval: 0,
        stockLocation: '',
        inStock: false,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'modelNumber': modelNumber,
      'purchaseUrl': purchaseUrl,
      'lastReplaced': lastReplaced,
      'replacementInterval': replacementInterval,
      'stockLocation': stockLocation,
      'inStock': inStock,
    };
  }
}

class Warranty {
  final WarrantyInfo? manufacturer;
  final WarrantyInfo? store;
  final WarrantyInfo? extended;

  Warranty({
    this.manufacturer,
    this.store,
    this.extended,
  });

  factory Warranty.fromJson(Map<String, dynamic> json) {
    try {
      return Warranty(
        manufacturer: json['manufacturer'] != null
            ? WarrantyInfo.fromJson(
                json['manufacturer'] as Map<String, dynamic>)
            : null,
        store: json['store'] != null
            ? WarrantyInfo.fromJson(json['store'] as Map<String, dynamic>)
            : null,
        extended: json['extended'] != null
            ? WarrantyInfo.fromJson(json['extended'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      print('Error parsing Warranty: $e');
      return Warranty();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'manufacturer': manufacturer?.toJson(),
      'store': store?.toJson(),
      'extended': extended?.toJson(),
    };
  }
}

class WarrantyInfo {
  final int period;
  final String expiryDate;
  final bool expired;

  WarrantyInfo({
    required this.period,
    required this.expiryDate,
    required this.expired,
  });

  factory WarrantyInfo.fromJson(Map<String, dynamic> json) {
    try {
      return WarrantyInfo(
        period: (json['period'] as num?)?.toInt() ?? 0,
        expiryDate: json['expiryDate']?.toString() ?? '',
        expired: json['expired'] == true,
      );
    } catch (e) {
      print('Error parsing WarrantyInfo: $e');
      return WarrantyInfo(
        period: 0,
        expiryDate: '',
        expired: false,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'expiryDate': expiryDate,
      'expired': expired,
    };
  }
}

class AssetValue {
  final int purchasePrice;
  final int currentUsedPrice;
  final double depreciationRate;
  final String lastPriceCheck;
  final List<PriceHistory> priceHistory;
  final int? bookValue; // 帳簿上の価値（減価償却残高）
  final int? marketValue; // 市場価値（中古相場）
  final bool? hasSellOpportunity; // 売却チャンスがあるか
  final double? usefulLife; // 法定耐用年数
  final String? valuationInsight; // 資産価値インサイト

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
  });

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
