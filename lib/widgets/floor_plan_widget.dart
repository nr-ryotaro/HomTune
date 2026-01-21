import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/room.dart' as room_models;

class FloorPlanWidget extends StatelessWidget {
  final room_models.FloorPlan? floorPlan;
  final List<Device> devices;
  final String? selectedRoomId;
  final Function(String) onRoomTap;

  const FloorPlanWidget({
    super.key,
    required this.floorPlan,
    required this.devices,
    this.selectedRoomId,
    required this.onRoomTap,
  });

  int _getDeviceCountForRoom(String roomId) {
    try {
      return devices.where((device) => device.room == roomId).length;
    } catch (e) {
      print('Error getting device count for room $roomId: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (floorPlan == null || floorPlan!.rooms.isEmpty) {
      return const Center(
        child: Text(
          '間取り図データがありません',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) {
            _handleTap(details.localPosition, constraints);
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: FloorPlanPainter(
              floorPlan: floorPlan!,
              devices: devices,
              selectedRoomId: selectedRoomId,
              getDeviceCount: _getDeviceCountForRoom,
            ),
          ),
        );
      },
    );
  }

  void _handleTap(Offset localPosition, BoxConstraints constraints) {
    if (floorPlan == null || floorPlan!.rooms.isEmpty) return;

    try {
      // スケールを計算
      final scaleX = constraints.maxWidth / floorPlan!.width;
      final scaleY = constraints.maxHeight / floorPlan!.height;
      final scale = scaleX < scaleY ? scaleX : scaleY;

      if (scale <= 0) return; // 無効なスケール

      // タップ位置をスケール調整
      final scaledX = localPosition.dx / scale;
      final scaledY = localPosition.dy / scale;

      // どの部屋がタップされたか判定
      for (var room in floorPlan!.rooms) {
        if (scaledX >= room.coordinates.x &&
            scaledX <= room.coordinates.x + room.coordinates.width &&
            scaledY >= room.coordinates.y &&
            scaledY <= room.coordinates.y + room.coordinates.height) {
          onRoomTap(room.id);
          break;
        }
      }
    } catch (e) {
      print('Error handling tap: $e');
    }
  }
}

class FloorPlanPainter extends CustomPainter {
  final room_models.FloorPlan floorPlan;
  final List<Device> devices;
  final String? selectedRoomId;
  final int Function(String) getDeviceCount;

  FloorPlanPainter({
    required this.floorPlan,
    required this.devices,
    this.selectedRoomId,
    required this.getDeviceCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      // サイズが無効な場合は何もしない
      if (size.width <= 0 || size.height <= 0) return;
      if (floorPlan.width <= 0 || floorPlan.height <= 0) return;
      
      // スケールを計算
      final scaleX = size.width / floorPlan.width;
      final scaleY = size.height / floorPlan.height;
      final scale = scaleX < scaleY ? scaleX : scaleY;
      
      if (scale <= 0) return; // 無効なスケール

      canvas.save();
      canvas.scale(scale);

      // 部屋を描画
      for (var room in floorPlan.rooms) {
        try {
          _drawRoom(canvas, room);
        } catch (e) {
          print('Error drawing room ${room.id}: $e');
          // 個別の部屋の描画エラーは無視して続行
        }
      }

      canvas.restore();
    } catch (e) {
      print('Error in FloorPlanPainter.paint: $e');
    }
  }

  void _drawRoom(Canvas canvas, room_models.FloorPlanRoom room) {
    try {
      final isSelected = selectedRoomId == room.id;
      final deviceCount = getDeviceCount(room.id);

      // 座標の検証
      if (room.coordinates.width <= 0 || room.coordinates.height <= 0) {
        return; // 無効なサイズの部屋はスキップ
      }

      // 部屋の矩形
      final roomRect = Rect.fromLTWH(
        room.coordinates.x,
        room.coordinates.y,
        room.coordinates.width,
        room.coordinates.height,
      );

      // 背景色（不動産サイト風のグラデーション）
      final baseColor = isSelected
          ? const Color(0xFFE3F2FD)
          : _parseColor(room.color);
      
      // グラデーション効果（上部を少し明るく）
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          baseColor.withValues(alpha: 0.15),
          baseColor.withValues(alpha: 0.08),
        ],
      );
      final gradientPaint = Paint()
        ..shader = gradient.createShader(roomRect);
      canvas.drawRect(roomRect, gradientPaint);

      // 枠線（不動産サイト風の太めの線）
      final borderColor = isSelected
          ? const Color(0xFF3b82f6)
          : const Color(0xFFCCCCCC);
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 1.0;
      canvas.drawRect(roomRect, borderPaint);

