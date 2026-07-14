import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/ai_usage_policy.dart';
import 'package:homtune/services/ai_api_client.dart';
import 'package:homtune/services/config_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('featureName maps AiFeature', () {
    expect(AiApiClient.featureName(AiFeature.chat), 'chat');
    expect(AiApiClient.featureName(AiFeature.roomImage), 'roomImage');
  });

  test('generate parses success payload', () async {
    final client = AiApiClient(
      httpClient: MockClient((request) async {
        expect(request.url.path, '/v1/ai/generate');
        expect(request.headers['X-HomTune-Pro'], 'false');
        return http.Response(
          '''
          {
            "ok": true,
            "text": "hello",
            "modelId": "gemini-2.5-flash-lite",
            "feature": "chat",
            "mocked": true,
            "usage": {
              "creditsCharged": 2,
              "remainingCredits": 38,
              "creditLimit": 40,
              "estimatedCostUsd": 0.02
            }
          }
          ''',
          200,
          headers: {'Content-Type': 'application/json'},
        );
      }),
    );

    final config = ConfigService();
    await config.load();
    final result = await client.generate(
      config: config,
      feature: AiFeature.chat,
      contents: const [AiContentMessage(role: 'user', text: 'hi')],
    );

    expect(result.text, 'hello');
    expect(result.usage.creditsCharged, 2);
    expect(result.mocked, isTrue);
    client.dispose();
  });

  test('generate maps quota error', () async {
    final client = AiApiClient(
      httpClient: MockClient((request) async {
        return http.Response(
          '''
          {
            "ok": false,
            "error": {
              "code": "quota_exceeded",
              "message": "limit",
              "retryable": false
            },
            "usage": { "remainingCredits": 0, "creditLimit": 40 }
          }
          ''',
          429,
          headers: {'Content-Type': 'application/json'},
        );
      }),
    );

    final config = ConfigService();
    await config.load();
    expect(
      () => client.generate(
        config: config,
        feature: AiFeature.chat,
        contents: const [AiContentMessage(role: 'user', text: 'hi')],
      ),
      throwsA(
        isA<AiApiException>().having((e) => e.code, 'code', 'quota_exceeded'),
      ),
    );
    client.dispose();
  });

  test('preferAiProxy defaults to true', () async {
    final config = ConfigService();
    await config.load();
    expect(config.preferAiProxy, isTrue);
    await config.setPreferAiProxy(false);
    expect(config.preferAiProxy, isFalse);
  });
}
