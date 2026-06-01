import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/add_device_screen.dart';
import 'screens/web_unsupported_feature_screen.dart';
import 'widgets/web_preview_banner.dart';
import 'utils/platform_support.dart';
import 'services/config_service.dart';
import 'services/device_service.dart';
import 'services/notification_service.dart';
import 'services/onboarding_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('ja_JP');
  } catch (e) {
    debugPrint('Date formatting init failed, using default locale: $e');
    try {
      await initializeDateFormatting('en_US');
    } catch (_) {}
  }
  final configService = ConfigService();
  await configService.load();

  final showOnboarding = await OnboardingPrefs.shouldShowOnLaunch();

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
        showOnboarding: showOnboarding,
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
    required this.showOnboarding,
  });
  final ConfigService configService;
  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ConfigService>.value(value: configService),
        ChangeNotifierProvider(create: (_) => DeviceService()),
      ],
      child: MaterialApp(
        title: PlatformSupport.isWebUiPreview
            ? 'HomTune (Web Preview)'
            : 'HomTune',
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();
          if (!PlatformSupport.isWebUiPreview) return child;
          return Column(
            children: [
              const WebPreviewBanner(),
              Expanded(child: child),
            ],
          );
        },
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1a1a1a),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: Colors.white,
        ),
        home: showOnboarding
            ? const OnboardingScreen()
            : const HomeScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/onboarding-preview': (context) =>
              const OnboardingScreen(isPreview: true),
          '/scan': (context) => PlatformSupport.supportsSmartIngester
              ? const ScanScreen()
              : const WebUnsupportedFeatureScreen(
                  featureName: 'Smart Ingester',
                ),
          '/add-device': (context) => const AddDeviceScreen(),
        },
      ),
    );
  }
}
