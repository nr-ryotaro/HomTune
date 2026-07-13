import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homtune/services/onboarding_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('getSelectedRoomIds returns saved onboarding selection', () async {
    SharedPreferences.setMockInitialValues({
      OnboardingPrefs.keySelectedRooms: [
        'living-room',
        'kitchen-01',
        'entrance',
      ],
    });
    final ids = await OnboardingPrefs.getSelectedRoomIds();
    expect(ids, ['living-room', 'kitchen-01', 'entrance']);
  });

  test('setSelectedRoomIds persists cleaned ids', () async {
    SharedPreferences.setMockInitialValues({});
    await OnboardingPrefs.setSelectedRoomIds([
      'living-room',
      '  ',
      'entrance',
    ]);
    final ids = await OnboardingPrefs.getSelectedRoomIds();
    expect(ids, ['living-room', 'entrance']);
  });

  test('OnboardingRoomCatalog has entrance and study cards', () {
    expect(OnboardingRoomCatalog.cardById.containsKey('entrance'), isTrue);
    expect(OnboardingRoomCatalog.cardById.containsKey('study'), isTrue);
  });
}
