import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/screens/add_appliance_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homtune/services/config_service.dart';
import 'package:homtune/services/device_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AddApplianceScreen shows registration methods', (tester) async {
    final configService = ConfigService();
    final deviceService = DeviceService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ConfigService>.value(value: configService),
          ChangeNotifierProvider<DeviceService>.value(value: deviceService),
        ],
        child: const MaterialApp(home: AddApplianceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('登録方法を選ぶ'), findsOneWidget);
    expect(find.text('型番を入力'), findsOneWidget);
  });
}
