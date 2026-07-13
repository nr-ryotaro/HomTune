import 'package:flutter/material.dart';

import '../../services/first_launch_guide_service.dart';

/// ホーム上部の初回セットアップ進捗バナー
class SetupProgressBanner extends StatelessWidget {
  final SetupProgress progress;
  final VoidCallback onAddAppliance;
  final VoidCallback onSetupRoomPhotos;
  final VoidCallback? onLearnPro;

  const SetupProgressBanner({
    super.key,
    required this.progress,
    required this.onAddAppliance,
    required this.onSetupRoomPhotos,
    this.onLearnPro,
  });

  @override
  Widget build(BuildContext context) {
    if (progress.applianceGoalMet && progress.roomPhotosConfigured) {
      return const SizedBox.shrink();
    }

    final photoDone = progress.roomPhotosConfigured;
    final applianceDone = progress.applianceGoalMet;

    return Material(
      color: const Color(0xFFFAFAF8),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'はじめてのセットアップ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              photoDone
                  ? (progress.hasApplianceGoal
                      ? '家電 ${progress.applianceProgressCurrent}/${progress.applianceProgressTarget} 台登録済み'
                      : '家電を登録して管理を始めましょう')
                  : 'まずは部屋の写真を1部屋設定しましょう',
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 12),
            _StepRow(
              index: 1,
              label: '部屋の写真を設定',
              done: photoDone,
              actionLabel: '写真を設定',
              onTap: onSetupRoomPhotos,
            ),
            const SizedBox(height: 8),
            _StepRow(
              index: 2,
              label: '家電を登録',
              done: applianceDone,
              actionLabel: applianceDone ? '追加する' : '登録を始める',
              onTap: onAddAppliance,
            ),
            if (photoDone && applianceDone && onLearnPro != null) ...[
              const SizedBox(height: 8),
              _StepRow(
                index: 3,
                label: 'Proで資産・リモコンを強化（任意）',
                done: false,
                actionLabel: '詳しく見る',
                onTap: onLearnPro!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final String label;
  final bool done;
  final String actionLabel;
  final VoidCallback onTap;

  const _StepRow({
    required this.index,
    required this.label,
    required this.done,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        done ? const Color(0xFF16A34A) : const Color(0xFF333333);

    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: done
              ? const Color(0xFFDCFCE7)
              : const Color(0xFFF3F4F6),
          child: done
              ? const Icon(Icons.check, size: 14, color: Color(0xFF16A34A))
              : Text(
                  '$index',
                  style:
                      TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ),
        if (!done)
          TextButton(
            onPressed: onTap,
            child: Text(actionLabel, style: const TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}
