import 'package:flutter/material.dart';
import '../utils/platform_support.dart';

/// Web UI プレビュー時に画面上部へ表示する帯
class WebPreviewBanner extends StatelessWidget {
  const WebPreviewBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!PlatformSupport.isWebUiPreview) {
      return const SizedBox.shrink();
    }

    return Material(
      color: const Color(0xFFEFF6FF),
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFBFDBFE)),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.laptop_mac, size: 18, color: Color(0xFF1D4ED8)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Web UI プレビュー — オンボーディング・ホーム・手入力登録・メンテ画面の確認用です。'
                  'スキャン・OCR・カメラはモバイル版のみ対応しています。',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w400,
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
