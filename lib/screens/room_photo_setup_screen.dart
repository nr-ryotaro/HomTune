import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/onboarding_prefs.dart';
import '../services/room_photo_service.dart';
import '../utils/platform_support.dart';

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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
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
      OnboardingRoomCatalog.cardById[_currentRoomId]?.title ?? _currentRoomId;

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
      if (!mounted) return;
      setState(() {
        _displayPaths[_currentRoomId] = file.path;
      });
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
              '今はサンプル画像が表示されています。',
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
