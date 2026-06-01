import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homtune/screens/home_screen.dart';
import 'package:homtune/screens/onboarding_screen.dart';
import 'package:homtune/services/config_service.dart';
import 'package:homtune/services/device_service.dart';
import 'package:homtune/services/onboarding_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      OnboardingPrefs.keyCompleted: true,
    });
  });

  testWidgets('プレビューで閉じると完了フラグは維持される', (tester) async {
    final configService = ConfigService();
    final deviceService = DeviceService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ConfigService>.value(value: configService),
          ChangeNotifierProvider<DeviceService>.value(value: deviceService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const OnboardingScreen(isPreview: true),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('閉じる'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
    expect(await OnboardingPrefs.isCompleted(), isTrue);
  });

  testWidgets('プレビューを2回開いてもクラッシュしない', (tester) async {
    final configService = ConfigService();
    final deviceService = DeviceService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ConfigService>.value(value: configService),
          ChangeNotifierProvider<DeviceService>.value(value: deviceService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OnboardingScreen(
                          key: ValueKey<int>(
                              DateTime.now().millisecondsSinceEpoch),
                          isPreview: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('閉じる'), findsOneWidget);
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('プレビュー完了でホームに戻り2回目も開ける', (tester) async {
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
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ConfigService>.value(value: configService),
          ChangeNotifierProvider<DeviceService>.value(value: deviceService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OnboardingScreen(
                          key: ValueKey<int>(
                              DateTime.now().millisecondsSinceEpoch),
                          isPreview: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ワンルーム / 1K'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2部屋で始める'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('次へ'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('スキップしてホームへ →'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('スキップしてホームへ →'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('open'), findsOneWidget);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('閉じる'), findsOneWidget);
  });
}
