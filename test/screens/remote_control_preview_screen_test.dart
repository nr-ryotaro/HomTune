import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/screens/remote_control_preview_screen.dart';

void main() {
  testWidgets('RemoteControlPreviewScreen shows scenario chips and panel',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RemoteControlPreviewScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('リモコン UI プレビュー'), findsOneWidget);
    expect(find.text('Free（ロック）'), findsOneWidget);
    expect(find.text('エアコン'), findsWidgets);
    expect(find.text('リモコン'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('登録後プロンプトを開く'),
      200,
    );
    expect(find.text('登録後プロンプトを開く'), findsOneWidget);
  });

  testWidgets('scenario switch updates to Free locked state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RemoteControlPreviewScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Free（ロック）'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Proでリモコン操作'), findsOneWidget);
  });
}
