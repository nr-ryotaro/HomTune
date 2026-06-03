import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/add_device_screen.dart';
import '../screens/dev_settings_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/web_unsupported_feature_screen.dart';
import '../utils/platform_support.dart';

GoRouter createAppRouter({required bool showOnboarding}) {
  return GoRouter(
    initialLocation: showOnboarding ? '/onboarding' : '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) {
          final preview = state.uri.queryParameters['preview'] == '1';
          return OnboardingScreen(isPreview: preview);
        },
      ),
      GoRoute(
        path: '/onboarding-preview',
        builder: (context, state) => const OnboardingScreen(isPreview: true),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => PlatformSupport.supportsSmartIngester
            ? const ScanScreen()
            : const WebUnsupportedFeatureScreen(
                featureName: 'Smart Ingester',
              ),
      ),
      GoRoute(
        path: '/add-device',
        builder: (context, state) => const AddDeviceScreen(),
      ),
      if (kDebugMode)
        GoRoute(
          path: '/dev-settings',
          builder: (context, state) => const DevSettingsScreen(),
        ),
    ],
  );
}
