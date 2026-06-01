import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/services/device_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('addDevice sets manualState fetching when model present', () async {
    final service = DeviceService();
    final device = Device(
      id: 'manual-fetch-001',
      name: 'テストエアコン',
      modelNumber: 'CS-ZX2811',
      category: 'エアコン',
      manufacturer: 'ダイキン',
      purchaseDate: '2025-01-01',
      purchasePrice: 100000,
      yearsOwned: 0,
      room: 'living-room',
      location: '壁',
      status: 'active',
      consumables: [],
      photos: [],
      documents: [],
    );

    await service.addDevice(device);
    final stored = service.getDeviceById('manual-fetch-001');
    expect(stored, isNotNull);
    expect(stored!.manualState, ManualFetchState.fetching);

    for (var i = 0; i < 50; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      final updated = service.getDeviceById('manual-fetch-001');
      if (updated?.manualState != ManualFetchState.fetching) break;
    }

    final finalDevice = service.getDeviceById('manual-fetch-001');
    expect(
      finalDevice?.manualState,
      anyOf(ManualFetchState.found, ManualFetchState.notFound),
    );
  });
}
