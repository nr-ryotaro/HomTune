import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/add_device_screen.dart';
import 'services/config_service.dart';
import 'services/device_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');
  final configService = ConfigService();
  await configService.load();

  // オンボーディング完了チェック
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  // メンテナンス通知サービスの初期化
  final notificationService = NotificationService();
  await notificationService.initialize();

  runZonedGuarded(
    () {
      FlutterError.onError = (FlutterErrorDetails details) {
        if (kDebugMode) {
          FlutterError.presentError(details);
        }
        print('Flutter Error: ${details.exception}');
        print('Stack trace: ${details.stack}');
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        print('Platform Error: $error');
        print('Stack trace: $stack');
        return true;
      };
      runApp(HomTuneApp(
        configService: configService,
        onboardingCompleted: onboardingCompleted,
      ));
    },
    (error, stack) {
      print('Uncaught error: $error');
      print('Stack trace: $stack');
    },
  );
}

class HomTuneApp extends StatelessWidget {
  const HomTuneApp({
    super.key,
    required this.configService,
    required this.onboardingCompleted,
  });
  final ConfigService configService;
  final bool onboardingCompleted;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ConfigService>.value(value: configService),
        ChangeNotifierProvider(create: (_) => DeviceService()),
      ],
      child: MaterialApp(
        title: 'HomTune',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1a1a1a),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: Colors.white,
          fontFamily:
              '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        ),
        home:
            onboardingCompleted ? const HomeScreen() : const OnboardingScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/scan': (context) => const ScanScreen(),
          '/add-device': (context) => const AddDeviceScreen(),
        },
      ),
    );
  }
}
