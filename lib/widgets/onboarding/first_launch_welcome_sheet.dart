import 'package:flutter/material.dart';

/// オンボーディング直後のウェルカムシート
class FirstLaunchWelcomeSheet extends StatelessWidget {
  final VoidCallback onStartRoomPhoto;
  final VoidCallback onStartApplianceRegistration;
  final VoidCallback onOpenManufacturerBundles;
  final VoidCallback onSkip;

  const FirstLaunchWelcomeSheet({
    super.key,
    required this.onStartRoomPhoto,
    required this.onStartApplianceRegistration,
    required this.onOpenManufacturerBundles,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'HomTune へようこそ',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            '部屋の写真と家電登録で、あなたの住まいに合わせたホームが完成します。',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.5),
          ),
          const SizedBox(height: 20),
          _roadmapItem(
            Icons.photo_camera_outlined,
            '1. 部屋の写真を設定',
            'まず1部屋から。撮影またはアルバムから選べます',
          ),
          _roadmapItem(
            Icons.kitchen_outlined,
            '2. 家電を登録',
            '型番スキャン・メーカーセット・手入力から選べます',
          ),
          _roadmapItem(
            Icons.edit_outlined,
            '3. 部屋名はいつでも変更可',
            '「部屋1」などの仮名から、リビング・寝室などに変更できます',
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onStartRoomPhoto();
            },
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1a1a1a),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            label: const Text('部屋の写真を設定する'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onStartApplianceRegistration();
            },
            child: const Text('家電の登録を始める'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onSkip();
            },
            child: const Text('あとで（ホームを見る）'),
          ),
        ],
      ),
    );
  }

  Widget _roadmapItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF555555)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                    height: 1.4,
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
