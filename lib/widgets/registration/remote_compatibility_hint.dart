import 'package:flutter/material.dart';

import '../../models/remote_compatibility_assessment.dart';
import '../../services/remote_control/remote_control_policy.dart';

/// 登録フォーム内: 型番ベースのリモコン対応ヒント
class RemoteCompatibilityHint extends StatelessWidget {
  final RemoteCompatibilityAssessment? assessment;
  final bool isLoading;

  const RemoteCompatibilityHint({
    super.key,
    this.assessment,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!RemoteControlPolicy.supportsRemoteControl) {
      return const SizedBox.shrink();
    }
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    final a = assessment;
    if (a == null || !a.isEligible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFB3D4FF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.sensors,
              size: 20,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'リモコン操作に対応している可能性',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a.registrationHint,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '登録後に Pro で Remo / SwitchBot との紐付けを案内します',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[800]?.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
