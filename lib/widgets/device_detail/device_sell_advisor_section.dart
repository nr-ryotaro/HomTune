import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/device.dart';
import '../../services/sell_advisor_service.dart';

bool shouldShowSellAdvisor(Device device) {
  final advice = SellAdvisorService().analyze(device);
  return advice.type == 'sell_now' || advice.type == 'sell_soon';
}

/// 売却タイミングアドバイザーカード。
class DeviceSellAdvisorSection extends StatelessWidget {
  const DeviceSellAdvisorSection({super.key, required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    if (!shouldShowSellAdvisor(device)) {
      return const SizedBox.shrink();
    }

    final advice = SellAdvisorService().analyze(device);

    final Color primaryColor;
    final Color bgColor;
    final Color borderColor;
    final IconData iconData;
    switch (advice.type) {
      case 'sell_now':
        primaryColor = const Color(0xFF16A34A);
        bgColor = const Color(0xFFF0FDF4);
        borderColor = const Color(0xFF86EFAC);
        iconData = Icons.trending_up_rounded;
        break;
      case 'sell_soon':
        primaryColor = const Color(0xFFD97706);
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFCD34D);
        iconData = Icons.schedule_rounded;
        break;
      case 'hold':
        primaryColor = const Color(0xFF2563EB);
        bgColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFF93C5FD);
        iconData = Icons.swap_horiz_rounded;
        break;
      default:
        primaryColor = const Color(0xFF6B7280);
        bgColor = const Color(0xFFF9FAFB);
        borderColor = const Color(0xFFE5E7EB);
        iconData = Icons.hourglass_empty_rounded;
    }

    final currencyFormatter = NumberFormat('#,##0', 'ja_JP');

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(iconData, color: primaryColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    advice.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Score ${advice.score}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advice.reason,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _AdvisorStat(
                        label: '推定売却価格',
                        value:
                            '¥${currencyFormatter.format(advice.estimatedSellPrice)}',
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AdvisorStat(
                        label: '帳簿価値との差額',
                        value:
                            '${advice.profitOrLoss >= 0 ? "+" : ""}¥${currencyFormatter.format(advice.profitOrLoss)}',
                        color: advice.profitOrLoss >= 0
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                if (advice.monthsUntilCrossover != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.event_rounded,
                          size: 14, color: Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text(
                        '交差点まで約${advice.monthsUntilCrossover}ヶ月',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          size: 16, color: primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          advice.action,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
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

class _AdvisorStat extends StatelessWidget {
  const _AdvisorStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
