import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/ai_usage_policy.dart';
import '../services/config_service.dart';
import '../services/unit_economics_service.dart';
import '../widgets/ads/pro_upgrade_dialog.dart';

/// 現在のプランと Pro 特典の概要
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigService>();
    final isPro = config.subscriptionTier == SubscriptionTier.pro;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        title: const Text(
          'プラン',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPro ? 'HomTune Pro' : 'HomTune Free',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isPro
                      ? 'すべてのプレミアム機能が利用できます'
                      : '基本機能は無料。高度な機能は Pro で解放',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _planTable(isPro),
          const SizedBox(height: 12),
          Text(
            'Pro ${UnitEconomicsService.proPriceJpy}円/月（税込）・AI原価は売上の40%以内を目標に設計',
            style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 24),
          if (!isPro) ...[
            FilledButton(
              onPressed: () => showProUpgradeDialog(
                context,
                upsellContext: ProUpsellContext.general,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1a1a1a),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Pro の機能を詳しく見る'),
            ),
            const SizedBox(height: 8),
            const Text(
              'クレジットが足りない場合は Pro へアップグレードしてください。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 4),
            const Text(
              'ストア課金は準備中です。開発ビルドでは開発者設定から Pro を試せます。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
          ] else ...[
            const Text(
              'Pro プランをご利用中です。ありがとうございます。',
              style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 12),
            Text(
              '追加クレジット: ${AiUsagePolicy.proAddonPacks.map((p) => '${p.credits}cr/¥${p.priceJpy}').join('、')}（Pro専用・準備中）',
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
          ],
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.push('/dev-settings'),
              child: const Text('開発者設定（プラン切替）'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _planTable(bool isPro) {
    const rows = <({String feature, String free, String pro})>[
      (feature: '家電登録・メンテ管理', free: '○', pro: '○'),
      (feature: '資産価値（端末内推定）', free: '○', pro: '○'),
      (feature: '相場DB（月10回）・AI相場', free: '—', pro: '○'),
      (feature: 'スマートリモコン', free: '—', pro: '月300回'),
      (feature: '部屋画像（AI）', free: 'アカウント生涯1回', pro: '月2回/部屋'),
      (feature: '登録部屋数', free: '最大5', pro: '最大10'),
      (feature: '追加AIクレジット', free: '—（Proへ）', pro: '50cr/350円〜'),
      (feature: '広告', free: 'あり', pro: 'なし'),
      (feature: 'AI クレジット', free: '月40', pro: '月120'),
      (feature: '月額', free: '0円', pro: '490円'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('機能', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Expanded(child: Center(child: Text('Free'))),
                Expanded(child: Center(child: Text('Pro'))),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(row.feature, style: const TextStyle(fontSize: 13))),
                  Expanded(child: Center(child: Text(row.free))),
                  Expanded(
                    child: Center(
                      child: Text(
                        row.pro,
                        style: TextStyle(
                          fontWeight: isPro ? FontWeight.w600 : FontWeight.normal,
                          color: const Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
