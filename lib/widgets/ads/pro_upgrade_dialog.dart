import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum ProUpsellContext { general, remoteControl }

/// Pro プラン訴求
Future<void> showProUpgradeDialog(
  BuildContext context, {
  ProUpsellContext upsellContext = ProUpsellContext.general,
  String? deviceName,
  String? deviceCategoryLabel,
}) async {
  final isRemote = upsellContext == ProUpsellContext.remoteControl;
  final headline = isRemote && deviceName != null && deviceName.isNotEmpty
      ? '$deviceName をスマホから操作'
      : 'HomTune Pro';

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
          ] else ...[
            const Text('月額 490円（税込）で次が使えます:'),
            const SizedBox(height: 12),
          ],
          if (!isRemote) ...[
            const Text('• 広告なしの快適な画面'),
            const Text('• AIクレジット拡大（チャット・画像・スキャン）'),
            const Text('• 相場DB・AI相場推定（資産価値）'),
            const Text('• 部屋画像の再生成（月2回/部屋）'),
            const Text('• スマートリモコン連携（Remo / SwitchBot）'),
          ] else ...[
            const Text('• 広告なし ＋ AI相場・部屋画像'),
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
        if (kDebugMode)
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ctx.push('/dev-settings');
            },
            child: const Text('開発者設定'),
          ),
      ],
    ),
  );
}
