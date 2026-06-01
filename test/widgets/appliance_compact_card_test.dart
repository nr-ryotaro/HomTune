import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/widgets/appliance_compact_card.dart';

void main() {
  testWidgets('ApplianceCompactCard fits long titles without overflow',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ApplianceCompactCard(
            icon: '❄️',
            title: 'ビルトインコンベクションオーブン',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('ビルトインコンベクションオーブン'), findsOneWidget);
  });
}
