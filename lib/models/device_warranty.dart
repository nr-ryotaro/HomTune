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
