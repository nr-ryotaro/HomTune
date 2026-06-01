import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/widgets/appliance_detail_card.dart';

void main() {
  testWidgets('ApplianceDetailCard shows title and model', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ApplianceDetailCard(
            icon: '📺',
            title: 'テレビ',
            subtitle: 'KJ-55X80L',
          ),
        ),
      ),
    );

    expect(find.text('テレビ'), findsOneWidget);
    expect(find.text('KJ-55X80L'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
