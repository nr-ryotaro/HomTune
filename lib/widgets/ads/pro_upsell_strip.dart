import 'package:flutter/material.dart';

import '../../services/analytics_service.dart';
import 'pro_upgrade_dialog.dart';

/// バナー直上の Pro 訴求（Free のみ）
class ProUpsellStrip extends StatelessWidget {
  final String placement;

  const ProUpsellStrip({super.key, required this.placement});

  Future<void> _onTap(BuildContext context) async {
    await AnalyticsService.logEvent(
      event: 'pro_upsell_tap',
      properties: {'placement': placement, 'source': 'ad_strip'},
    );
    if (!context.mounted) return;
    await showProUpgradeDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFAFAFA),
      child: InkWell(
        onTap: () => _onTap(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFE5E5E5)),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium_outlined,
                  size: 18, color: Color(0xFF1A1A1A)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Proで広告を非表示 ＋ AI相場・部屋画像',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              Text(
                '詳細',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
