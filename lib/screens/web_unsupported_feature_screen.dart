import 'package:flutter/material.dart';
import 'add_device_screen.dart';

/// Web プレビューで利用できない機能へのフォールバック画面
class WebUnsupportedFeatureScreen extends StatelessWidget {
  final String featureName;
  final String? initialRoomId;

  const WebUnsupportedFeatureScreen({
    super.key,
    required this.featureName,
    this.initialRoomId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          featureName,
          style: const TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF333333),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFB45309)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'この機能は Web プレビューでは利用できません。\n'
                      'Android / iOS アプリでお試しください。',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Web で確認できること',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            const _Bullet(text: '初回オンボーディング（住居・部屋・家電の選択）'),
            const _Bullet(text: 'ホーム画面・部屋カード・デバイス一覧'),
            const _Bullet(text: '家電の手入力登録・メンテナンスカレンダー'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => AddDeviceScreen(
                        initialRoomId: initialRoomId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.keyboard_alt_outlined),
                label: const Text('手入力で家電を追加'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('戻る'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF666666))),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
