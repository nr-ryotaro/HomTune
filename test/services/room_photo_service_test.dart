import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/services/room_photo_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to sample asset when no custom path', () async {
    final path = await RoomPhotoService.imagePathForRoom('living-room');
    expect(path, contains('Living_sample.jpg'));
  });

  test('appliance and room photo flags persist', () async {
    expect(await RoomPhotoService.isApplianceSetupDone(), isFalse);
    await RoomPhotoService.setApplianceSetupDone(true);
    expect(await RoomPhotoService.isApplianceSetupDone(), isTrue);

    await RoomPhotoService.setCustomImagePath('kitchen-01', '/tmp/kitchen.jpg');
    expect(
      await RoomPhotoService.getCustomImagePath('kitchen-01'),
      '/tmp/kitchen.jpg',
    );
    final path = await RoomPhotoService.imagePathForRoom('kitchen-01');
    expect(path, '/tmp/kitchen.jpg');

    await RoomPhotoService.setRoomPhotosConfigured(true);
    expect(await RoomPhotoService.isRoomPhotosConfigured(), isTrue);
  });
}
