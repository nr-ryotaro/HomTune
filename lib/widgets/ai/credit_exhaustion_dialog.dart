import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/ai_usage_policy.dart';
import '../../screens/plan_screen.dart';
import '../../services/ai_usage_service.dart';
import '../../services/billing/store_billing_service.dart';
import '../../services/config_service.dart';
import '../ads/pro_upgrade_dialog.dart';

/// クレジット枯渇時の統一導線
/// - Free → Pro プランへ
/// - Pro → 追加クレジット購入（IAP 準備中 / debug サンドボックス付与）
Future<void> showCreditExhaustionDialog(
  BuildContext context, {
  required ConfigService config,
  required AiBudgetCheck check,
  ProUpsellContext upsellContext = ProUpsellContext.general,
}) async {
  if (!context.mounted) return;

  final tier = config.subscriptionTier;
  final isFree = tier == SubscriptionTier.free;
  final reason = check.exhaustionReason;

  if (isFree &&
      (reason == AiExhaustionReason.monthlyCredits ||
          reason == AiExhaustionReason.hardCap ||
          reason == AiExhaustionReason.roomQuotaFree)) {
    await showProUpgradeDialog(
      context,
      upsellContext: upsellContext,
    );
    return;
  }

  if (!isFree &&
      (reason == AiExhaustionReason.monthlyCredits ||
          reason == AiExhaustionReason.hardCap)) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('今月のAIクレジットが不足'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '残り ${check.snapshot.remainingCredits} / ${check.snapshot.creditLimit} クレジット',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              '追加クレジットで今月の利用を続けられます（Pro 専用）。',
              style: TextStyle(fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 12),
            for (final pack in AiUsagePolicy.proAddonPacks) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text('${pack.credits} クレジット'),
                subtitle: Text('¥${pack.priceJpy}（税込）'),
                trailing: const Icon(Icons.add_shopping_cart_outlined, size: 20),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _purchaseAddonCredits(context, config, pack);
                },
              ),
            ],
            const SizedBox(height: 8),
            Text(
              StoreBillingService.instance.isStoreBillingAvailable
                  ? 'App Store / Google Play から購入できます。'
                  : StoreBillingService.instance.canUseSandboxPurchase
                      ? 'ストア課金は準備中です。開発ビルドではサンドボックス付与が使えます。'
                      : 'ストア課金は準備中です。リリース後に App Store / Google Play から購入できます。',
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('閉じる'),
          ),
          if (kDebugMode)
            TextButton(
              onPressed: () async {
                await AiUsageService.instance.grantBonusCredits(50);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('開発用: 50クレジットを付与しました')),
                  );
                }
              },
              child: const Text('開発: +50cr'),
            ),
        ],
      ),
    );
    return;
  }

  if (!isFree && reason == AiExhaustionReason.roomQuotaPro) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('部屋画像の月間上限'),
        content: const Text(
          'この部屋は今月2回まで生成できます。来月リセットされるまでお待ちください。\n'
          '別の部屋であれば、部屋ごとに月2回まで利用できます。',
          style: TextStyle(fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
    return;
  }

  await showProUpgradeDialog(context, upsellContext: upsellContext);
}

Future<void> _purchaseAddonCredits(
  BuildContext context,
  ConfigService config,
  CreditAddonPack pack,
) async {
  final result =
      await StoreBillingService.instance.purchaseAddonCredits(config, pack);
  if (!context.mounted) return;

  if (result.isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('追加クレジット'),
      content: Text(
        result.message,
        style: const TextStyle(fontSize: 13, height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('閉じる'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlanScreen()),
            );
          },
          child: const Text('プラン比較'),
        ),
      ],
    ),
  );
}
