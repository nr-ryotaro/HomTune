import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:math' as math;
import '../models/appliance_archetype.dart';
import '../models/device.dart';
import '../services/appliance_template_service.dart';
import '../services/device_service.dart';
import '../services/manual_link_resolver.dart';
import '../services/ocr_service.dart';
import '../widgets/device_form.dart';

class AddDeviceScreen extends StatefulWidget {
  final String? initialRoomId;
  /// Smart Ingester からの初期値
  final String? initialJanCode;
  final String? initialManufacturer;
  final String? initialModelNumber;
  final String? initialCategory;
  final String? initialName;
  final String? initialArchetypeId;

  const AddDeviceScreen({
    super.key,
    this.initialRoomId,
    this.initialJanCode,
    this.initialManufacturer,
    this.initialModelNumber,
    this.initialCategory,
    this.initialName,
    this.initialArchetypeId,
  });

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _selectedImage;
  bool _isScanning = false;
  bool _isProcessing = false;
  Map<String, String>? _scannedData;
  
  // フォームデータ
  String _modelNumber = '';
  String _name = '';
  String _category = '';
  String _manufacturer = '';
  String _purchaseDate = '';
  String _serialNumber = '';
  int _purchasePrice = 0;
  int _warrantyYears = 0;
  String _room = '';
  String _location = '';
  String _notes = '';
  final List<String> _photos = [];
  String? _selectedArchetypeId;
  List<ApplianceArchetype> _roomArchetypes = [];
  bool _loadingArchetypes = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoomId != null) _room = widget.initialRoomId!;
    if (widget.initialManufacturer != null) _manufacturer = widget.initialManufacturer!;
    if (widget.initialModelNumber != null) _modelNumber = widget.initialModelNumber!;
    if (widget.initialCategory != null) _category = widget.initialCategory!;
    if (widget.initialName != null) _name = widget.initialName!;
    _selectedArchetypeId = widget.initialArchetypeId;
    final now = DateTime.now();
    _purchaseDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (_room.isNotEmpty) {
      _loadArchetypesForRoom(_room);
    }
  }

  Future<void> _loadArchetypesForRoom(String roomId) async {
    if (roomId.isEmpty) return;
    setState(() => _loadingArchetypes = true);
    final list =
        await ApplianceTemplateService.instance.getArchetypesForRoom(roomId);
    if (!mounted) return;
    setState(() {
      _roomArchetypes = list;
      _loadingArchetypes = false;
    });
  }

  void _applyArchetype(ApplianceArchetype archetype) {
    setState(() {
      _selectedArchetypeId = archetype.id;
      _category = archetype.category;
      if (_name.isEmpty) _name = archetype.displayName;
      if (_location.isEmpty && archetype.defaultLocationHint.isNotEmpty) {
        _location = archetype.defaultLocationHint;
      }
    });
    if (_manufacturer.isNotEmpty && _modelNumber.isNotEmpty) {
      ManualLinkResolver.instance.prefetch(_manufacturer, _modelNumber);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isScanning = true;
        });

        // OCR解析（モック）
        await _scanImage(_selectedImage!);
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像の選択に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _scanImage(File image) async {
    // 精密に調律中のアニメーション表示
    setState(() {
      _isScanning = true;
    });

    // モックOCR解析（実際の実装ではOCRサービスを呼び出す）
    await Future.delayed(const Duration(seconds: 2));

    final ocrService = OCRService();
    final scannedData = await ocrService.scanImage(image);

    if (!mounted) return;

    setState(() {
      _isScanning = false;
      _scannedData = scannedData;
      
      // 解析結果をフォームに反映
      if (scannedData['modelNumber'] != null) {
        _modelNumber = scannedData['modelNumber']!;
      }
      if (scannedData['manufacturer'] != null) {
        _manufacturer = scannedData['manufacturer']!;
      }
      if (scannedData['name'] != null) {
        _name = scannedData['name']!;
      }
      if (scannedData['category'] != null) {
        _category = scannedData['category']!;
      }
      if (scannedData['serialNumber'] != null) {
        _serialNumber = scannedData['serialNumber']!;
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final deviceService = Provider.of<DeviceService>(context, listen: false);
      
      // 購入日から経過年数を計算
      final purchaseDateTime = DateTime.parse(_purchaseDate);
      final now = DateTime.now();
      final yearsOwned = now.difference(purchaseDateTime).inDays / 365.0;

      // デバイスオブジェクトを作成（Smart Ingester 由来の JAN があれば付与）
      final device = Device(
        id: 'device-${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        modelNumber: _modelNumber,
        category: _category,
        manufacturer: _manufacturer,
        purchaseDate: _purchaseDate,
        purchasePrice: _purchasePrice,
        yearsOwned: yearsOwned,
        room: _room,
        location: _location,
        status: 'active',
        maintenance: null,
        manual: null,
        janCode: widget.initialJanCode,
        consumables: [],
        warranty: null,
        assetValue: null,
        photos: _photos,
        documents: [],
        archetypeId: _selectedArchetypeId,
      );

      // デバイスを追加（モック実装）
      await deviceService.addDevice(
        device,
        archetypeId: _selectedArchetypeId,
      );

      if (mounted) {
        // 成功メッセージ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('家が調律されました'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('Error adding device: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登録に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '家電を追加',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            color: const Color(0xFFE5E5E5),
            height: 0.5,
          ),
        ),
      ),
      body: _isScanning
          ? _buildScanningView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_room.isNotEmpty) _buildArchetypeSuggestions(),
                    DeviceForm(
                  modelNumber: _modelNumber,
                  name: _name,
                  category: _category,
                  manufacturer: _manufacturer,
                  purchaseDate: _purchaseDate,
                  serialNumber: _serialNumber,
                  purchasePrice: _purchasePrice,
                  warrantyYears: _warrantyYears,
                  room: _room,
                  location: _location,
                  notes: _notes,
                  selectedImage: _selectedImage,
                  scannedData: _scannedData,
                  onModelNumberChanged: (value) => setState(() => _modelNumber = value),
                  onNameChanged: (value) => setState(() => _name = value),
                  onCategoryChanged: (value) => setState(() => _category = value),
                  onManufacturerChanged: (value) => setState(() => _manufacturer = value),
                  onPurchaseDateChanged: (value) => setState(() => _purchaseDate = value),
                  onSerialNumberChanged: (value) => setState(() => _serialNumber = value),
                  onPurchasePriceChanged: (value) => setState(() => _purchasePrice = value),
                  onWarrantyYearsChanged: (value) => setState(() => _warrantyYears = value),
                  onRoomChanged: (value) {
                    setState(() {
                      _room = value;
                      _selectedArchetypeId = null;
                    });
                    _loadArchetypesForRoom(value);
                  },
                  onLocationChanged: (value) => setState(() => _location = value),
                  onNotesChanged: (value) => setState(() => _notes = value),
                  onImagePicked: _pickImage,
                  onSubmit: _submitForm,
                  isProcessing: _isProcessing,
                ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildArchetypeSuggestions() {
    if (_loadingArchetypes) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (_roomArchetypes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'この部屋でよくある家電',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _roomArchetypes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final a = _roomArchetypes[index];
                final selected = _selectedArchetypeId == a.id;
                return ChoiceChip(
                  label: Text('${a.icon} ${a.displayName}'),
                  selected: selected,
                  onSelected: (_) => _applyArchetype(a),
                  selectedColor: const Color(0xFFE8F4EA),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 精密に調律中のアニメーション
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // 外側の円（回転）
                  Transform.rotate(
                    angle: value * 2 * 3.14159,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3b82f6).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: CustomPaint(
                        painter: _PrecisionDialPainter(value),
                      ),
                    ),
                  ),
                  // 中央のアイコン
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3b82f6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 30,
                      color: Color(0xFF3b82f6),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            '精密に調律中...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: Color(0xFF666666),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '型番とメーカー情報を解析しています',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrecisionDialPainter extends CustomPainter {
  final double progress;

  _PrecisionDialPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3b82f6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // 精密な目盛りを描画
    for (int i = 0; i < 60; i++) {
      final angle = (i / 60) * 2 * 3.14159;
      final startRadius = i % 5 == 0 ? radius - 8 : radius - 4;
      final endRadius = radius;

                      final startX = center.dx + startRadius * _cos(angle);
                      final startY = center.dy + startRadius * _sin(angle);
                      final endX = center.dx + endRadius * _cos(angle);
                      final endY = center.dy + endRadius * _sin(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PrecisionDialPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// 数学関数のヘルパー
double _cos(double angle) => math.cos(angle);
double _sin(double angle) => math.sin(angle);
