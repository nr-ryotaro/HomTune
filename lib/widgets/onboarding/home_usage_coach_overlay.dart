import 'package:flutter/material.dart';

/// ホーム初回到達時の利用ガイド吹き出し
class HomeUsageCoachOverlay extends StatelessWidget {
  final VoidCallback onStartRoomPhoto;
  final VoidCallback onDismiss;

  const HomeUsageCoachOverlay({
    super.key,
    required this.onStartRoomPhoto,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onDismiss,
              child: Container(color: Colors.black.withValues(alpha: 0.45)),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SpeechBubble(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.waving_hand_outlined,
                              size: 20, color: Color(0xFF333333)),
                          SizedBox(width: 8),
                          Text(
                            'HomTune の使い方',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• 部屋カードをスワイプして部屋を切り替え\n'
                        '• 家電を登録するとメンテと資産価値を管理\n'
                        '• 部屋イメージはデフォルト or AI生成（実写なし）',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.55,
                          color: Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '部屋イメージはデフォルトのままでOK。FreeはAIを1回お試しできます。',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: onStartRoomPhoto,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('部屋イメージを見る'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1a1a1a),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onDismiss,
                        child: const Text('あとで'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 36,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    '下の部屋カードがあなたの住まいになります',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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

class _SpeechBubble extends StatelessWidget {
  final Widget child;

  const _SpeechBubble({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
