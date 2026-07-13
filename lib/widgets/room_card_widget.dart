import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/room_card_model.dart';
import '../services/room_photo_service.dart';

class RoomCardWidget extends StatelessWidget {
  final RoomCardModel room;
  final VoidCallback? onDetailTap;
  final VoidCallback? onCustomizePhoto;
  final VoidCallback? onRename;

  const RoomCardWidget({
    super.key,
    required this.room,
    this.onDetailTap,
    this.onCustomizePhoto,
    this.onRename,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
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
                    child: GestureDetector(
                      onLongPress: onRename,
                      child: Text(
                        room.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.5,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ),
                  if (onRename != null)
                    IconButton(
                      onPressed: onRename,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      color: const Color(0xFF999999),
                      tooltip: '名称を変更',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                  const SizedBox(width: 4),
                  // Minimal status dot: meaning is explained on room detail screen.
                  Tooltip(
                    message: _healthStatusLabel(room.maintenanceHealth),
                    waitDuration: const Duration(milliseconds: 120),
                    showDuration: const Duration(milliseconds: 900),
                    triggerMode: TooltipTriggerMode.tap,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _healthStatusColor(room.maintenanceHealth),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.95),
                          width: 1,
                        ),
                      ),
                    ),
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

                  if (onCustomizePhoto != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onCustomizePhoto,
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
                            child: const Icon(Icons.photo_camera_outlined,
                                size: 18, color: Color(0xFF333333)),
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
                        '部屋の資産合計',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(room.totalAssetValue),
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
                  if (onDetailTap != null)
                    GestureDetector(
                      onTap: onDetailTap,
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

  Color _healthStatusColor(double score) {
    if (score >= 0.8) return const Color(0xFF22C55E);
    if (score >= 0.5) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _healthStatusLabel(double score) {
    if (score >= 0.8) return '良好';
    if (score >= 0.5) return '注意';
    return '要対応';
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

  static String _formatCurrency(num value) {
    try {
      return NumberFormat.currency(
        locale: 'ja_JP',
        symbol: '¥ ',
        decimalDigits: 0,
      ).format(value);
    } catch (_) {
      return '¥ ${value.toStringAsFixed(0)}';
    }
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
    }
    if (RoomPhotoService.isAssetPath(path)) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFFF5F5F0),
            child: const Center(
              child: Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          );
        },
      );
    }
    if (!kIsWeb) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFFF5F5F0),
            child: const Center(
              child: Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          );
        },
      );
    }
    return Container(
      color: const Color(0xFFF5F5F0),
      child: const Center(child: Icon(Icons.image, color: Colors.grey)),
    );
  }
}
