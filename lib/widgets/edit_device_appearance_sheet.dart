import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appliance_presentation.dart';
import '../models/device.dart';
import '../services/appliance_template_service.dart';
import '../services/device_service.dart';

/// 家電の表示名・絵文字を編集するボトムシート
class EditDeviceAppearanceSheet extends StatefulWidget {
  final Device device;
  final AppliancePresentation defaultPresentation;

  const EditDeviceAppearanceSheet({
    super.key,
    required this.device,
    required this.defaultPresentation,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Device device,
    required AppliancePresentation defaultPresentation,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: EditDeviceAppearanceSheet(
          device: device,
          defaultPresentation: defaultPresentation,
        ),
      ),
    );
  }

  @override
  State<EditDeviceAppearanceSheet> createState() =>
      _EditDeviceAppearanceSheetState();
}

class _EditDeviceAppearanceSheetState extends State<EditDeviceAppearanceSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _iconController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final customName = widget.device.customDisplayName?.trim();
    final customIcon = widget.device.customIcon?.trim();
    _nameController = TextEditingController(
      text: (customName != null && customName.isNotEmpty)
          ? customName
          : widget.defaultPresentation.title,
    );
    _iconController = TextEditingController(
      text: (customIcon != null && customIcon.isNotEmpty)
          ? customIcon
          : widget.defaultPresentation.icon,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final icon = _iconController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('表示名を入力してください')),
      );
      return;
    }
    if (icon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('絵文字を1つ以上入力してください')),
      );
      return;
    }

    setState(() => _saving = true);
    await Provider.of<DeviceService>(context, listen: false)
        .updateDeviceAppearance(
      widget.device.id,
      displayName: name,
      icon: icon,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _reset() async {
    setState(() => _saving = true);
    await Provider.of<DeviceService>(context, listen: false)
        .updateDeviceAppearance(
      widget.device.id,
      resetToDefault: true,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '表示のカスタマイズ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ホームや一覧に表示される名前と絵文字を変更できます。\n'
              '型番（${widget.device.modelNumber.isNotEmpty ? widget.device.modelNumber : '未登録'}）は登録情報のままです。',
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _iconController,
              decoration: const InputDecoration(
                labelText: '絵文字',
                hintText: '例: 📺',
                border: OutlineInputBorder(),
              ),
              maxLength: 8,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '表示名',
                hintText: '例: テレビ',
                border: OutlineInputBorder(),
              ),
              maxLength: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'デフォルト: ${widget.defaultPresentation.icon} ${widget.defaultPresentation.title}',
              style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('保存'),
            ),
            TextButton(
              onPressed: _saving ? null : _reset,
              child: const Text('デフォルトに戻す'),
            ),
          ],
        ),
      ),
    );
  }
}

/// テンプレ由来のデフォルト表示（カスタム未適用）
Future<AppliancePresentation> resolveDefaultPresentation(Device device) {
  return ApplianceTemplateService.instance
      .resolvePresentation(
        device.copyWith(customDisplayName: '', customIcon: ''),
      );
}
