import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../services/config_service.dart';
import '../services/device_service.dart';
import '../services/manual_search_service.dart';
import '../services/scanner_service.dart';
import 'add_device_screen.dart';

/// Smart Ingester: バーコード（JAN）＋製品プレート撮影のマルチスキャン画面
/// - バーコード検知時は即製品取得フローへ
/// - それ以外はシャッターでOCR用写真を撮影
class ScanScreen extends StatefulWidget {
  final String? initialRoomId;

  const ScanScreen({super.key, this.initialRoomId});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  ScannerService? _scannerService;
  ManualSearchService? _manualSearchService;

  MobileScannerController? _controller;
  ScanMode _mode = ScanMode.barcode;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _janCode;
  ExtractedProductInfo? _extracted;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scannerService == null) {
      final config = Provider.of<ConfigService>(context, listen: false);
      _scannerService = ScannerService(config);
      _manualSearchService = ManualSearchService(config);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scannerService?.dispose();
    _manualSearchService?.close();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing || _mode != ScanMode.barcode) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _janCode = code;
    });

    _handleJanCode(code);
  }

  Future<void> _handleJanCode(String jan) async {
    // JAN → 製品情報の取得は外部APIが必要。ここではモックとして
    // 「JANを読み取りました。プレート撮影するか手入力で登録してください」と案内
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('JANコードを読み取りました: $jan。製品プレートを撮影するか、手入力で登録してください。'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '手入力',
          onPressed: () => _navigateToManualInput(janCode: jan),
        ),
      ),
    );
    setState(() => _janCode = jan);
  }

  Future<void> _capturePlate() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _extracted = null;
    });

    try {
      final XFile? x = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (x == null || !mounted) {
        setState(() => _isProcessing = false);
        return;
      }
      final file = File(x.path);
      final info = await _scannerService!.processPlateImage(file);
      if (!mounted) return;
      setState(() {
        _extracted = info;
        _isProcessing = false;
      });
    } on ScannerException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isProcessing = false;
      });
      _showFallbackSnackBar(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '処理中にエラーが発生しました: $e';
        _isProcessing = false;
      });
      _showFallbackSnackBar('型番を特定できませんでした。手入力で登録してください。');
    }
  }

  void _showFallbackSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '手入力で登録',
          onPressed: _navigateToManualInput,
        ),
      ),
    );
  }

  void _navigateToManualInput({String? janCode}) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddDeviceScreen(
          initialRoomId: widget.initialRoomId,
          initialJanCode: janCode,
          initialManufacturer: _extracted?.manufacturer,
          initialModelNumber: _extracted?.modelNumber,
          initialCategory: _extracted?.category,
          initialName: _extracted != null && _extracted!.modelNumber.isNotEmpty
              ? '${_extracted!.manufacturer} ${_extracted!.modelNumber}'
              : null,
        ),
      ),
    );
  }

  Future<void> _registerAndArchive(ExtractedProductInfo info) async {
    if (info.isEmpty) {
      _showFallbackSnackBar('メーカー・型番が取得できていません。手入力で登録してください。');
      return;
    }

    setState(() => _isProcessing = true);
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    final now = DateTime.now();
    final purchaseDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    const yearsOwned = 0.0;
    final name = info.modelNumber.isNotEmpty
        ? '${info.manufacturer} ${info.modelNumber}'
        : info.manufacturer;

    final device = Device(
      id: 'device-${now.millisecondsSinceEpoch}',
      name: name,
      modelNumber: info.modelNumber,
      category: info.category.isEmpty ? 'その他' : info.category,
      manufacturer: info.manufacturer,
      purchaseDate: purchaseDate,
      purchasePrice: 0,
      yearsOwned: yearsOwned,
      room: widget.initialRoomId ?? '',
      location: '',
      status: 'active',
      maintenance: null,
      manual: null,
      janCode: _janCode,
      consumables: [],
      warranty: null,
      assetValue: null,
      safetyInfo: null,
      photos: [],
      documents: [],
    );

    try {
      await deviceService.addDevice(device);
      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('登録しました。説明書の検索をバックグラウンドで実行しています。'),
          duration: Duration(seconds: 2),
        ),
      );

      _runManualSearchInBackground(device.id, info.manufacturer, info.modelNumber, deviceService);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登録に失敗しました: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _runManualSearchInBackground(
    String deviceId,
    String manufacturer,
    String modelNumber,
    DeviceService deviceService,
  ) async {
    try {
      final url = await _manualSearchService!.searchManualUrl(manufacturer, modelNumber);
      if (url == null || url.isEmpty) return;

      final manual = Manual(
        url: url,
        autoGenerated: true,
        lastUpdated: DateTime.now().toIso8601String(),
        source: 'official',
      );
      await deviceService.updateDeviceManual(deviceId, manual);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ManualSearchService.archiveCompleteMessage),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Smart Ingester',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: Colors.white24, height: 0.5),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller!,
            onDetect: _onBarcodeDetected,
          ),
          _ThinLineScanOverlay(mode: _mode),
          _buildModeToggle(),
          if (_mode == ScanMode.plate) _buildShutterButton(),
          if (_isProcessing) _buildProcessingOverlay(),
          if (_errorMessage != null) _buildErrorBanner(),
          if (_extracted != null && !_isProcessing) _buildResultSheet(),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _modeChip('バーコード', ScanMode.barcode),
              const SizedBox(width: 8),
              _modeChip('プレート撮影', ScanMode.plate),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeChip(String label, ScanMode mode) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = mode;
          _errorMessage = null;
          _extracted = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: selected ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildShutterButton() {
    return Positioned(
      bottom: 48,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isProcessing ? null : _capturePlate,
            customBorder: const CircleBorder(),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: Colors.black45,
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              '解析中...',
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Positioned(
      bottom: 120,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.red.shade900,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _errorMessage = null),
                child: const Text('閉じる', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSheet() {
    final info = _extracted!;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '読み取り結果',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              _resultRow('メーカー', info.manufacturer),
              _resultRow('型番', info.modelNumber),
              _resultRow('カテゴリ', info.category),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => _navigateToManualInput(janCode: _janCode),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white38),
                    ),
                    child: const Text('手入力で登録'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: info.isEmpty ? null : () => _registerAndArchive(info),
                      style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
                      child: const Text('この内容で登録'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

enum ScanMode { barcode, plate }

/// Thin Line スキャンガイド枠（ミニマル）
class _ThinLineScanOverlay extends StatelessWidget {
  final ScanMode mode;

  const _ThinLineScanOverlay({required this.mode});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ThinLineScanPainter(mode: mode),
        size: Size.infinite,
      ),
    );
  }
}

class _ThinLineScanPainter extends CustomPainter {
  final ScanMode mode;

  _ThinLineScanPainter({required this.mode});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 1.0;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    const padding = 48.0;
    final w = size.width - padding * 2;
    final h = size.height * 0.35;
    final top = size.height * 0.3;
    const left = padding;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, w, h),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ThinLineScanPainter old) => old.mode != mode;
}
