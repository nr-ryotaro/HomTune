import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/app/router.dart';
import 'package:homtune/main.dart';
import 'package:homtune/screens/home_screen.dart';
import 'package:homtune/services/config_service.dart';
import 'package:homtune/services/manual_link_resolver.dart';
import 'package:homtune/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
    });
  });

  testWidgets('HomTuneApp shows HomeScreen when onboarding is skipped',
      (tester) async {
    final configService = ConfigService();
    await configService.load();

    final notificationService = NotificationService();
    final manualLinkResolver = ManualLinkResolver(configService);
    ManualLinkResolver.bind(manualLinkResolver);

    await tester.pumpWidget(
      HomTuneApp(
        configService: configService,
        notificationService: notificationService,
        manualLinkResolver: manualLinkResolver,
        router: createAppRouter(showOnboarding: false),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
