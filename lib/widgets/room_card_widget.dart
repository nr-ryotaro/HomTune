import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/room_card_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RoomCardWidget extends StatelessWidget {
  final RoomCardModel room;
  final VoidCallback onTap;

  const RoomCardWidget({
    super.key,
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2), // Minimal rounded corner
        border: Border.all(
          color: const Color(0xFFE5E5E5), // Thin line
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      room.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w300, // Thin font
                        letterSpacing: 0.5,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badges
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (room.streakWeeks > 0)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '🔥${room.streakWeeks}週',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: room.maintenanceHealth >= 0.8
                                  ? Colors.green.withValues(alpha: 0.85)
                                  : room.maintenanceHealth >= 0.5
                                      ? Colors.amber.withValues(alpha: 0.9)
                                      : Colors.red.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${(room.maintenanceHealth * 100).round()}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (room.achievementRate < 1.0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '今月 ${(room.achievementRate * 100).round()}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Visual Area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image Layer
                  _buildRoomImage(room.imagePath),

                  // Weather/Effect Layer (Stub)
                  // Future: Add fog/rain animation here
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),

                  // Monetization / Regenerate Button (Magic Wand)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showPremiumDialog(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.auto_fix_high,
                              size: 18, color: Colors.purple),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Asset',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        NumberFormat.currency(
                                locale: 'ja_JP', symbol: '¥ ', decimalDigits: 0)
                            .format(room.totalAssetValue),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400, // Not too bold
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Info Row (Warning / Maintenance / Device Count)
                      Row(
                        children: [
                          if (room.alertCount > 0) ...[
                            _buildInfoIcon(
                              Icons.warning_amber_rounded,
                              room.alertCount.toString(),
                              Colors.red,
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (room.maintenanceCount > 0) ...[
                            _buildInfoIcon(
                              Icons.access_time_rounded,
                              room.maintenanceCount.toString(),
                              Colors.amber,
                            ),
                            const SizedBox(width: 12),
                          ],
                          _buildInfoIcon(
                            Icons.devices,
                            room.deviceCount.toString(),
                            Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Detail Button (Minimal)
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber),
            SizedBox(width: 8),
            Text('Premium Feature',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('無料プランでは部屋画像の生成は初回のみです。'),
            SizedBox(height: 16),
            Text(
              'HomTuneプレミアム（¥300/月）に登録して、最新の機材構成で部屋をリデザインしますか？',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('プレミアム登録画面へ遷移します（デモ）')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF333333),
              foregroundColor: Colors.white,
            ),
            child: const Text('登録する'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildInfoIcon(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color == Colors.grey ? const Color(0xFF999999) : color,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomImage(String path) {
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[100]),
        errorWidget: (context, url, error) => Container(
            color: Colors.grey[200], child: const Icon(Icons.broken_image)),
      );
    } else {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFFF5F5F0), // Japandi base color
            child: const Center(
              child: Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          );
        },
      );
    }
  }
}
