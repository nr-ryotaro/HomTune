import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/data/repositories/device_repository.dart';
import 'package:homtune/data/sources/device_local_source.dart';
import 'package:homtune/models/device.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DeviceRepository', () {
    test('isSeedDevice identifies demo ids', () {
      final repo = DeviceRepository();
      expect(repo.isSeedDevice('tv_001'), isTrue);
      expect(repo.isSeedDevice('user-custom-001'), isFalse);
    });

    test('mergeUserDevices prefers later in-memory over persisted', () {
      final repo = DeviceRepository();
      final persisted = [
        _device(id: 'user-1', name: 'Old Name'),
      ];
      final inMemory = [
        _device(id: 'user-1', name: 'New Name'),
        _device(id: 'user-2', name: 'Second'),
      ];
      final merged = repo.mergeUserDevices(
        persisted: persisted,
        inMemory: inMemory,
      );
      expect(merged.length, 2);
      expect(
        merged.firstWhere((d) => d.id == 'user-1').name,
        'New Name',
      );
    });

    test('persistUserDevices excludes seed devices', () async {
      final local = DeviceLocalSource();
      final repo = DeviceRepository(localSource: local);
      await repo.persistUserDevices([
        _device(id: 'tv_001', name: 'Seed'),
        _device(id: 'user-x', name: 'User'),
      ]);
      final loaded = await repo.loadPersistedUserDevices();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'user-x');
    });

    test('loadPersistedUserDevices round-trips user device', () async {
      final repo = DeviceRepository();
      final user = _device(id: 'user-roundtrip', name: 'Round');
      await repo.persistUserDevices([user]);
      final loaded = await repo.loadPersistedUserDevices();
      expect(loaded.single.id, 'user-roundtrip');
      expect(loaded.single.name, 'Round');
    });
  });
}

Device _device({required String id, required String name}) {
  return Device(
    id: id,
    name: name,
    modelNumber: 'M-1',
    category: 'Other',
    manufacturer: 'TestCo',
    purchaseDate: '2024-01-01',
    purchasePrice: 10000,
    yearsOwned: 1,
    room: 'living-room',
    location: 'floor',
    status: 'active',
    consumables: [],
    photos: [],
    documents: [],
  );
}
