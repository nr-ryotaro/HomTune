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
  final Maintenance? maintenance;
  final Manual? manual;
  final List<Consumable> consumables;
  final Warranty? warranty;
  final AssetValue? assetValue;
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
    required this.consumables,
    this.warranty,
    this.assetValue,
    required this.photos,
    required this.documents,
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
                  return Maintenance.fromJson(json['maintenance'] as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing maintenance for device ${json['id']}: $e');
                  return null;
                }
              })()
            : null,
        manual: json['manual'] != null 
            ? (() {
                try {
                  return Manual.fromJson(json['manual'] as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing manual for device ${json['id']}: $e');
                  return null;
                }
              })()
            : null,
        consumables: (json['consumables'] as List<dynamic>?)
                ?.map((e) => Consumable.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        warranty: json['warranty'] != null
            ? (() {
                try {
                  return Warranty.fromJson(json['warranty'] as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing warranty for device ${json['id']}: $e');
                  return null;
                }
              })()
            : null,
        assetValue: json['assetValue'] != null
            ? (() {
                try {
                  return AssetValue.fromJson(json['assetValue'] as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing assetValue for device ${json['id']}: $e');
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
      'consumables': consumables.map((e) => e.toJson()).toList(),
      'warranty': warranty?.toJson(),
      'assetValue': assetValue?.toJson(),
      'photos': photos,
      'documents': documents,
    };
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
                    return MaintenanceHistory.fromJson(e as Map<String, dynamic>);
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
  final String url;
  final bool autoGenerated;
  final String lastUpdated;

  Manual({
    required this.url,
    required this.autoGenerated,
    required this.lastUpdated,
  });

  factory Manual.fromJson(Map<String, dynamic> json) {
    try {
      return Manual(
        url: json['url']?.toString() ?? '',
        autoGenerated: json['autoGenerated'] == true,
        lastUpdated: json['lastUpdated']?.toString() ?? '',
      );
    } catch (e) {
      print('Error parsing Manual: $e');
      return Manual(
        url: '',
        autoGenerated: false,
        lastUpdated: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'autoGenerated': autoGenerated,
      'lastUpdated': lastUpdated,
    };
  }
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
        replacementInterval: (json['replacementInterval'] as num?)?.toInt() ?? 0,
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
            ? WarrantyInfo.fromJson(json['manufacturer'] as Map<String, dynamic>)
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

  AssetValue({
    required this.purchasePrice,
    required this.currentUsedPrice,
    required this.depreciationRate,
    required this.lastPriceCheck,
    required this.priceHistory,
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
