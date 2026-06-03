import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/device.dart';

/// SharedPreferences によるユーザーデバイス永続化。
class DeviceLocalSource {
  static const String userDevicesStorageKey = 'user_devices';

  static const Set<String> seedDeviceIds = {
    'tv_001',
    'speaker_001',
    'record_player_001',
    'humidifier_001',
    'sofa_001',
    'tv_bed_001',
    'bed_001',
    'light_bed_001',
    'smart_speaker_bed_001',
    'cabinet_bed_001',
    'fridge_001',
    'oven_001',
    'espresso_001',
    'rice_cooker_001',
    'light_kitchen_001',
  };

  bool isSeedDevice(String id) => seedDeviceIds.contains(id);

  Future<void> saveUserDevices(List<Device> userDevices) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded =
          jsonEncode(userDevices.map((d) => d.toJson()).toList());
      await prefs.setString(userDevicesStorageKey, encoded);
    } catch (e) {
      print('Error persisting user devices: $e');
    }
  }

  Future<List<Device>> loadUserDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(userDevicesStorageKey);
      if (stored == null || stored.isEmpty) return [];

      final list = jsonDecode(stored) as List<dynamic>;
      return list
          .map((e) => Device.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading persisted user devices: $e');
      return [];
    }
  }
}
