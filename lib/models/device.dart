import 'safety_info.dart';
import 'maintenance_task.dart';
import 'device_enums.dart';
import 'device_maintenance.dart';
import 'device_manual.dart';
import 'device_warranty.dart';
import 'device_asset.dart';
import 'device_remote_link.dart';

export 'device_enums.dart';
export 'device_remote_link.dart';
export 'device_maintenance.dart';
export 'device_manual.dart';
export 'device_warranty.dart';
export 'device_asset.dart';

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
  final List<MaintenanceTask> maintenanceTasks;
  final String? archetypeId;
  final String? customDisplayName;
  final String? customIcon;
  final DeviceRemoteLink? remoteLink;

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
    List<MaintenanceTask>? maintenanceTasks,
    this.archetypeId,
    this.customDisplayName,
    this.customIcon,
    this.remoteLink,
  }) : maintenanceTasks = maintenanceTasks ?? [];

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
        maintenanceTasks: (json['maintenanceTasks'] as List<dynamic>?)
                ?.map(
                    (e) => MaintenanceTask.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        archetypeId: json['archetypeId']?.toString(),
        customDisplayName: json['customDisplayName']?.toString(),
        customIcon: json['customIcon']?.toString(),
        remoteLink: json['remoteLink'] != null
            ? DeviceRemoteLink.fromJson(
                json['remoteLink'] as Map<String, dynamic>,
              )
            : null,
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
      'maintenanceTasks': maintenanceTasks.map((e) => e.toJson()).toList(),
      if (archetypeId != null && archetypeId!.isNotEmpty)
        'archetypeId': archetypeId,
      if (customDisplayName != null && customDisplayName!.isNotEmpty)
        'customDisplayName': customDisplayName,
      if (customIcon != null && customIcon!.isNotEmpty)
        'customIcon': customIcon,
      if (remoteLink != null) 'remoteLink': remoteLink!.toJson(),
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
    List<MaintenanceTask>? maintenanceTasks,
    String? archetypeId,
    String? customDisplayName,
    String? customIcon,
    DeviceRemoteLink? remoteLink,
    bool clearRemoteLink = false,
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
      maintenanceTasks: maintenanceTasks ?? this.maintenanceTasks,
      archetypeId: archetypeId ?? this.archetypeId,
      customDisplayName: customDisplayName ?? this.customDisplayName,
      customIcon: customIcon ?? this.customIcon,
      remoteLink: clearRemoteLink ? null : (remoteLink ?? this.remoteLink),
    );
  }
}
