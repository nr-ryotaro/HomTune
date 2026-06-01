import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/screens/onboarding_screen.dart';

void main() {
  test('studio default rooms are living and kitchen', () {
    final rooms = HousingType.studio.defaultRooms;
    expect(rooms.length, 2);
    expect(rooms.map((r) => r.id), ['living-room', 'kitchen-01']);
    expect(rooms.any((r) => r.id == 'bathroom'), isFalse);
  });

  test('oneLDK default rooms include kitchen not bathroom', () {
    final rooms = HousingType.oneLDK.defaultRooms;
    expect(rooms.length, 3);
    expect(rooms.map((r) => r.id),
        ['living-room', 'kitchen-01', 'bedroom-01']);
  });

  test('twoLDK default rooms include entrance', () {
    final rooms = HousingType.twoLDK.defaultRooms;
    expect(rooms.length, 4);
    expect(rooms.last.id, 'entrance');
    expect(rooms.any((r) => r.id == 'bathroom'), isFalse);
  });

  test('threeLDK default rooms include study and entrance', () {
    final rooms = HousingType.threeLDK.defaultRooms;
    expect(rooms.length, 5);
    expect(rooms.map((r) => r.id), contains('study'));
    expect(rooms.map((r) => r.id), contains('entrance'));
  });
}