      // 内側の影（立体感）
      final innerShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.03)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      final innerRect = Rect.fromLTWH(
        room.coordinates.x + 2,
        room.coordinates.y + 2,
        room.coordinates.width - 4,
        room.coordinates.height - 4,
      );
      canvas.drawRect(innerRect, innerShadowPaint);

      // 部屋名（不動産サイト風のスタイル）
      final textPainter = TextPainter(
        text: TextSpan(
          text: room.name,
          style: TextStyle(
            color: isSelected ? const Color(0xFF3b82f6) : const Color(0xFF333333),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.8),
                offset: const Offset(0, 0),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(room.coordinates.x + 12, room.coordinates.y + 12),
      );

      // デバイス数バッジ（不動産サイト風のスタイル）
      if (deviceCount > 0) {
        const badgeRadius = 14.0;
        final badgeX = room.coordinates.x + room.coordinates.width - 28;
        final badgeY = room.coordinates.y + 24;

        // バッジの背景（影付き）
        final badgeShadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(
          Offset(badgeX + 1, badgeY + 1),
          badgeRadius,
          badgeShadowPaint,
        );

        // バッジの円（グラデーション風）
        final badgePaint = Paint()
          ..color = isSelected ? const Color(0xFF3b82f6) : const Color(0xFF4A90E2)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(badgeX, badgeY),
          badgeRadius,
          badgePaint,
        );

        // バッジの枠線
        final badgeBorderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(
          Offset(badgeX, badgeY),
          badgeRadius,
          badgeBorderPaint,
        );

        // デバイス数のテキスト
        final countTextPainter = TextPainter(
          text: TextSpan(
            text: deviceCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        countTextPainter.layout();
        countTextPainter.paint(
          canvas,
          Offset(
            badgeX - countTextPainter.width / 2,
            badgeY - countTextPainter.height / 2 + 1,
          ),
        );
      }

      // デバイスアイコンを描画
      for (var devicePlacement in room.devices) {
        try {
          final device = devices.firstWhere(
            (d) => d.id == devicePlacement.deviceId,
            orElse: () => Device(
              id: '',
              name: '',
              modelNumber: '',
              category: '',
              manufacturer: '',
              purchaseDate: '',
              purchasePrice: 0,
              yearsOwned: 0,
              room: '',
              location: '',
              status: '',
              consumables: [],
              photos: [],
              documents: [],
            ),
          );

          if (device.id.isNotEmpty) {
            _drawDevice(canvas, devicePlacement, device);
          }
        } catch (e) {
          print('Error drawing device ${devicePlacement.deviceId}: $e');
          // 個別のデバイスの描画エラーは無視して続行
        }
      }
    } catch (e) {
      print('Error in _drawRoom: $e');
    }
  }

  void _drawDevice(
    Canvas canvas,
    room_models.DevicePlacement placement,
    Device device,
  ) {
    try {
      final x = placement.x;
      final y = placement.y;

      // 座標の検証
      if (x.isNaN || y.isNaN || x.isInfinite || y.isInfinite) {
        return; // 無効な座標はスキップ
      }

      // デバイスアイコンの色を決定
      final hasHighPriorityAlert = device.maintenance?.alerts
              .any((a) => a.priority == 'high') ??
          false;
      final deviceColor = hasHighPriorityAlert
          ? const Color(0xFFef4444)
          : const Color(0xFF3b82f6);

      // デバイスの円（影付き）
      final deviceShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(Offset(x + 0.5, y + 0.5), 9, deviceShadowPaint);

      // デバイスの円
      final devicePaint = Paint()
        ..color = deviceColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 9, devicePaint);

      // デバイスの枠線
      final deviceBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(x, y), 9, deviceBorderPaint);

      // デバイス名（短縮、不動産サイト風）
      final deviceName = device.name.split(' ').first;
      final deviceTextPainter = TextPainter(
        text: TextSpan(
          text: deviceName,
          style: TextStyle(
            color: const Color(0xFF333333),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.9),
                offset: const Offset(0, 0),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      deviceTextPainter.layout();
      deviceTextPainter.paint(
        canvas,
        Offset(
          x - deviceTextPainter.width / 2,
          y + 14,
        ),
      );
    } catch (e) {
      print('Error in _drawDevice: $e');
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFFFAFAFA);
    }
  }

  @override
  bool shouldRepaint(FloorPlanPainter oldDelegate) {
    return oldDelegate.selectedRoomId != selectedRoomId ||
        oldDelegate.devices.length != devices.length;
  }
}
