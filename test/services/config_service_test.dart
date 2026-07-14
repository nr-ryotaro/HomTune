import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/services/config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConfigService API settings', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Gemini API key and model persist across reload', () async {
      final config = ConfigService();
      await config.load();

      await config.setGeminiApiKey('test-key-123');
      await config.setGeminiModel('gemini-3.1-flash-lite');

      final reloaded = ConfigService();
      await reloaded.load();

      expect(reloaded.geminiApiKey, 'test-key-123');
      expect(reloaded.geminiModel, 'gemini-3.1-flash-lite');
      expect(reloaded.hasGeminiApiKey, isTrue);
    });

    test('resolveCloudSecretInput keeps stored key when field is empty', () async {
      final config = ConfigService();
      await config.load();
      await config.setGeminiApiKey('AQ.test-key-value');

      expect(config.resolveCloudSecretInput(''), 'AQ.test-key-value');
      expect(
        config.resolveCloudSecretInput(config.cloudSecretMaskedSummary),
        'AQ.test-key-value',
      );
      expect(config.resolveCloudSecretInput('new-key'), 'new-key');
    });

    test('testCloudConnection via proxy reports failure without backend', () async {
      final config = ConfigService();
      await config.load();
      expect(config.preferAiProxy, isTrue);

      final result = await config.testCloudConnection(secret: '');
      expect(result.success, isFalse);
      expect(result.message, contains('プロキシ'));
    });

    test('testCloudConnection without proxy requires secret', () async {
      final config = ConfigService();
      await config.load();
      await config.setPreferAiProxy(false);

      final result = await config.testCloudConnection(secret: '');
      expect(result.success, isFalse);
      expect(
        result.message,
        anyOf(contains('空'), contains('preferAiProxy'), contains('プロキシ')),
      );
    });
  });
}
