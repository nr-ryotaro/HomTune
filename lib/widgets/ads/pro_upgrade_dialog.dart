import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pro プラン訴求（広告非表示 + AI）
Future<void> showProUpgradeDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('HomTune Pro'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('月額 490円（税込）で次が使えます:'),
          SizedBox(height: 12),
          Text('• 広告なしの快適な画面'),
          Text('• AIクレジット拡大（チャット・画像・スキャン）'),
          Text('• 相場DB・AI相場推定（資産価値）'),
          Text('• 部屋画像の再生成（月2回/部屋）'),
          SizedBox(height: 12),
          Text(
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
