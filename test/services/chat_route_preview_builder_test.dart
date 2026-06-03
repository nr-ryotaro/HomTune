import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/ai_usage_policy.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/services/ai_routing_service.dart';
import 'package:homtune/services/chat_route_preview_builder.dart';
import 'package:homtune/services/config_service.dart';
import 'package:homtune/services/local_response_planner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tv = Device(
    id: 'tv_001',
    name: 'BRAVIA 65V型',
    modelNumber: 'XRJ-65A95K',
    category: 'テレビ',
    manufacturer: 'SONY',
    purchaseDate: '2023-01-01',
    purchasePrice: 100,
    yearsOwned: 1,
    room: 'living-room',
    location: '',
    status: 'active',
    consumables: [],
    photos: [],
    documents: [],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('型番質問のプレビューはローカル', () async {
    final config = ConfigService();
    await config.load();
    final preview = ChatRoutePreviewBuilder.build(
      message: 'テレビの型番を教えて',
      devices: [tv],
      config: config,
    );
    expect(preview.willUseAi, isFalse);
    expect(preview.hintLine, contains('ローカル'));
    expect(preview.hintLine, contains('型番'));
  });

  test('複雑質問のプレビューはAI寄り', () async {
    final config = ConfigService();
    await config.load();
    await config.setUseRealApi(true);
    await config.setGeminiApiKey('test-key-for-preview-only');

    final preview = ChatRoutePreviewBuilder.build(
      message: '電気代を比較して最適な運用を提案して',
      devices: [tv],
      config: config,
    );
    expect(preview.willUseAi, isTrue);
    expect(preview.hintLine, contains('AI'));
  });

  test('ローカルで答えられる場合は確認不要', () {
    final plan = LocalResponsePlanner.plan('テレビの型番', [tv]);
    final decision = AiRoutingService.instance.decideChatRoute(
      'テレビの型番',
      devices: [tv],
      localPlan: plan,
      subscriptionTier: SubscriptionTier.pro,
    );
    expect(decision.routeType, AiRouteType.localOnly);
    expect(decision.needsConfirmation, isFalse);
  });
}
