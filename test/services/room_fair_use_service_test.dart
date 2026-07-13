import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/ai_usage_policy.dart';
import 'package:homtune/screens/onboarding_screen.dart';
import 'package:homtune/services/room_fair_use_service.dart';

void main() {
  group('RoomFairUseService', () {
    final service = RoomFairUseService.instance;

    test('recommended room count matches housing type', () {
      expect(service.recommendedRoomCount(HousingType.studio), 2);
      expect(service.recommendedRoomCount(HousingType.oneLDK), 3);
      expect(service.recommendedRoomCount(HousingType.twoLDK), 4);
      expect(service.recommendedRoomCount(HousingType.house), 5);
    });

    test('absolute max prevents 13-room abuse', () {
      expect(
        service.canRegisterRoomCount(5, tier: SubscriptionTier.free),
        isTrue,
      );
      expect(
        service.canRegisterRoomCount(6, tier: SubscriptionTier.free),
        isFalse,
      );
      expect(
        service.canRegisterRoomCount(10, tier: SubscriptionTier.pro),
        isTrue,
      );
      expect(
        service.canRegisterRoomCount(13, tier: SubscriptionTier.pro),
        isFalse,
      );
    });
  });
}
