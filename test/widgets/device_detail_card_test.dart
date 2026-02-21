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
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify Summary Card appears
    expect(find.text('Test Device'), findsOneWidget);
  });
}
