import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/device_service.dart';

void main() {
  // アプリを実行（エラーが発生してもクラッシュしないように）
  // WidgetsFlutterBinding.ensureInitialized()はrunZonedGuardedの中に配置
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      
      // エラーハンドリング（開発環境）
      FlutterError.onError = (FlutterErrorDetails details) {
        if (kDebugMode) {
          FlutterError.presentError(details);
        }
        print('Flutter Error: ${details.exception}');
        print('Stack trace: ${details.stack}');
      };
      
      // プラットフォームエラーハンドリング
      PlatformDispatcher.instance.onError = (error, stack) {
        print('Platform Error: $error');
        print('Stack trace: $stack');
        return true; // エラーを処理したことを示す
      };
      
      runApp(const HomTuneApp());
    },
    (error, stack) {
      print('Uncaught error: $error');
      print('Stack trace: $stack');
    },
  );
}

class HomTuneApp extends StatelessWidget {
  const HomTuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DeviceService(),
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
