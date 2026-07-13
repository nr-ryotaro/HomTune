import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/screens/onboarding_screen.dart';
import 'package:homtune/services/appliance_template_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('家電選択は前画面で選んだ部屋のみ表示する', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: OnboardingScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('1LDK'));
    await tester.pumpAndSettle();

    // 部屋3（キッチン相当）のチェックを外す
    await tester.tap(find.text('部屋3'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2部屋で始める'));
    await tester.pumpAndSettle();

    expect(find.text('🛋️ 部屋1'), findsOneWidget);
    expect(find.text('🍳 部屋2'), findsOneWidget);
    expect(find.text('🛏️ 部屋3'), findsNothing);

    final livingArchetypes = await ApplianceTemplateService.instance
        .getArchetypesForRoom('living-room');
    expect(livingArchetypes, isNotEmpty);
    expect(
      find.text('${livingArchetypes.first.icon} ${livingArchetypes.first.displayName}'),
      findsWidgets,
    );
  });
}
