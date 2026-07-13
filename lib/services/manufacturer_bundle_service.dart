import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:flutter/foundation.dart';

import '../models/device.dart';
import '../models/manufacturer_bundle.dart';
import '../models/room.dart';

/// メーカー別家電バンドルの読み込み・デバイス生成
class ManufacturerBundleService {
  ManufacturerBundleService._();
  static final ManufacturerBundleService instance = ManufacturerBundleService._();

  List<ManufacturerBundle>? _bundles;

  Future<List<ManufacturerBundle>> loadBundles() async {
    if (_bundles != null) return _bundles!;
    final jsonStr =
        await rootBundle.loadString('assets/data/manufacturer-bundles.json');
    final raw = jsonDecode(jsonStr) as Map<String, dynamic>;
    _bundles = (raw['bundles'] as List<dynamic>? ?? [])
        .map((e) => ManufacturerBundle.fromJson(e as Map<String, dynamic>))
        .toList();
    return _bundles!;
  }

  Future<List<ManufacturerBundle>> bundlesForRooms(
    Iterable<String> roomTemplateIds,
  ) async {
    final all = await loadBundles();
    final roomSet = roomTemplateIds.toSet();
    return all
        .where((b) =>
            roomSet.contains(b.primaryRoomId) ||
            b.devices.any((d) => roomSet.contains(d.roomId)))
        .toList();
  }

  /// 未登録のバンドルのみ（型番または archetype+部屋 で重複除外）
  Future<List<ManufacturerBundle>> availableBundles({
    required List<Device> registeredDevices,
    Iterable<String> roomTemplateIds = const [],
  }) async {
    final candidates = roomTemplateIds.isEmpty
        ? await loadBundles()
        : await bundlesForRooms(roomTemplateIds);
    return candidates
        .where((b) => !isBundleFullyRegistered(b, registeredDevices))
        .toList();
  }

  bool isBundleFullyRegistered(
    ManufacturerBundle bundle,
    List<Device> registeredDevices,
  ) {
    final pending = pendingDevicesInBundle(bundle, registeredDevices);
    return pending.isEmpty;
  }

  List<ManufacturerBundleDevice> pendingDevicesInBundle(
    ManufacturerBundle bundle,
    List<Device> registeredDevices,
  ) {
    return bundle.devices
        .where((d) => !_isDeviceRegistered(d, registeredDevices))
        .toList();
  }

  bool _isDeviceRegistered(
    ManufacturerBundleDevice template,
    List<Device> registeredDevices,
  ) {
    final modelKey = template.modelNumber.trim().toUpperCase();
    if (modelKey.isNotEmpty) {
      for (final d in registeredDevices) {
        if (d.modelNumber.trim().toUpperCase() == modelKey) return true;
      }
    }
    for (final d in registeredDevices) {
      if (d.archetypeId == template.archetypeId &&
          _roomMatchesTemplate(d.room, template.roomId)) {
        return true;
      }
    }
    return false;
  }

  bool _roomMatchesTemplate(String deviceRoomId, String templateRoomId) {
    final dr = deviceRoomId.toLowerCase();
    final tr = templateRoomId.toLowerCase();
    if (dr == tr) return true;
    if (dr.contains(tr.replaceAll('-', '')) || tr.contains(dr)) return true;
    if (tr.contains('living') && dr.contains('living')) return true;
    if (tr.contains('kitchen') && dr.contains('kitchen')) return true;
    if (tr.contains('bedroom') && dr.contains('bedroom')) return true;
    return false;
  }

  /// ユーザーの部屋一覧からテンプレート roomId を実際の room.id に解決
  String resolveRoomId(String templateRoomId, List<Room> userRooms) {
    for (final room in userRooms) {
      final id = room.id.toLowerCase();
      final name = room.name.toLowerCase();
      switch (templateRoomId) {
        case 'living-room':
          if (id.contains('living') || name.contains('リビング')) return room.id;
          break;
        case 'kitchen-01':
          if (id.contains('kitchen') || name.contains('キッチン')) {
            return room.id;
          }
          break;
        case 'bedroom-01':
          if (id.contains('bedroom') || name.contains('寝室')) return room.id;
          break;
      }
    }
    if (userRooms.isNotEmpty) return userRooms.first.id;
    return templateRoomId;
  }

  List<BundleRegistrationItem> buildRegistrationItems({
    required ManufacturerBundle bundle,
    required List<Room> userRooms,
    required List<Device> registeredDevices,
    int? baseTimestampMs,
  }) {
    final base = baseTimestampMs ?? DateTime.now().millisecondsSinceEpoch;
    final pending = pendingDevicesInBundle(bundle, registeredDevices);
    final items = <BundleRegistrationItem>[];
    for (var i = 0; i < pending.length; i++) {
      final template = pending[i];
      final roomId = resolveRoomId(template.roomId, userRooms);
      final deviceId = 'bundle-$base-$i';
      items.add(
        BundleRegistrationItem(
          archetypeId: template.archetypeId,
          device: template.toDevice(
            resolvedRoomId: roomId,
            deviceId: deviceId,
          ),
        ),
      );
    }
    return items;
  }

  @visibleForTesting
  void resetCache() => _bundles = null;
}
