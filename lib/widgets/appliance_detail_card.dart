import 'package:flutter/material.dart';

/// 詳細一覧用（名前・型番・カスタム絵文字）
class ApplianceDetailCard extends StatelessWidget {
  static const double cardWidth = 132;
  static const double cardHeight = 118;

  final String icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final bool showAlertDot;

  const ApplianceDetailCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.onEdit,
    this.showAlertDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: cardWidth,
          height: cardHeight,
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E5E5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 22, height: 1.1)),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle?.trim().isNotEmpty == true
                        ? subtitle!
                        : '型番未登録',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      color: subtitle?.trim().isNotEmpty == true
                          ? const Color(0xFF888888)
                          : const Color(0xFFCCCCCC),
                    ),
                  ),
                ],
              ),
              if (onEdit != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    color: const Color(0xFF999999),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    tooltip: '名前とアイコンを編集',
                  ),
                ),
              if (showAlertDot)
                Positioned(
                  top: 4,
                  left: 28,
                  child: Container(
                    width: 8,
                    height: 8,
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
