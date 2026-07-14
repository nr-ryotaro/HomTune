import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/plan_screen.dart';
import '../../services/analytics_service.dart';

enum ProUpsellContext { general, remoteControl, valuation, roomImage }

/// Pro プラン訴求
Future<void> showProUpgradeDialog(
  BuildContext context, {
  ProUpsellContext upsellContext = ProUpsellContext.general,
  String? deviceName,
  String? deviceCategoryLabel,
  String? source,
}) async {
  final isRemote = upsellContext == ProUpsellContext.remoteControl;
  final isValuation = upsellContext == ProUpsellContext.valuation;
  final isRoomImage = upsellContext == ProUpsellContext.roomImage;
  final resolvedSource = source ?? upsellContext.name;
  final headline = isRemote && deviceName != null && deviceName.isNotEmpty
      ? '$deviceName をスマホから操作'
      : isValuation
          ? 'より正確な資産価値を把握'
          : isRoomImage
              ? '部屋画像をもっと自由に'
              : 'HomTune Pro';

  await AnalyticsService.logEvent(
    event: isRoomImage ? 'room_image_upsell_shown' : 'pro_upgrade_shown',
    properties: {
      'context': upsellContext.name,
      'source': resolvedSource,
    },
  );

  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(headline),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRemote) ...[
            Text(
              deviceCategoryLabel != null && deviceCategoryLabel.isNotEmpty
                  ? '登録した$deviceCategoryLabelを、Nature Remo / SwitchBot 経由で操作できます。'
                  : '登録した家電を、Nature Remo / SwitchBot 経由で操作できます。',
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pro で使えること:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('• リモコン紐付けとワンタップ操作'),
            const Text('• チャットから「エアコンつけて」など'),
            const Text('• 月 300 回まで操作'),
            const SizedBox(height: 8),
            const Text('その他の Pro 特典:'),
            const SizedBox(height: 4),
            const Text('• 広告なし ＋ AI相場・部屋画像'),
          ] else if (isValuation) ...[
            const Text(
              '無料プランでは端末内の推定（L0）のみです。Pro では実際の中古相場に近い価値を確認できます。',
              style: TextStyle(fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pro の資産価値機能:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('• 相場DB参照（月10回）'),
            const Text('• AI相場推定'),
            const Text('• グラフへの正確な市場価値反映'),
            const Text('• 売却タイミング判断の精度向上'),
            const SizedBox(height: 8),
            const Text('その他の Pro 特典:'),
            const SizedBox(height: 4),
            const Text('• 広告なしの快適な画面'),
            const Text('• スマートリモコン連携'),
          ] else if (isRoomImage) ...[
            const Text(
              '部屋カードの画像差し替えは AI 生成のみです（実写登録なし）。'
              'Freeではお試し生成がアカウント全体で1回まで。差し替え・別部屋・再生成は Pro で利用できます。',
              style: TextStyle(fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pro の部屋画像:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('• 画像の差し替え・再生成（最大10部屋・月2回/部屋）'),
            const Text('• スタイル指定で雰囲気を更新'),
            const Text('• AIクレジット拡大（チャット・スキャンも）'),
            const SizedBox(height: 8),
            const Text('その他の Pro 特典:'),
            const SizedBox(height: 4),
            const Text('• 広告なしの快適な画面'),
            const Text('• 相場DB・スマートリモコン連携'),
          ] else ...[
            const Text('月額 490円（税込）で次が使えます:'),
            const SizedBox(height: 12),
            const Text('• 広告なしの快適な画面'),
            const Text('• AIクレジット拡大（チャット・画像・スキャン）'),
            const Text('• 相場DB・AI相場推定（資産価値）'),
            const Text('• 部屋画像の再生成（月2回/部屋・最大10部屋）'),
            const Text('• スマートリモコン連携（Remo / SwitchBot）'),
            const Text('• クレジット不足時は追加購入可（Pro専用）'),
          ],
          const SizedBox(height: 12),
          const Text(
            'ストア課金は準備中です。開発ビルドでは開発者設定から Pro を試せます。',
            style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('閉じる'),
        ),
        TextButton(
          onPressed: () async {
            await AnalyticsService.logEvent(
              event: 'pro_upgrade_tapped',
              properties: {
                'context': upsellContext.name,
                'source': resolvedSource,
                'action': 'plan_compare',
              },
            );
            if (!ctx.mounted) return;
            Navigator.of(ctx).pop();
            Navigator.of(ctx).push(
              MaterialPageRoute(builder: (_) => const PlanScreen()),
            );
          },
          child: const Text('プラン比較'),
        ),
        if (kDebugMode)
          TextButton(
            onPressed: () async {
              await AnalyticsService.logEvent(
                event: 'pro_upgrade_tapped',
                properties: {
                  'context': upsellContext.name,
                  'source': resolvedSource,
                  'action': 'dev_settings',
                },
              );
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              ctx.push('/dev-settings');
            },
            child: const Text('開発者設定'),
          ),
      ],
    ),
  );
}
