import 'package:flutter/material.dart';
import 'dart:io';
import '../models/appliance_presentation.dart';
import '../models/device.dart';
import '../services/manual_service.dart';
import '../screens/manual_viewer_screen.dart';
import '../screens/manual_registration_screen.dart';
import 'device_detail_content.dart';

class DeviceDetailCard extends StatelessWidget {
  final Device device;
  final AppliancePresentation? presentation;

  const DeviceDetailCard({
    super.key,
    required this.device,
    this.presentation,
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
                if (presentation != null) ...[
                  Text(
                    presentation!.icon,
                    style: const TextStyle(fontSize: 32, height: 1.1),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  presentation?.title ?? device.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_subtitleLine != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _subtitleLine!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
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
                // 資産価値・詳細（帳簿/市場価値・グラフ・売却アドバイス等）
                _buildAssetValueButton(context),
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

  String? get _subtitleLine {
    final fromPresentation = presentation?.subtitle?.trim();
    if (fromPresentation != null && fromPresentation.isNotEmpty) {
      return fromPresentation;
    }
    if (device.modelNumber.isNotEmpty) return device.modelNumber;
    return null;
  }

  Widget _buildAssetValueButton(BuildContext context) {
    final valueLabel = device.assetValue != null
        ? '¥${_formatCompactYen(device.assetValue!.currentUsedPrice)}'
        : null;

    return Tooltip(
      message: '資産価値の詳細（帳簿・市場価値・推移グラフ）',
      waitDuration: const Duration(milliseconds: 200),
      child: Semantics(
        button: true,
        label: '資産価値を表示',
        child: InkWell(
          onTap: () => _showAssetDetails(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF3b82f6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF3b82f6).withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.savings_outlined,
                  size: 20,
                  color: Color(0xFF3b82f6),
                ),
                if (valueLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    valueLabel,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3b82f6),
                      height: 1,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  const Text(
                    '資産',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3b82f6),
                      height: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCompactYen(int amount) {
    if (amount >= 10000) {
      final man = amount / 10000;
      if (man >= 10) {
        return '${man.round()}万';
      }
      return '${man.toStringAsFixed(1)}万';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}千';
    }
    return amount.toString();
  }

  void _showAssetDetails(BuildContext context) {
    _showMoreDetails(context);
  }
}
