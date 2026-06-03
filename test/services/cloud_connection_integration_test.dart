import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/services/config_service.dart';

/// 実キーでの接続確認（任意）
///
/// 実行例:
/// flutter test test/services/cloud_connection_integration_test.dart `
///   --dart-define=GEMINI_API_KEY=YOUR_KEY
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('live Gemini connection when GEMINI_API_KEY is provided', () async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) {
      // CI / 通常テストではスキップ相当（成功扱い）
      return;
    }

    final config = ConfigService();
    await config.load();
    await config.setGeminiApiKey(apiKey);

    final result = await config.testCloudConnection(secret: apiKey);
    expect(
      result.success,
      isTrue,
      reason: result.message,
    );
    expect(result.modelId, isNotEmpty);
  }, timeout: const Timeout(Duration(seconds: 90)));
}
