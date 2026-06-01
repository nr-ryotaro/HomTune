import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homtune/screens/onboarding_screen.dart';
import 'package:homtune/screens/home_screen.dart';
import 'package:homtune/services/config_service.dart';
import 'package:homtune/services/device_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('スキップしてホームへで遷移しクラッシュしない', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final configService = ConfigService();
    final deviceService = DeviceService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ConfigService>.value(value: configService),
          ChangeNotifierProvider<DeviceService>.value(value: deviceService),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ワンルーム / 1K'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2部屋で始める'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    expect(find.text('スキップしてホームへ →'), findsOneWidget);
    await tester.tap(find.text('スキップしてホームへ →'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('スキップしてホームへ →'), findsNothing);

    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (!tester.any(find.byType(CircularProgressIndicator))) break;
    }
    Object? exception;
    while ((exception = tester.takeException()) != null) {
      expect(
        exception.toString(),
        contains('overflowed'),
        reason: 'Only layout overflow is tolerated in this navigation test',
      );
    }
  });
}
