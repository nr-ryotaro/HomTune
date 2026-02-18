import 'package:flutter/material.dart';
import 'dart:io';
import '../models/device.dart';
import '../services/manual_service.dart';
import '../services/valuation_service.dart';
import '../screens/manual_viewer_screen.dart';
import '../screens/manual_registration_screen.dart';
import 'asset_value_chart.dart';
import 'device_detail_content.dart';

class DeviceDetailCard extends StatelessWidget {
  final Device device;

  const DeviceDetailCard({
    super.key,
    required this.device,
  });

  void _showMoreDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // ハンドル
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // コンテンツ (共通ウィジェットを使用)
            Expanded(
              child: DeviceDetailContent(device: device),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openManual(BuildContext context) async {
    // マニュアルが未登録の場合は登録画面へ
    if (device.manual == null || device.manual!.url.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ManualRegistrationScreen(
            device: device,
          ),
        ),
      );
      return;
    }

    if (device.modelNumber.isEmpty || device.manufacturer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('型番またはメーカー情報が不足しています'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final manualService = ManualService();
      File? pdfFile;

      // ローカルファイルの場合
      if (device.manual!.isLocalFile) {
        pdfFile = await manualService.getManualFile(device.manual!.url);
      } else {
        // 外部URLまたは型番から検索
        pdfFile = await manualService.getManual(
          device.modelNumber,
          device.manufacturer,
          manualUrl: device.manual!.url,
        );
      }

      if (!context.mounted) return;
      Navigator.of(context).pop(); // ローディングを閉じる

      if (pdfFile != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ManualViewerScreen(
              pdfFile: pdfFile!,
              deviceName: device.name,
              modelNumber: device.modelNumber,
            ),
          ),
        );
      } else {
        // マニュアルが見つからない場合は登録画面へ
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ManualRegistrationScreen(
              device: device,
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // ローディングを閉じる
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE5E5E5),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // デバイス名
                Text(
                  device.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // 型名
                if (device.modelNumber.isNotEmpty)
                  Text(
                    device.modelNumber,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w300,
                    ),
                  ),
              ],
            ),
          ),
          // クイックアクセス（右側配置）
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 説明書（丸型アイコン）
                _buildManualButton(context),
                const SizedBox(width: 12),
                // More
                _buildMoreButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualButton(BuildContext context) {
    final hasManual = device.manual != null && device.manual!.url.isNotEmpty;
    final hasModelNumber =
        device.modelNumber.isNotEmpty && device.manufacturer.isNotEmpty;

    return InkWell(
      onTap: hasModelNumber || hasManual ? () => _openManual(context) : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (hasModelNumber || hasManual)
              ? const Color(0xFF3b82f6).withValues(alpha: 0.1)
              : Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(
            color: (hasModelNumber || hasManual)
                ? const Color(0xFF3b82f6)
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Icon(
          hasManual ? Icons.menu_book_outlined : Icons.add,
          size: 20,
          color: (hasModelNumber || hasManual)
              ? const Color(0xFF3b82f6)
              : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    return InkWell(
      onTap: () => _showMoreDetails(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFE5E5E5),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.more_horiz,
          size: 20,
          color: Color(0xFF3b82f6),
        ),
      ),
    );
  }
}
