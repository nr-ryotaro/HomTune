import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/config_service.dart';
import 'services/device_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final configService = ConfigService();
  await configService.load();

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
      runApp(HomTuneApp(configService: configService));
    },
    (error, stack) {
      print('Uncaught error: $error');
      print('Stack trace: $stack');
    },
  );
}

class HomTuneApp extends StatelessWidget {
  const HomTuneApp({super.key, required this.configService});
  final ConfigService configService;

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
          fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
