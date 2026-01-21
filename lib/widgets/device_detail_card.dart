import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/manual_service.dart';
import '../screens/manual_viewer_screen.dart';

class DeviceDetailCard extends StatelessWidget {
  final Device device;

  const DeviceDetailCard({
    super.key,
    required this.device,
  });

  Future<void> _openManual(BuildContext context) async {
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
      final pdfFile = await manualService.getManual(
        device.modelNumber,
        device.manufacturer,
      );

      if (!context.mounted) return;
      Navigator.of(context).pop(); // ローディングを閉じる

      if (pdfFile != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ManualViewerScreen(
              pdfFile: pdfFile,
              deviceName: device.name,
              modelNumber: device.modelNumber,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('説明書の取得に失敗しました'),
            backgroundColor: Colors.red,
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


  void _showMoreDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // ハンドル
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ヘッダー
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (device.modelNumber.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            device.modelNumber,
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
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 詳細情報
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection(
                      'メーカー',
                      device.manufacturer.isNotEmpty
                          ? device.manufacturer
                          : '未登録',
                    ),
                    _buildDetailSection(
                      'カテゴリー',
                      device.category.isNotEmpty
                          ? device.category
                          : '未登録',
                    ),
                    if (device.purchaseDate.isNotEmpty)
                      _buildDetailSection(
                        '購入日',
                        device.purchaseDate,
                      ),
                    if (device.purchasePrice > 0)
                      _buildDetailSection(
                        '購入価格',
                        '¥${device.purchasePrice.toStringAsFixed(0)}',
                      ),
                    if (device.yearsOwned > 0)
                      _buildDetailSection(
                        '所有年数',
                        '${device.yearsOwned}年',
                      ),
                    if (device.location.isNotEmpty)
                      _buildDetailSection(
                        '設置場所',
                        device.location,
                      ),
                    if (device.status.isNotEmpty)
                      _buildDetailSection(
                        'ステータス',
                        device.status,
                      ),
                    if (device.maintenance != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'メンテナンス情報',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (device.maintenance!.alerts.isNotEmpty) ...[
                        ...device.maintenance!.alerts.map(
                          (alert) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: alert.priority == 'high'
                                  ? Colors.red[50]
                                  : Colors.amber[50],
                              border: Border.all(
                                color: alert.priority == 'high'
                                    ? Colors.red[200]!
                                    : Colors.amber[200]!,
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 20,
                                  color: alert.priority == 'high'
                                      ? Colors.red[700]
                                      : Colors.amber[700],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alert.message,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: alert.priority == 'high'
                                              ? Colors.red[900]
                                              : Colors.amber[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
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
    final hasModelNumber = device.modelNumber.isNotEmpty && device.manufacturer.isNotEmpty;
    
    return InkWell(
      onTap: hasModelNumber
          ? () => _openManual(context)
          : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: hasModelNumber
              ? const Color(0xFF3b82f6).withValues(alpha: 0.1)
              : Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(
            color: hasModelNumber
                ? const Color(0xFF3b82f6)
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.menu_book_outlined,
          size: 20,
          color: hasModelNumber
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
