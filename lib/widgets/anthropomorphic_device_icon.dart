import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/device_status_service.dart';

/// 擬人化されたデバイスアイコンウィジェット
/// 機械要素（レンズ、ランプ、水平器）で状態を表現
class AnthropomorphicDeviceIcon extends StatefulWidget {
  final Device device;
  final double size;
  final bool showAnimation;

  const AnthropomorphicDeviceIcon({
    super.key,
    required this.device,
    this.size = 18.0,
    this.showAnimation = true,
  });

  @override
  State<AnthropomorphicDeviceIcon> createState() =>
      _AnthropomorphicDeviceIconState();
}

class _AnthropomorphicDeviceIconState
    extends State<AnthropomorphicDeviceIcon>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _blinkController;
  late AnimationController _wobbleController;
  late AnimationController _noiseController;

  late DeviceStatus _status;

  @override
  void initState() {
    super.initState();
    try {
      _status = DeviceStatusService().getDeviceStatus(widget.device);

      // ブリージングアニメーション（3秒周期）
      _breathingController = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      )..repeat(reverse: true);

      // 点滅アニメーション（1秒周期、needsMaintenance時）
      _blinkController = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this,
      );

      // 歪みアニメーション（2秒周期、needsMaintenance時）
      _wobbleController = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      );

      // ノイズアニメーション（0.1秒周期、error時）
      _noiseController = AnimationController(
        duration: const Duration(milliseconds: 100),
        vsync: this,
      );

      // 状態に応じてアニメーションを開始
      if (_status == DeviceStatus.needsMaintenance) {
        _blinkController.repeat(reverse: true);
        _wobbleController.repeat(reverse: true);
      } else if (_status == DeviceStatus.error) {
        _noiseController.repeat();
      }
    } catch (e) {
      print('Error initializing AnthropomorphicDeviceIcon: $e');
      // エラー時はデフォルト値を使用
      _status = DeviceStatus.healthy;
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _blinkController.dispose();
    _wobbleController.dispose();
    _noiseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAnimation) {
      return CustomPaint(
        size: Size(widget.size, widget.size),
        painter: AnthropomorphicIconPainter(
          status: _status,
          size: widget.size,
          breathingValue: 1.0,
          blinkValue: 1.0,
          wobbleValue: 0.0,
          noiseOffset: Offset.zero,
          deviceCategory: widget.device.category,
        ),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _breathingController,
        _blinkController,
        _wobbleController,
        _noiseController,
      ]),
      builder: (context, child) {
        // ブリージング値（0.95-1.05）
        final breathingValue = 0.95 +
            (_breathingController.value * 0.1);

        // 点滅値（0.3-1.0、needsMaintenance時のみ）
        final blinkValue = _status == DeviceStatus.needsMaintenance
            ? 0.3 + (_blinkController.value * 0.7)
            : 1.0;

        // 歪み値（-2度〜+2度、needsMaintenance時のみ）
        final wobbleValue = _status == DeviceStatus.needsMaintenance
            ? (math.sin(_wobbleController.value * 2 * math.pi) * 2)
            : 0.0;

        // ノイズオフセット（error時のみ）
        // アニメーションコントローラーの値に基づいてランダム性を追加
        final noiseSeed = _noiseController.value * 1000;
        final noiseRandom = math.Random(noiseSeed.toInt());
        final noiseOffset = _status == DeviceStatus.error
            ? Offset(
                (noiseRandom.nextDouble() - 0.5) * 0.5,
                (noiseRandom.nextDouble() - 0.5) * 0.5,
              )
            : Offset.zero;

        return Transform.translate(
          offset: noiseOffset,
          child: Transform.rotate(
            angle: wobbleValue * math.pi / 180,
            child: Opacity(
              opacity: blinkValue,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: AnthropomorphicIconPainter(
                  status: _status,
                  size: widget.size,
                  breathingValue: breathingValue,
                  blinkValue: blinkValue,
                  wobbleValue: wobbleValue,
                  noiseOffset: noiseOffset,
                  deviceCategory: widget.device.category,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 擬人化アイコンの描画ロジック
class AnthropomorphicIconPainter extends CustomPainter {
  final DeviceStatus status;
  final double size;
  final double breathingValue;
  final double blinkValue;
  final double wobbleValue;
  final Offset noiseOffset;
  final String deviceCategory; // 家電カテゴリ

  AnthropomorphicIconPainter({
    required this.status,
    required this.size,
    required this.breathingValue,
    required this.blinkValue,
    required this.wobbleValue,
    required this.noiseOffset,
    required this.deviceCategory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final statusColor = DeviceStatusService.getStatusColor(status);

    // 角丸四角形（背景）
    final rect = Rect.fromCenter(
      center: center,
      width: this.size * breathingValue,
      height: this.size * breathingValue,
    );
    final borderRadius = Radius.circular(this.size * 0.15);
    
    final backgroundPaint = Paint()
      ..color = statusColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, borderRadius),
      backgroundPaint,
    );

    // 外枠（極細線）
    final borderPaint = Paint()
      ..color = statusColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, borderRadius),
      borderPaint,
    );

    // 家電アイコン - 中央上部
    _drawDeviceIcon(canvas, center, status, statusColor);
  }

  /// カテゴリに応じたMaterial Iconを取得
  IconData _getDeviceIcon(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('エアコン') || categoryLower.contains('air')) {
      return Icons.ac_unit;
    } else if (categoryLower.contains('pc') || 
               categoryLower.contains('パソコン') || 
               categoryLower.contains('computer') ||
               categoryLower.contains('macbook')) {
      return Icons.computer;
    } else if (categoryLower.contains('テレビ') || categoryLower.contains('tv')) {
      return Icons.tv;
    } else if (categoryLower.contains('冷蔵庫') || categoryLower.contains('refrigerator')) {
      return Icons.kitchen;
    } else if (categoryLower.contains('洗濯機') || categoryLower.contains('washing')) {
      return Icons.local_laundry_service;
    } else if (categoryLower.contains('掃除機') || categoryLower.contains('vacuum')) {
      return Icons.cleaning_services;
    } else if (categoryLower.contains('電子レンジ') || categoryLower.contains('microwave')) {
      return Icons.microwave;
    } else if (categoryLower.contains('スマートフォン') || 
               categoryLower.contains('smartphone') ||
               categoryLower.contains('iphone')) {
      return Icons.smartphone;
    } else if (categoryLower.contains('カメラ') || categoryLower.contains('camera')) {
      return Icons.camera_alt;
    } else if (categoryLower.contains('オーディオ') || 
               categoryLower.contains('audio') ||
               categoryLower.contains('アンプ') ||
               categoryLower.contains('amp')) {
      return Icons.speaker;
    } else {
      return Icons.devices;
    }
  }

  /// 家電アイコンを描画
  void _drawDeviceIcon(Canvas canvas, Offset center, DeviceStatus status, Color statusColor) {
    final iconData = _getDeviceIcon(deviceCategory);
    final iconSize = size * 0.4;
    final iconY = center.dy - size * 0.1; // 中央上部

    // Material Iconを描画するためにTextPainterを使用
    final textStyle = TextStyle(
      fontFamily: 'MaterialIcons',
      fontSize: iconSize,
      color: statusColor.withValues(alpha: 0.7),
    );
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        iconY - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(AnthropomorphicIconPainter oldDelegate) {
    return oldDelegate.status != status ||
        oldDelegate.breathingValue != breathingValue ||
        oldDelegate.blinkValue != blinkValue ||
        oldDelegate.wobbleValue != wobbleValue ||
        oldDelegate.noiseOffset != noiseOffset;
  }
}
