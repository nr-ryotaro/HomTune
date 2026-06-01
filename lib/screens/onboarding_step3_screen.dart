import 'package:flutter/material.dart';
import '../utils/platform_support.dart';
import '../widgets/appliance_registration_option.dart';
import 'add_device_screen.dart';
import 'scan_screen.dart';
import 'web_unsupported_feature_screen.dart';

/// Step 4: ホームへ進み、そこで家電登録（部屋写真は登録後）
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
            'ホームで家電を登録',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w200,
              letterSpacing: -0.5,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '選んだ家電の型番やお手入れ情報は、\n'
            '「家電を追加」からいつでも登録できます。\n'
            '部屋の写真は、登録が一通り終わってから設定します。',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Color(0xFF999999),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isFinishing ? null : onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'ホームへ進む',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '先に1台だけ登録する',
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
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: isFinishing ? null : onSkip,
              child: const Text(
                'スキップしてホームへ →',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF999999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
