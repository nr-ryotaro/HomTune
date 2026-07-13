import 'package:flutter/foundation.dart';

import '../../models/ai_usage_policy.dart';
import '../ai_usage_service.dart';
import '../config_service.dart';

/// ストア課金の結果
enum StorePurchaseStatus {
  success,
  cancelled,
  unavailable,
  failed,
}

class StorePurchaseResult {
  final StorePurchaseStatus status;
  final String message;
  final CreditAddonPack? pack;

  const StorePurchaseResult({
    required this.status,
    required this.message,
    this.pack,
  });

  bool get isSuccess => status == StorePurchaseStatus.success;
}

/// App Store / Play Billing 接続の骨格。
/// 本番 IAP 前は debug/sandbox 付与のみ。レシート検証はサーバー連携後に追加する。
class StoreBillingService {
  StoreBillingService._();
  static final StoreBillingService instance = StoreBillingService._();

  static const String proMonthlyProductId = 'homtune_pro_monthly';

  /// 本番ストア課金が使えるか（現状は常に false。in_app_purchase 導入後に更新）
  bool get isStoreBillingAvailable => false;

  /// 開発ビルドでは Pro / 追加クレジットのサンドボックス付与を許可
  bool get canUseSandboxPurchase => kDebugMode;

  Future<StorePurchaseResult> purchaseProSubscription(
    ConfigService config,
  ) async {
    if (config.subscriptionTier == SubscriptionTier.pro) {
      return const StorePurchaseResult(
        status: StorePurchaseStatus.success,
        message: 'すでに Pro プランです',
      );
    }

    if (isStoreBillingAvailable) {
      return const StorePurchaseResult(
        status: StorePurchaseStatus.unavailable,
        message: 'ストア課金の接続準備中です',
      );
    }

    if (!canUseSandboxPurchase) {
      return const StorePurchaseResult(
        status: StorePurchaseStatus.unavailable,
        message: 'ストア課金は準備中です。リリース後に App Store / Google Play から購読できます。',
      );
    }

    try {
      await config.setSubscriptionTier(SubscriptionTier.pro);
      return const StorePurchaseResult(
        status: StorePurchaseStatus.success,
        message: '開発用: Pro プランを有効化しました',
      );
    } catch (e) {
      return StorePurchaseResult(
        status: StorePurchaseStatus.failed,
        message: 'Pro の有効化に失敗しました: $e',
      );
    }
  }

  Future<StorePurchaseResult> purchaseAddonCredits(
    ConfigService config,
    CreditAddonPack pack,
  ) async {
    if (config.subscriptionTier != SubscriptionTier.pro) {
      return const StorePurchaseResult(
        status: StorePurchaseStatus.unavailable,
        message: '追加クレジットは Pro プラン専用です',
      );
    }

    if (isStoreBillingAvailable) {
      return StorePurchaseResult(
        status: StorePurchaseStatus.unavailable,
        message: 'ストア課金の接続準備中です',
        pack: pack,
      );
    }

    if (!canUseSandboxPurchase) {
      return StorePurchaseResult(
        status: StorePurchaseStatus.unavailable,
        message:
            '${pack.credits} クレジット（¥${pack.priceJpy}）の購入は準備中です。リリース後はストアから購入できます。',
        pack: pack,
      );
    }

    try {
      await AiUsageService.instance.grantBonusCredits(pack.credits);
      return StorePurchaseResult(
        status: StorePurchaseStatus.success,
        message: '開発用: ${pack.credits} クレジットを付与しました',
        pack: pack,
      );
    } catch (e) {
      return StorePurchaseResult(
        status: StorePurchaseStatus.failed,
        message: 'クレジット付与に失敗しました: $e',
        pack: pack,
      );
    }
  }
}
