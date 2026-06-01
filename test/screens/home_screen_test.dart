import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:homtune/screens/home_screen.dart';
import 'package:homtune/services/device_service.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/models/room.dart';
import 'package:homtune/models/room_card_model.dart';
import 'package:homtune/services/config_service.dart';
// Ensure Manual is available. It is in device.dart usually.

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
        room: 'living', // room id
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
  Future<void> onMaintenanceTasksUpdated(String deviceId) async {}
  @override
  String? consumePendingUserMessage() => null;
  @override
  Future<void> updateDeviceManual(String deviceId, Manual manual) async {}
  @override
  Future<void> deleteDevice(String id) async {}
  @override
  Future<void> refresh() async {}
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
}
