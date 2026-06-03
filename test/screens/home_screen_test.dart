import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:homtune/screens/home_screen.dart';
import 'package:homtune/models/asset_refresh_result.dart';
import 'package:homtune/models/market_refresh_mode.dart';
import 'package:homtune/services/device_service.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/models/room.dart';
import 'package:homtune/services/config_service.dart';
import 'package:homtune/screens/room_devices_screen.dart';
import 'package:homtune/widgets/device_detail_card.dart';

// Mock DeviceService
class MockDeviceService extends ChangeNotifier implements DeviceService {
  @override
  List<Device> devices = [];
  @override
  List<Room> rooms = [];
  @override
  bool isLoading = false;
  @override
  String? errorMessage;
  @override
  FloorPlan? get floorPlan => null;

  @override
  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100));
    // Mock data based on _getRooms in HomeScreen
    rooms = [
      Room(
        id: 'living',
        name: 'Living Room',
        type: 'living_room',
        floor: 1,
        coordinates: RoomCoordinates(x: 0, y: 0, width: 100, height: 100),
        devices: ['1'],
      ),
      Room(
        id: 'bedroom',
        name: 'Bedroom',
        type: 'bedroom',
        floor: 1,
        coordinates: RoomCoordinates(x: 0, y: 0, width: 100, height: 100),
        devices: [],
      ),
      Room(
        id: 'kitchen',
        name: 'Kitchen',
        type: 'kitchen',
        floor: 1,
        coordinates: RoomCoordinates(x: 0, y: 0, width: 100, height: 100),
        devices: [],
      ),
    ];
    devices = [
      Device(
        id: '1',
        name: 'AC',
        modelNumber: 'CS-101',
        category: 'ac',
        manufacturer: 'Panasonic',
        purchaseDate: '2025-01-01',
        purchasePrice: 100000,
        yearsOwned: 1.0,
        room: 'living-room',
        location: 'Wall',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
      ),
    ];
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }

  @override
  List<Device> getDevicesByRoom(String roomId) {
    if (devices.isEmpty) return [];
    return devices.where((d) => d.room == roomId).toList();
  }

  @override
  int getDeviceCountForRoom(String roomId) {
    return devices.where((d) => d.room == roomId).length;
  }

  @override
  Device? getDeviceById(String deviceId) {
    if (devices.isEmpty) return null;
    try {
      return devices.firstWhere((d) => d.id == deviceId);
    } catch (e) {
      return null;
    }
  }

  @override
  int getAlertCount() => 0;
  @override
  int getMaintenanceCount() => 0;

  // Stubs for unused methods
  @override
  Future<void> addDevice(Device device, {String? archetypeId}) async {}
  @override
  Future<void> updateDeviceManualState(
    String deviceId,
    ManualFetchState state,
  ) async {}
  @override
  Future<void> updateDevice(Device device) async {}
  @override
  Future<void> updateDeviceAppearance(
    String deviceId, {
    String? displayName,
    String? icon,
    bool resetToDefault = false,
  }) async {}
  @override
  Future<void> onMaintenanceTasksUpdated(String deviceId) async {}
  @override
  String? consumePendingUserMessage() => null;
  @override
  Future<void> updateDeviceManual(String deviceId, Manual manual) async {}
  @override
  Future<void> deleteDevice(String id) async {}
  @override
  Future<void> refresh() async {}
  @override
  Future<AssetRefreshResult?> refreshDeviceAssetValue(
    String deviceId, {
    required ConfigService config,
    MarketRefreshMode mode = MarketRefreshMode.local,
  }) async =>
      null;
}

void main() {
  testWidgets('HomeScreen initializes without crash', (
    WidgetTester tester,
  ) async {
    final mockService = MockDeviceService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DeviceService>.value(value: mockService),
          ChangeNotifierProvider<ConfigService>.value(value: ConfigService()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    // Initial load (show loading or empty)
    await tester.pump();

    // Trigger post frame callback and wait for mock load
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(); // Rebuild after setState
    // Use pump instead of pumpAndSettle if animations are indefinite, but here loading should be done.
    // If loading is done, no more indefinite animations (unless PageView has one?)

    // Verify Carousel is present
    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('My Rooms'), findsOneWidget);

    // Verify Living Room (default selected) content is shown
    expect(find.text('Living Room'), findsOneWidget);
  });

  testWidgets('Room card arrow opens RoomDevicesScreen when room has devices', (
    WidgetTester tester,
  ) async {
    final mockService = MockDeviceService();
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DeviceService>.value(value: mockService),
          ChangeNotifierProvider<ConfigService>.value(value: ConfigService()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.byType(RoomDevicesScreen), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_forward).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(RoomDevicesScreen), findsOneWidget);
    expect(find.byType(DeviceDetailCard), findsOneWidget);
    expect(find.text('CS-101'), findsOneWidget);
  });
}
