import '../models/ai_usage_policy.dart';
import '../screens/onboarding_screen.dart';

/// 部屋数のフェアユース（追加部屋は許可、13LDK 等の異常値は拒否）
class RoomFairUseService {
  RoomFairUseService._();

  static final RoomFairUseService instance = RoomFairUseService._();

  /// 住居タイプごとの推奨部屋数（オンボーディング初期値）
  int recommendedRoomCount(HousingType housingType) {
    switch (housingType) {
      case HousingType.studio:
        return 2;
      case HousingType.oneLDK:
        return 3;
      case HousingType.twoLDK:
        return 4;
      case HousingType.threeLDK:
      case HousingType.house:
        return 5;
    }
  }

  int absoluteMaxRooms(SubscriptionTier tier, {AiUsagePolicy? policy}) {
    final p = policy ?? const AiUsagePolicy();
    return p.maxRoomsForTier(tier);
  }

  bool canRegisterRoomCount(
    int count, {
    required SubscriptionTier tier,
    AiUsagePolicy? policy,
  }) {
    if (count < 1) return false;
    return count <= absoluteMaxRooms(tier, policy: policy);
  }

  String limitMessage(SubscriptionTier tier, {AiUsagePolicy? policy}) {
    final max = absoluteMaxRooms(tier, policy: policy);
    if (tier == SubscriptionTier.pro) {
      return 'Proプランでは最大$max部屋まで登録できます。'
          '追加した部屋ごとに月2回まで部屋画像を生成できます。';
    }
    return 'Freeプランでは最大$max部屋まで登録できます。'
        '部屋を増やす場合は Pro プランをご検討ください。';
  }

  String rejectionMessage(SubscriptionTier tier, {AiUsagePolicy? policy}) {
    final max = absoluteMaxRooms(tier, policy: policy);
    if (tier == SubscriptionTier.pro) {
      return '部屋数の上限（$max部屋）に達しています。'
          '一般住宅の範囲を超える登録はできません。';
    }
    return 'Freeプランでは最大$max部屋までです。'
        'Pro プランで最大${absoluteMaxRooms(SubscriptionTier.pro, policy: policy)}部屋まで利用できます。';
  }
}
