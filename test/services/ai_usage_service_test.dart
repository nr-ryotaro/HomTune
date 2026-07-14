import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/ai_usage_policy.dart';
import 'package:homtune/services/ai_usage_service.dart';
import 'package:homtune/services/config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiUsageService', () {
    late ConfigService configService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AiUsageService.instance.resetForTest();
      configService = ConfigService();
      await configService.load();
      await configService.setUseRealApi(true);
    });

    test('初期状態ではクレジット利用が0', () async {
      final snapshot = await AiUsageService.instance.getSnapshot(configService);
      expect(snapshot.usedCredits, 0);
      expect(snapshot.remainingCredits, greaterThan(0));
    });

    test('recordUsageで利用量が増える', () async {
      await AiUsageService.instance.recordUsage(
        configService,
        feature: AiFeature.chat,
        consumedCredits: 3,
        route: 'test',
      );
      final snapshot = await AiUsageService.instance.getSnapshot(configService);
      expect(snapshot.usedCredits, greaterThanOrEqualTo(3));
      expect(snapshot.estimatedCostUsd, greaterThan(0));
    });

    test('クラウドAIオフ時は利用不可', () async {
      await configService.setPreferAiProxy(false);
      await configService.setUseRealApi(false);
      final check = await AiUsageService.instance.canRunFeature(
        configService,
        feature: AiFeature.chat,
        requestedCredits: 1,
      );
      expect(check.allowed, false);
      expect(check.reason, contains('クラウドAI'));
    });

    test('pro tier は free より上限が大きい', () async {
      final freeSnapshot = await AiUsageService.instance.getSnapshot(configService);
      await configService.setSubscriptionTier(SubscriptionTier.pro);
      final proSnapshot = await AiUsageService.instance.getSnapshot(configService);
      expect(proSnapshot.creditLimit, greaterThan(freeSnapshot.creditLimit));
    });

    test('Free は AI 部屋画像がアカウント全体で1回まで', () async {
      final first = await AiUsageService.instance.canRunRoomImage(
        configService,
        roomId: 'living-room',
        requestedCredits: 2,
      );
      expect(first.allowed, true);
      await AiUsageService.instance.recordRoomImageUsage(
        configService,
        roomId: 'living-room',
        consumedCredits: 2,
      );
      final sameRoom = await AiUsageService.instance.canRunRoomImage(
        configService,
        roomId: 'living-room',
        requestedCredits: 2,
      );
      expect(sameRoom.allowed, false);
      expect(sameRoom.reason, contains('アカウント全体で1回'));
      expect(sameRoom.exhaustionReason, AiExhaustionReason.roomQuotaFree);

      final otherRoom = await AiUsageService.instance.canRunRoomImage(
        configService,
        roomId: 'kitchen-01',
        requestedCredits: 2,
      );
      expect(otherRoom.allowed, false);
      expect(otherRoom.exhaustionReason, AiExhaustionReason.roomQuotaFree);
    });

    test('Pro は部屋画像が月2回まで', () async {
      await configService.setSubscriptionTier(SubscriptionTier.pro);
      for (var i = 0; i < 2; i++) {
        final check = await AiUsageService.instance.canRunRoomImage(
          configService,
          roomId: 'kitchen-01',
          requestedCredits: 2,
        );
        expect(check.allowed, true);
        await AiUsageService.instance.recordRoomImageUsage(
          configService,
          roomId: 'kitchen-01',
          consumedCredits: 2,
        );
      }
      final third = await AiUsageService.instance.canRunRoomImage(
        configService,
        roomId: 'kitchen-01',
        requestedCredits: 2,
      );
      expect(third.allowed, false);
      expect(third.reason, contains('月2回'));
      expect(third.exhaustionReason, AiExhaustionReason.roomQuotaPro);
    });

    test('bonus credits extend monthly limit', () async {
      await configService.setSubscriptionTier(SubscriptionTier.pro);
      await AiUsageService.instance.grantBonusCredits(30);
      final snapshot = await AiUsageService.instance.getSnapshot(configService);
      expect(snapshot.creditLimit, 150);
    });
  });
}
