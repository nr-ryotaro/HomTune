import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/services/room_name_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('default room names are generic', () {
    expect(RoomNameService.defaultNameForIndex(0), '部屋1');
    expect(RoomNameService.defaultNameForIndex(2), '部屋3');
  });

  test('custom display names persist', () async {
    final service = RoomNameService.instance;
    await service.setDisplayName('living-room', 'ダイニング');
    expect(service.displayNameFor('living-room'), 'ダイニング');
    await service.load();
    expect(service.displayNameFor('living-room'), 'ダイニング');
  });
}
