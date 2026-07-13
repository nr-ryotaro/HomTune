import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/config_service.dart';
import '../services/onboarding_prefs.dart';
import '../services/room_image_generation_service.dart';
import '../services/room_name_service.dart';
import '../services/room_photo_service.dart';
import '../utils/platform_support.dart';
import '../widgets/ads/pro_upgrade_dialog.dart';
import '../widgets/ai/credit_exhaustion_dialog.dart';

/// 家電登録後に部屋の写真を設定するフロー
class RoomPhotoSetupScreen extends StatefulWidget {
  final bool isFirstLaunchFlow;

  const RoomPhotoSetupScreen({super.key, this.isFirstLaunchFlow = false});

  @override
  State<RoomPhotoSetupScreen> createState() => _RoomPhotoSetupScreenState();
}

class _RoomPhotoSetupScreenState extends State<RoomPhotoSetupScreen> {
  final ImagePicker _picker = ImagePicker();
  late List<String> _roomIds;
  final Map<String, String> _displayPaths = {};
  int _index = 0;
  bool _loading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await RoomNameService.instance.load();
    final ids = await OnboardingPrefs.getSelectedRoomIds();
    _roomIds = ids
        .where((id) => OnboardingRoomCatalog.cardById.containsKey(id))
        .toList();
    if (_roomIds.isEmpty) {
      _roomIds = List.from(OnboardingRoomCatalog.defaultHomeRoomIds);
    }
    for (final id in _roomIds) {
      _displayPaths[id] = await RoomPhotoService.imagePathForRoom(id);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  String get _currentRoomId => _roomIds[_index];

  String get _currentRoomName =>
      OnboardingRoomCatalog.displayTitleFor(_currentRoomId);

  Future<void> _pickImage(ImageSource source) async {
    if (!PlatformSupport.supportsDevicePhotoPick && source == ImageSource.camera) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Webプレビューではギャラリーからの選択のみ利用できます'),
          ),
        );
      }
      if (source == ImageSource.camera) return;
    }

    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      await RoomPhotoService.setCustomImagePath(_currentRoomId, file.path);
      await RoomPhotoService.markFirstRoomPhotoIfNeeded();
      if (!mounted) return;
      setState(() {
        _displayPaths[_currentRoomId] = file.path;
      });
      _showPhotoAppliedFeedback(fromGallery: source == ImageSource.gallery);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像を取得できませんでした: $e')),
      );
    }
  }

  void _skipRoom() {
    if (_index < _roomIds.length - 1) {
      setState(() => _index++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await RoomPhotoService.setRoomPhotosConfigured(true);
    if (!mounted) return;
    if (widget.isFirstLaunchFlow) {
      Navigator.of(context).pop(true);
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _showPhotoAppliedFeedback({required bool fromGallery}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fromGallery
              ? '写真を設定しました。必要ならAIで雰囲気を整えられます。'
              : '写真を設定しました。',
        ),
        action: SnackBarAction(
          label: 'AIで整える',
          onPressed: _generateWithAi,
        ),
      ),
    );
  }

  bool get _hasCustomPhoto {
    final path = _displayPaths[_currentRoomId] ?? '';
    return path.isNotEmpty && !RoomPhotoService.isAssetPath(path);
  }

  Future<void> _generateWithAi() async {
    if (_isGenerating) return;
    final configService = Provider.of<ConfigService>(context, listen: false);
    final styleController = TextEditingController(
      text: '自然光が入り、落ち着いた雰囲気の$_currentRoomName',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('AIで雰囲気を整える'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_hasCustomPhoto)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    '選んだ写真をもとに、部屋の雰囲気を調整します。',
                    style: TextStyle(fontSize: 13, height: 1.45),
                  ),
                ),
              TextField(
                controller: styleController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '例: 北欧風、木目、明るいトーン',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('生成'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isGenerating = true);
    try {
      final service = RoomImageGenerationService();
      final generatedPath = await service.generateRoomImage(
        configService: configService,
        roomId: _currentRoomId,
        roomName: _currentRoomName,
        stylePrompt: styleController.text.trim(),
      );
      await RoomPhotoService.setCustomImagePath(_currentRoomId, generatedPath);
      await RoomPhotoService.markFirstRoomPhotoIfNeeded();
      if (!mounted) return;
      setState(() {
        _displayPaths[_currentRoomId] = generatedPath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI画像を生成して適用しました。')),
      );
    } catch (e) {
      if (!mounted) return;
      if (e is RoomImageGenerationException && e.budget != null) {
        final config = context.read<ConfigService>();
        await showCreditExhaustionDialog(
          context,
          config: config,
          check: e.budget!,
          upsellContext: ProUpsellContext.roomImage,
        );
        return;
      }
      final message = e is RoomImageGenerationException ? e.message : '$e';
      if (message.contains('Freeプラン') || message.contains('クレジット')) {
        await showProUpgradeDialog(
          context,
          upsellContext: ProUpsellContext.roomImage,
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI画像生成に失敗しました: $message')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Widget _buildPreviewImage(String path) {
    if (RoomPhotoService.isAssetPath(path)) {
      return Image.asset(path, fit: BoxFit.cover);
    }
    if (kIsWeb) {
      return Image.network(path, fit: BoxFit.cover);
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final path = _displayPaths[_currentRoomId] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        title: Text(
          '部屋の写真 (${_index + 1}/${_roomIds.length})',
          style: const TextStyle(
            fontWeight: FontWeight.w300,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('あとで'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentRoomName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'いつものお部屋の写真を登録すると、ホーム画面があなたの住まいらしくなります。\n'
              'まずは撮影するか、アルバムから選んでください。',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF777777),
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: path.isNotEmpty
                    ? _buildPreviewImage(path)
                    : Container(color: const Color(0xFFE5E5E5)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('写真を撮る'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('アルバムから選ぶ'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_hasCustomPhoto) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _isGenerating ? null : _generateWithAi,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_isGenerating ? '生成中...' : 'AIで雰囲気を整える（任意）'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _skipRoom,
                child: Text(
                  _index < _roomIds.length - 1 ? 'この部屋はスキップして次へ' : '完了する',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
