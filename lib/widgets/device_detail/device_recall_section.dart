import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/device.dart';
import '../../models/safety_info.dart';

String formatRecallDate(String dateStr) {
  try {
    return DateFormat('yyyy年MM月dd日').format(DateTime.parse(dateStr));
  } catch (_) {
    return dateStr;
  }
}

/// デバイス詳細のリコールアラートバナー。
class DeviceRecallSection extends StatelessWidget {
  const DeviceRecallSection({super.key, required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final recall = device.safetyInfo?.recallDetails;
    if (recall == null) return const SizedBox.shrink();

    Color bgColor;
    Color borderColor;
    Color textColor;
    Color iconColor;
    IconData icon;

    switch (recall.severity) {
      case RecallSeverity.critical:
        bgColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFFCA5A5);
        textColor = const Color(0xFF991B1B);
        iconColor = const Color(0xFFDC2626);
        icon = Icons.warning_amber_rounded;
        break;
      case RecallSeverity.warning:
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFCD34D);
        textColor = const Color(0xFF92400E);
        iconColor = const Color(0xFFF59E0B);
        icon = Icons.error_outline_rounded;
        break;
      case RecallSeverity.info:
        bgColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFF93C5FD);
        textColor = const Color(0xFF1E40AF);
        iconColor = const Color(0xFF3B82F6);
        icon = Icons.info_outline_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'リコール情報 — ${recall.severityLabel}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recall.description,
            style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            '原因: ${recall.reason}',
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
          if (recall.date.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '発表日: ${formatRecallDate(recall.date)}',
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
          if (recall.affectedUnits != null) ...[
            const SizedBox(height: 4),
            Text(
              '対象台数: 約${NumberFormat('#,###').format(recall.affectedUnits)}台',
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
          if (recall.manufacturerContactUrl != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(recall.manufacturerContactUrl!);
                  if (!await launchUrl(url,
                      mode: LaunchMode.externalApplication)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('URLを開けませんでした')),
                      );
                    }
                  }
                },
                icon: Icon(Icons.open_in_new, size: 16, color: iconColor),
                label: Text(
                  'メーカーに問い合わせる',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
