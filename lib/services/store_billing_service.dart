import '../models/ai_usage_policy.dart';

/// ストア課金のクライアント stub（レシート検証・本番 IAP は帰宅後実装）
///
/// Product ID は `AiUsagePolicy.proAddonPacks` と揃える。
class StoreBillingService {
  StoreBillingService._();
  static final StoreBillingService instance = StoreBillingService._();

  static const String proMonthlyProductId = 'homtune_pro_monthly';

  bool get isStoreBillingReady => false;

  String get unavailableMessage =>
      'ストア課金は準備中です。開発ビルドでは開発者設定から Pro を試せます。';

  Future<bool> purchaseProSubscription() async => false;

  Future<bool> purchaseAddon(CreditAddonPack pack) async => false;

  Future<bool> restorePurchases() async => false;

  List<CreditAddonPack> get availableAddons => AiUsagePolicy.proAddonPacks;
}
