import 'package:flutter/material.dart';
import '../models/appliance_presentation.dart';
import '../models/device.dart';
import '../screens/device_detail_screen.dart';

/// ホームでアイコンタップ後、絵文字と名前を表示してから詳細へ
class DeviceQuickPreviewSheet extends StatelessWidget {
  final Device device;
  final AppliancePresentation presentation;

  const DeviceQuickPreviewSheet({
    super.key,
    required this.device,
    required this.presentation,
  });

  static Future<void> show(
    BuildContext context, {
    required Device device,
    required AppliancePresentation presentation,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DeviceQuickPreviewSheet(
        device: device,
        presentation: presentation,
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeviceDetailScreen(device: device),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modelLine = presentation.subtitle?.trim();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              presentation.icon,
              style: const TextStyle(fontSize: 44, height: 1),
            ),
            const SizedBox(height: 12),
            Text(
              presentation.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            if (modelLine != null && modelLine.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                modelLine,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF888888),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openDetail(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('お手入れ・資産情報を見る'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
