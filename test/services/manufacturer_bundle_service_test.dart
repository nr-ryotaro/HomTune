import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/models/manufacturer_bundle.dart';
import 'package:homtune/models/room.dart';
import 'package:homtune/services/manufacturer_bundle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ManufacturerBundleService', () {
    tearDown(() {
      ManufacturerBundleService.instance.resetCache();
    });

    test('loads bundles from asset', () async {
      final bundles = await ManufacturerBundleService.instance.loadBundles();
      expect(bundles, isNotEmpty);
      expect(bundles.any((b) => b.id == 'panasonic_living_core'), isTrue);
      expect(bundles.first.devices, isNotEmpty);
    });

    test('buildRegistrationItems skips already registered model', () async {
      final bundles = await ManufacturerBundleService.instance.loadBundles();
      final bundle = bundles.firstWhere((b) => b.id == 'sony_living_entertainment');
      final rooms = [
        Room(
          id: 'living-room',
          name: 'リビング',
          type: 'living_room',
          floor: 1,
          coordinates: RoomCoordinates(x: 0, y: 0, width: 0, height: 0),
          devices: [],
        ),
      ];
      final registered = [
        Device(
          id: 'tv_001',
          name: 'BRAVIA',
          modelNumber: 'XRJ-65A95K',
          category: 'テレビ',
          manufacturer: 'SONY',
          purchaseDate: '2023-01-01',
          purchasePrice: 450000,
          yearsOwned: 2,
          room: 'living-room',
          location: '',
          status: 'active',
          consumables: [],
          photos: [],
          documents: [],
          archetypeId: 'living_tv',
        ),
      ];

      final items = ManufacturerBundleService.instance.buildRegistrationItems(
        bundle: bundle,
        userRooms: rooms,
        registeredDevices: registered,
        baseTimestampMs: 1000,
      );

      expect(items.length, bundle.deviceCount - 1);
      expect(items.every((i) => i.device.modelNumber != 'XRJ-65A95K'), isTrue);
    });

    test('resolveRoomId maps kitchen template to user room', () {
      final rooms = [
        Room(
          id: 'kitchen-01',
          name: 'キッチン',
          type: 'kitchen',
          floor: 1,
          coordinates: RoomCoordinates(x: 0, y: 0, width: 0, height: 0),
          devices: [],
        ),
      ];
      final resolved = ManufacturerBundleService.instance.resolveRoomId(
        'kitchen-01',
        rooms,
      );
      expect(resolved, 'kitchen-01');
    });
  });
}
