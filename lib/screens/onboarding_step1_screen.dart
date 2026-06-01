import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

/// Step 1: 住居タイプ選択
class OnboardingStep1Screen extends StatelessWidget {
  final Function(HousingType) onTypeSelected;

  const OnboardingStep1Screen({super.key, required this.onTypeSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            '住まいのタイプを教えてください',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w200,
              letterSpacing: -0.5,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '選んだタイプにあわせて、\n部屋のテンプレートを用意します。',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Color(0xFF999999),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),

          // Housing type cards
          Expanded(
            child: ListView.separated(
              itemCount: HousingType.values.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final type = HousingType.values[index];
                return _HousingTypeCard(
                  type: type,
                  onTap: () => onTypeSelected(type),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HousingTypeCard extends StatelessWidget {
  final HousingType type;
  final VoidCallback onTap;

  const _HousingTypeCard({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E5E5), width: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                type.icon,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${type.defaultRooms.length}部屋を自動作成',
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
