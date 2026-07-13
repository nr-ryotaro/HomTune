import 'device_enums.dart';
import 'device.dart';

/// メーカー別一括登録バンドル定義
class ManufacturerBundle {
  final String id;
  final String label;
  final String manufacturer;
  final String tagline;
  final String icon;
  final String accentColor;
  final String primaryRoomId;
  final List<ManufacturerBundleDevice> devices;

  const ManufacturerBundle({
    required this.id,
    required this.label,
    required this.manufacturer,
    required this.tagline,
    required this.icon,
    required this.accentColor,
    required this.primaryRoomId,
    required this.devices,
  });

  factory ManufacturerBundle.fromJson(Map<String, dynamic> json) {
    return ManufacturerBundle(
      id: json['id'] as String,
      label: json['label'] as String,
      manufacturer: json['manufacturer'] as String,
      tagline: json['tagline'] as String? ?? '',
      icon: json['icon'] as String? ?? '📦',
      accentColor: json['accentColor'] as String? ?? '#333333',
      primaryRoomId: json['primaryRoomId'] as String,
      devices: (json['devices'] as List<dynamic>? ?? [])
          .map((e) =>
              ManufacturerBundleDevice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  int get deviceCount => devices.length;
}

class ManufacturerBundleDevice {
  final String archetypeId;
  final String roomId;
  final String name;
  final String modelNumber;
  final String manufacturer;
  final String category;
  final int purchasePrice;
  final int monthsAgoPurchase;
  final String location;
  final String icon;

  const ManufacturerBundleDevice({
    required this.archetypeId,
    required this.roomId,
    required this.name,
    required this.modelNumber,
    required this.manufacturer,
    required this.category,
    required this.purchasePrice,
    required this.monthsAgoPurchase,
    required this.location,
    required this.icon,
  });

  factory ManufacturerBundleDevice.fromJson(Map<String, dynamic> json) {
    return ManufacturerBundleDevice(
      archetypeId: json['archetypeId'] as String,
      roomId: json['roomId'] as String,
      name: json['name'] as String,
      modelNumber: json['modelNumber'] as String,
      manufacturer: json['manufacturer'] as String,
      category: json['category'] as String,
      purchasePrice: (json['purchasePrice'] as num).toInt(),
      monthsAgoPurchase: (json['monthsAgoPurchase'] as num?)?.toInt() ?? 12,
      location: json['location'] as String? ?? '',
      icon: json['icon'] as String? ?? '📦',
    );
  }

  Device toDevice({
    required String resolvedRoomId,
    required String deviceId,
  }) {
    final purchaseDate = _purchaseDateFromMonthsAgo(monthsAgoPurchase);
    final yearsOwned = monthsAgoPurchase / 12.0;
    return Device(
      id: deviceId,
      name: name,
      modelNumber: modelNumber,
      category: category,
      manufacturer: manufacturer,
      purchaseDate: purchaseDate,
      purchasePrice: purchasePrice,
      yearsOwned: yearsOwned,
      room: resolvedRoomId,
      location: location,
      status: 'active',
      consumables: [],
      photos: [],
      documents: [],
      condition: ItemCondition.newItem,
      archetypeId: archetypeId,
      customIcon: icon,
    );
  }

  static String _purchaseDateFromMonthsAgo(int monthsAgo) {
    final now = DateTime.now();
    final totalMonths = now.month - 1 - monthsAgo;
    final year = now.year + totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final day = now.day.clamp(1, 28);
    return DateTime(year, month, day).toIso8601String().split('T').first;
  }
}

/// バンドルから生成した登録候補
class BundleRegistrationItem {
  final Device device;
  final String archetypeId;

  const BundleRegistrationItem({
    required this.device,
    required this.archetypeId,
  });
}
