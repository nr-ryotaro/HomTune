import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/device_service.dart';
import '../models/room.dart';
import '../screens/manual_registration_screen.dart';
import '../models/device.dart';

class DeviceForm extends StatelessWidget {
  final String modelNumber;
  final String name;
  final String category;
  final String manufacturer;
  final String purchaseDate;
  final String serialNumber;
  final int purchasePrice;
  final int warrantyYears;
  final String room;
  final String location;
  final String notes;
  final File? selectedImage;
  final Map<String, String>? scannedData;
  final Device? existingDevice; // 既存デバイス（編集時）
  
  final ValueChanged<String> onModelNumberChanged;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onManufacturerChanged;
  final ValueChanged<String> onPurchaseDateChanged;
  final ValueChanged<String> onSerialNumberChanged;
  final ValueChanged<int> onPurchasePriceChanged;
  final ValueChanged<int> onWarrantyYearsChanged;
  final ValueChanged<String> onRoomChanged;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<String> onNotesChanged;
  final Function(ImageSource) onImagePicked;
  final VoidCallback onSubmit;
  final bool isProcessing;

  const DeviceForm({
    super.key,
    required this.modelNumber,
    required this.name,
    required this.category,
    required this.manufacturer,
    required this.purchaseDate,
    required this.serialNumber,
    required this.purchasePrice,
    required this.warrantyYears,
    required this.room,
    required this.location,
    required this.notes,
    this.selectedImage,
    this.scannedData,
    this.existingDevice,
    required this.onModelNumberChanged,
    required this.onNameChanged,
    required this.onCategoryChanged,
    required this.onManufacturerChanged,
    required this.onPurchaseDateChanged,
    required this.onSerialNumberChanged,
    required this.onPurchasePriceChanged,
    required this.onWarrantyYearsChanged,
    required this.onRoomChanged,
    required this.onLocationChanged,
    required this.onNotesChanged,
    required this.onImagePicked,
    required this.onSubmit,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    final rooms = deviceService.rooms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 画像アップロードセクション
        _buildImageSection(context),
        const SizedBox(height: 32),

        // マニュアル設定セクション
        _buildManualSection(context),
        const SizedBox(height: 32),

        // 必須項目
        _buildSectionTitle('必須項目'),
        const SizedBox(height: 16),

        // 型番
        _buildTextField(
          label: '型番',
          value: modelNumber,
          onChanged: onModelNumberChanged,
          hintText: '例: CS-ZX2811',
          isRequired: true,
          isAutoFilled: scannedData?['modelNumber'] != null,
        ),
        const SizedBox(height: 16),

        // 製品名
        _buildTextField(
          label: '製品名',
          value: name,
          onChanged: onNameChanged,
          hintText: '例: エアコン リビング',
          isRequired: true,
          isAutoFilled: scannedData?['name'] != null,
        ),
        const SizedBox(height: 16),

        // カテゴリ
        _buildTextField(
          label: 'カテゴリ',
          value: category,
          onChanged: onCategoryChanged,
          hintText: '例: エアコン',
          isRequired: true,
          isAutoFilled: scannedData?['category'] != null,
        ),
        const SizedBox(height: 16),

        // メーカー
        _buildTextField(
          label: 'メーカー',
          value: manufacturer,
          onChanged: onManufacturerChanged,
          hintText: '例: ダイキン',
          isRequired: true,
          isAutoFilled: scannedData?['manufacturer'] != null,
        ),
        const SizedBox(height: 16),

        // 購入日
        _buildDateField(context),
        const SizedBox(height: 32),

        // 任意項目
        _buildSectionTitle('任意項目'),
        const SizedBox(height: 16),

        // シリアル番号
        _buildTextField(
          label: 'シリアル番号',
          value: serialNumber,
          onChanged: onSerialNumberChanged,
          hintText: '例: SN123456789',
          isRequired: false,
          isAutoFilled: scannedData?['serialNumber'] != null && scannedData!['serialNumber']!.isNotEmpty,
        ),
        const SizedBox(height: 16),

        // 購入価格
        _buildPriceField(),
        const SizedBox(height: 16),

        // 保証期間
        _buildWarrantyField(),
        const SizedBox(height: 16),

        // 設置場所（部屋）
        _buildRoomField(rooms),
        const SizedBox(height: 16),

        // 設置場所（詳細）
        _buildTextField(
          label: '設置場所（詳細）',
          value: location,
          onChanged: onLocationChanged,
          hintText: '例: リビング南側',
          isRequired: false,
        ),
        const SizedBox(height: 16),

        // メモ
        _buildTextField(
          label: 'メモ',
          value: notes,
          onChanged: onNotesChanged,
          hintText: '消耗品のストック場所や配線の注意点など',
          isRequired: false,
          maxLines: 3,
        ),
        const SizedBox(height: 32),

        // 登録ボタン
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isProcessing ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3b82f6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            child: isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    '登録する',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '機材写真',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        if (selectedImage != null)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFFE5E5E5),
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                selectedImage!,
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFFE5E5E5),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  '写真を撮影または選択',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onImagePicked(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 16),
                label: const Text(
                  'カメラで撮影',
                  style: TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(
                    color: Color(0xFFE5E5E5),
                    width: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onImagePicked(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 16),
                label: const Text(
                  'ギャラリーから選択',
                  style: TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(
                    color: Color(0xFFE5E5E5),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF333333),
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    String? hintText,
    bool isRequired = false,
    bool isAutoFilled = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ],
            if (isAutoFilled) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.auto_awesome,
                size: 14,
                color: Colors.amber[700],
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
              fontWeight: FontWeight.w300,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(
                color: Color(0xFFE5E5E5),
                width: 0.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(
                color: Color(0xFFE5E5E5),
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(
                color: Color(0xFF3b82f6),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.2,
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '必須項目です';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              '購入日',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
              ),
            ),
            SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF3b82f6),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              final formattedDate =
                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
              onPurchaseDateChanged(formattedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: const Color(0xFFE5E5E5),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  purchaseDate,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.2,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '購入価格',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: purchasePrice > 0 ? purchasePrice.toString() : '',
          onChanged: (value) {
            final price = int.tryParse(value) ?? 0;
            onPurchasePriceChanged(price);
          },
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '例: 180000',
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
              fontWeight: FontWeight.w300,
            ),
            prefixText: '¥ ',
            prefixStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(
                color: Color(0xFFE5E5E5),
                width: 0.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(
                color: Color(0xFFE5E5E5),
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(
                color: Color(0xFF3b82f6),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildWarrantyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '保証期間',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: warrantyYears > 0 ? warrantyYears : null,
          decoration: InputDecoration(
            hintText: '選択してください',
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
              fontWeight: FontWeight.w300,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(
                color: Color(0xFFE5E5E5),
                width: 0.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(
                color: Color(0xFFE5E5E5),
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(
                color: Color(0xFF3b82f6),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: [1, 2, 3, 5, 7, 10].map((years) {
            return DropdownMenuItem<int>(
              value: years,
              child: Text(
                '$years年',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onWarrantyYearsChanged(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildRoomField(List<Room> rooms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '設置場所（部屋）',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: room.isNotEmpty ? room : null,
          decoration: InputDecoration(
            hintText: '選択してください',
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
              fontWeight: FontWeight.w300,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(
                color: Color(0xFFE5E5E5),
                width: 0.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(
                color: Color(0xFFE5E5E5),
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: const BorderSide(
                color: Color(0xFF3b82f6),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: rooms.map((r) {
            return DropdownMenuItem<String>(
              value: r.id,
              child: Text(
                r.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onRoomChanged(value);
            }
          },
        ),
      ],
    );
  }

  /// マニュアル設定セクション
  Widget _buildManualSection(BuildContext context) {
    final hasManual = existingDevice?.manual != null &&
        existingDevice!.manual!.url.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('マニュアル設定'),
        const SizedBox(height: 16),
        if (hasManual)
          // 登録済みマニュアルの表示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFFE5E5E5),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf,
                  color: Color(0xFFef4444),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'マニュアルが登録されています',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        existingDevice!.manual!.source == 'scanned'
                            ? 'スキャン生成'
                            : existingDevice!.manual!.source == 'uploaded'
                                ? 'アップロード'
                                : '公式サイト',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ManualRegistrationScreen(
                          device: existingDevice!,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    '変更',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        else
          // マニュアル未登録の場合
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // 一時的なデバイスオブジェクトを作成（登録前）
                    final tempDevice = Device(
                      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
                      name: name.isNotEmpty ? name : '新規デバイス',
                      modelNumber: modelNumber,
                      category: category,
                      manufacturer: manufacturer,
                      purchaseDate: purchaseDate,
                      purchasePrice: purchasePrice,
                      yearsOwned: 0,
                      room: room,
                      location: location,
                      status: 'active',
                      consumables: [],
                      photos: [],
                      documents: [],
                    );

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ManualRegistrationScreen(
                          device: tempDevice,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('マニュアルを登録'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(
                      color: Color(0xFF3b82f6),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
