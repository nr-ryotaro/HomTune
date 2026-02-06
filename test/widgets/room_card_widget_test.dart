import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/room_card_model.dart';
import 'package:homtune/widgets/room_card_widget.dart';

void main() {
  testWidgets('RoomCardWidget renders correctly with NumberFormat',
      (WidgetTester tester) async {
    const room = RoomCardModel(
      id: 'test_id',
      title: 'Test Room',
      styleName: 'Test Style',
      imagePath: 'assets/images/test.jpg',
      totalAssetValue: 1234567,
      maintenanceHealth: 1.0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomCardWidget(
            room: room,
            onTap: () {},
          ),
        ),
      ),
    );

    // Verify Title
    expect(find.text('Test Room'), findsOneWidget);
    // Verify Price Format (Japanese Yen)
    // Note: Depends on locale implementation, but typically "¥1,234,567" or similar
    // We check for the number part at least
    expect(find.textContaining('1,234,567'), findsOneWidget);
    expect(find.textContaining('¥'), findsOneWidget);

    // Verify Icons (Device count is always visible, others are 0 so hidden in this mock)
    expect(find.byIcon(Icons.devices), findsOneWidget);
    expect(find.text('0'), findsWidgets); // Device count 0
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(find.byIcon(Icons.access_time_rounded), findsNothing);
  });

  testWidgets('RoomCardWidget shows warnings and maintenance',
      (WidgetTester tester) async {
    const room = RoomCardModel(
      id: 'test_id_2',
      title: 'Problem Room',
      styleName: 'Test Style',
      imagePath: 'assets/images/test.jpg',
      totalAssetValue: 1000,
      maintenanceHealth: 0.5,
      alertCount: 2,
      maintenanceCount: 1,
      deviceCount: 5,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomCardWidget(
            room: room,
            onTap: () {},
          ),
        ),
      ),
    );

    // We expect 2 warning icons: one in the image overlay (health < 0.8) and one in the footer (alertCount > 0)
    expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(2));
    expect(find.text('2'), findsOneWidget); // Alert count

    expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // Maintenance count

    expect(find.byIcon(Icons.devices), findsOneWidget);
    expect(find.text('5'), findsOneWidget); // Device count
  });
}
