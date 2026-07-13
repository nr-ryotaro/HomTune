import 'package:flutter/material.dart';
import '../utils/platform_support.dart';
import '../widgets/appliance_registration_option.dart';
import 'add_device_screen.dart';
import 'scan_screen.dart';
import 'web_unsupported_feature_screen.dart';

/// Step 4: 家電登録（スキップ可）→ ホームへ
class OnboardingStep3Screen extends StatelessWidget {
  final String? initialRoomId;
  final bool isFinishing;
  final Future<void> Function() onComplete;
  final Future<void> Function() onSkip;

  const OnboardingStep3Screen({
    super.key,
    this.initialRoomId,
    this.isFinishing = false,
    required this.onComplete,
    required this.onSkip,
  });

  Future<void> _openScan(BuildContext context) async {
    if (isFinishing) return;
    if (!PlatformSupport.supportsSmartIngester) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WebUnsupportedFeatureScreen(
            featureName: 'Smart Ingester',
            initialRoomId: initialRoomId,
          ),
        ),
      );
      return;
    }
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ScanScreen(initialRoomId: initialRoomId),
      ),
    );
    if (registered == true && context.mounted) {
      await onComplete();
    }
  }

  Future<void> _openManualEntry(BuildContext context) async {
    if (isFinishing) return;
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddDeviceScreen(initialRoomId: initialRoomId),
      ),
    );
    if (registered == true && context.mounted) {
      await onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            '家電を登録しましょう',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w200,
              letterSpacing: -0.5,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '型番を登録すると、メンテナンスや資産価値の管理が始まります。\n'
            'あとからホーム画面でも登録できます。',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Color(0xFF999999),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            '登録方法を選ぶ',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF999999),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          if (PlatformSupport.supportsSmartIngester) ...[
            ApplianceRegistrationOption(
              icon: Icons.qr_code_scanner,
              title: 'バーコードスキャン',
              subtitle: '撮るだけで自動登録',
              isRecommended: true,
              onTap: () => _openScan(context),
            ),
            const SizedBox(height: 12),
          ],
          ApplianceRegistrationOption(
            icon: Icons.keyboard_alt_outlined,
            title: '型番を入力',
            subtitle: PlatformSupport.supportsSmartIngester
                ? '手動で家電情報を入力'
                : 'Web プレビューではこちらから登録',
            isRecommended: !PlatformSupport.supportsSmartIngester,
            onTap: () => _openManualEntry(context),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium_outlined,
                    size: 20, color: Color(0xFF666666)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pro ならリモコン操作・相場DB・広告なしなどが使えます。まずは無料で家電登録から始められます。',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isFinishing ? null : onSkip,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                side: const BorderSide(color: Color(0xFFE5E5E5)),
              ),
              child: const Text(
                '今は登録しない',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF666666),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'ホーム画面からいつでも登録できます',
              style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
