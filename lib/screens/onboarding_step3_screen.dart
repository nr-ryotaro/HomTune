import 'package:flutter/material.dart';

/// Step 3: 最初の1台を登録 or スキップ
class OnboardingStep3Screen extends StatelessWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const OnboardingStep3Screen({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            '最初の1台を登録',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w200,
              letterSpacing: -0.5,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '1台登録するだけで、健康度や資産価値が\nすぐに動き始めます。',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Color(0xFF999999),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),

          // Scan option (recommended)
          _RegistrationOption(
            icon: Icons.qr_code_scanner,
            title: 'バーコードスキャン',
            subtitle: 'おすすめ — 撮るだけで自動登録',
            isRecommended: true,
            onTap: () {
              // Navigate to scan screen, then complete onboarding
              Navigator.of(context).pushNamed('/scan').then((_) {
                onComplete();
              });
            },
          ),
          const SizedBox(height: 12),

          // Manual option
          _RegistrationOption(
            icon: Icons.keyboard_alt_outlined,
            title: '型番を入力',
            subtitle: '手動で家電情報を入力',
            onTap: () {
              Navigator.of(context).pushNamed('/add-device').then((_) {
                onComplete();
              });
            },
          ),

          const Spacer(),

          // Skip option
          Center(
            child: TextButton(
              onPressed: onSkip,
              child: const Text(
                'あとで登録する →',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF999999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'ホーム画面からいつでも追加できます',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFCCCCCC),
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _RegistrationOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isRecommended;
  final VoidCallback onTap;

  const _RegistrationOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isRecommended = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            border: Border.all(
              color: isRecommended
                  ? const Color(0xFF333333)
                  : const Color(0xFFE5E5E5),
              width: isRecommended ? 1.5 : 0.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isRecommended
                      ? const Color(0xFF333333)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isRecommended ? Colors.white : const Color(0xFF666666),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF333333),
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3b82f6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'おすすめ',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFFCCCCCC),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
