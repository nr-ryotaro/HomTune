import 'package:flutter/material.dart';
import '../models/device.dart';
import 'anthropomorphic_device_icon.dart';

class DeviceCard extends StatelessWidget {
  final Device device;

  const DeviceCard({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    final maintenanceStatus = _getMaintenanceStatus();
    final warrantyStatus = _getWarrantyStatus();
    final yearsOwned = _calculateYearsOwned();

    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // デバイスアイコン
                    AnthropomorphicDeviceIcon(
                      device: device,
                      size: 24.0,
                      showAnimation: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                device.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w300,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (maintenanceStatus != null)
                                _buildAlertBadge(maintenanceStatus),
                              if (warrantyStatus != null)
                                _buildAlertBadge(warrantyStatus),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${device.manufacturer} ${device.modelNumber}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_getRoomName()} · 購入から $yearsOwned年',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () {
                  // メニュー（将来実装）
                },
              ),
            ],
          ),
          const Divider(height: 32, thickness: 0.5),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '資産価値',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.assetValue != null
                          ? '¥${device.assetValue!.currentUsedPrice.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'
                          : 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '最終メンテナンス',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.maintenance?.lastMaintenance ?? '未実施',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (device.manual != null)
                TextButton(
                  onPressed: () {
                    // 説明書を開く（将来実装）
                  },
                  child: const Text(
                    '説明書を見る →',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  // 詳細画面（将来実装）
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                child: const Text(
                  '詳細',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBadge(Map<String, String> status) {
    final color = status['type'] == 'warning'
        ? Colors.red
        : status['type'] == 'info'
            ? Colors.blue
            : Colors.grey;

    final message = status['message'] ?? '';
    if (message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 10,
          color: color.shade700,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Map<String, String>? _getMaintenanceStatus() {
    if (device.maintenance?.alerts == null ||
        device.maintenance!.alerts.isEmpty) {
      return null;
    }

    final highPriorityAlert = device.maintenance!.alerts
        .firstWhere((a) => a.priority == 'high', orElse: () => Alert(
              type: '',
              message: '',
              priority: '',
              createdAt: '',
            ));

    if (highPriorityAlert.message.isNotEmpty) {
      return {
        'type': 'warning',
        'message': highPriorityAlert.message,
      };
    }

    final mediumPriorityAlert = device.maintenance!.alerts
        .firstWhere((a) => a.priority == 'medium', orElse: () => Alert(
              type: '',
              message: '',
              priority: '',
              createdAt: '',
            ));

    if (mediumPriorityAlert.message.isNotEmpty) {
      return {
        'type': 'info',
        'message': mediumPriorityAlert.message,
      };
    }

    return null;
  }

  Map<String, String>? _getWarrantyStatus() {
    if (device.warranty?.manufacturer == null) return null;

    final manufacturer = device.warranty!.manufacturer!;
    if (!manufacturer.expired) {
      try {
        final expiryDate = DateTime.parse(manufacturer.expiryDate);
        final today = DateTime.now();
        final daysRemaining = expiryDate.difference(today).inDays;

        if (daysRemaining > 0 && daysRemaining <= 30) {
          return {
            'type': 'info',
            'message': '保証期限まであと$daysRemaining日',
          };
        }
      } catch (e) {
        // 日付パースエラーは無視
      }
    }

    return null;
  }

  String _calculateYearsOwned() {
    try {
      if (device.purchaseDate.isEmpty) return '0.0';
      final purchase = DateTime.parse(device.purchaseDate);
      final today = DateTime.now();
      final diff = today.difference(purchase).inDays;
      if (diff < 0) return '0.0';
      return (diff / 365).toStringAsFixed(1);
    } catch (e) {
      return '0.0';
    }
  }

  String _getRoomName() {
    // 部屋IDから部屋名を取得（簡易実装）
    switch (device.room) {
      case 'living-room':
        return 'リビング';
      case 'study':
        return '書斎';
      case 'bedroom':
        return '寝室';
      default:
        return device.room;
    }
  }
}
