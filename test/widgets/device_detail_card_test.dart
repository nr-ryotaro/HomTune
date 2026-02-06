import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/models/safety_info.dart';
import 'package:homtune/widgets/device_detail_card.dart';

void main() {
  testWidgets(
      'DeviceDetailCard displays Asset Value section with Help and Refresh icons',
      (WidgetTester tester) async {
    // Mock Device
    final device = Device(
      id: 'test_dev',
      name: 'Test Device',
      modelNumber: 'M123',
      category: 'エアコン',
      manufacturer: 'Tester',
      purchaseDate: '2024-01-01',
      purchasePrice: 100000,
      yearsOwned: 1,
      room: 'living',
      location: 'Wall',
      status: 'active',
      consumables: [],
      photos: [],
      documents: [],
      safetyInfo: SafetyInfo(
        safetyScore: 90,
        safetyAdvice: [],
        lastSafetyCheck: '2025-01-01',
        recallStatus: 'none',
      ),
      assetValue: AssetValue(
        purchasePrice: 100000,
        currentUsedPrice: 50000,
        depreciationRate: 0.5,
        lastPriceCheck: '2025-01-01',
        priceHistory: [],
        bookValue: 40000,
        marketValue: 50000,
        hasSellOpportunity: true,
        usefulLife: 10,
      ),
    );

    // Initial pump
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeviceDetailCard(device: device),
          ),
        ),
      ),
    );

    // Wait for FutureBuilder to complete
    await tester.pumpAndSettle();

    // Verify Summary Card appears
    expect(find.text('Test Device'), findsOneWidget);

    // Tap "More" button to open details
    final moreButtonFinder = find.byIcon(Icons.more_horiz);
    await tester.ensureVisible(moreButtonFinder);
    await tester.pumpAndSettle();
    await tester.tap(moreButtonFinder);
    await tester.pumpAndSettle(); // Wait for bottom sheet animation

    // Verify Asset Value Header exists in Bottom Sheet
    expect(find.text('資産価値'), findsOneWidget);

    // Verify Refresh Icon (in header)
    expect(find.byIcon(Icons.refresh), findsOneWidget);

    // Verify Help Icons (in Value Cards: Book Value and Market Value)
    expect(find.byIcon(Icons.help_outline), findsNWidgets(2));

    // Tap Refresh
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();

    // Verify loading indicator appears (impl uses 800ms delay)
    // Actually we can't easily see the CircularProgressIndicator replace the icon unless we check exact frame
    // But we can check that it doesn't crash
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();

    // Tap Help Icon (Book Value)
    final helpIconFinder = find.byIcon(Icons.help_outline).first;
    await tester.ensureVisible(helpIconFinder);
    await tester.pumpAndSettle();
    await tester.tap(helpIconFinder);
    await tester.pumpAndSettle();

    // Verify Dialog appears
    expect(find.text('帳簿上の価値（減価償却）'), findsOneWidget);
    expect(find.text('了解'), findsOneWidget);

    // Close Dialog
    await tester.tap(find.text('了解'));
    await tester.pumpAndSettle();
  });
}
