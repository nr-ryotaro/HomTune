import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/router.dart';
import 'widgets/web_preview_banner.dart';
import 'utils/platform_support.dart';
import 'app/app_providers.dart';
import 'services/config_service.dart';
import 'services/manual_link_resolver.dart';
import 'services/notification_service.dart';
import 'services/onboarding_prefs.dart';
import 'services/ad_service.dart';

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

  final notificationService = NotificationService();
  await notificationService.initialize();

  final manualLinkResolver = ManualLinkResolver(configService);
  ManualLinkResolver.bind(manualLinkResolver);

  await AdService.instance.initialize();

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
        notificationService: notificationService,
        manualLinkResolver: manualLinkResolver,
        router: createAppRouter(showOnboarding: showOnboarding),
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
    required this.notificationService,
    required this.manualLinkResolver,
    required this.router,
  });
  final ConfigService configService;
  final NotificationService notificationService;
  final ManualLinkResolver manualLinkResolver;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildAppProviders(
        configService: configService,
        notificationService: notificationService,
        manualLinkResolver: manualLinkResolver,
      ),
      child: MaterialApp.router(
        title: PlatformSupport.isWebUiPreview
            ? 'HomTune (Web Preview)'
            : 'HomTune',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
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
      ),
    );
  }
}
