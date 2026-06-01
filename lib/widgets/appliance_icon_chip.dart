import 'package:flutter/material.dart';

/// ホーム用の小さな絵文字チップ（名前はタップ後の画面で表示）
class ApplianceIconChip extends StatelessWidget {
  static const double size = 48;

  final String icon;
  final VoidCallback? onTap;
  final bool showAlertDot;
  final bool selected;

  const ApplianceIconChip({
    super.key,
    required this.icon,
    this.onTap,
    this.showAlertDot = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF0F7FF) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFE5E5E5),
              width: selected ? 1.5 : 0.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 24, height: 1),
              ),
              if (showAlertDot)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
