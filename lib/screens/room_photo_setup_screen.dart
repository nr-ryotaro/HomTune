import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_usage_policy.dart';
import '../services/config_service.dart';
import '../services/onboarding_prefs.dart';
import '../services/room_image_generation_service.dart';
import '../services/room_name_service.dart';
import '../services/room_photo_service.dart';
import '../widgets/ads/pro_upgrade_dialog.dart';
import '../widgets/ai/credit_exhaustion_dialog.dart';

/// 部屋カード画像のセットアップ（デフォルト + AI生成のみ。実写カスタムなし）
class RoomPhotoSetupScreen extends StatefulWidget {
  final bool isFirstLaunchFlow;

  const RoomPhotoSetupScreen({super.key, this.isFirstLaunchFlow = false});

  @override
  State<RoomPhotoSetupScreen> createState() => _RoomPhotoSetupScreenState();
}

class _RoomPhotoSetupScreenState extends State<RoomPhotoSetupScreen> {
  late List<String> _roomIds;
  final Map<String, String> _displayPaths = {};
  int _index = 0;
  bool _loading = true;
  bool _isGenerating = false;
  bool _didGenerateOnceThisSession = false;

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

  bool get _hasGeneratedImage {
    final path = _displayPaths[_currentRoomId] ?? '';
    return path.isNotEmpty && !RoomPhotoService.isAssetPath(path);
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
    Navigator.of(context).pop(true);
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
          title: const Text('AIで部屋画像を作る'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'スタイル指定から部屋カード用の画像を生成します。'
                  'Freeプランではアカウント全体で1回までです。',
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
        _didGenerateOnceThisSession = true;
      });
      final isPro = configService.subscriptionTier == SubscriptionTier.pro;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPro
                ? 'AI画像を生成して適用しました。'
                : 'お試し生成が完了しました。ほかの部屋はデフォルト画像のまま使えます。',
          ),
        ),
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
      if (message.contains('Freeプラン') ||
          message.contains('クレジット') ||
          message.contains('1回') ||
          message.contains('Pro')) {
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
    final generateLabel = _isGenerating
        ? '生成中...'
        : (_hasGeneratedImage ? 'AIで再生成する' : 'AIで部屋画像を作る');

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        title: Text(
          '部屋のイメージ (${_index + 1}/${_roomIds.length})',
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
            child: const Text('完了'),
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
            Text(
              _didGenerateOnceThisSession
                  ? 'デフォルト画像のままでも使えます。FreeのAI生成はアカウント全体で1回までです。'
                  : '各部屋はデフォルト画像で使えます。雰囲気を変えたいときだけ AI で1枚作れます（Freeはアカウント生涯1回）。',
              style: const TextStyle(
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
            if (_hasGeneratedImage) ...[
              const SizedBox(height: 8),
              const Text(
                'この部屋はAI生成画像を表示中です',
                style: TextStyle(fontSize: 12, color: Color(0xFF16A34A)),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateWithAi,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(generateLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '撮影・アルバムからの実写登録はありません。画像はデフォルトまたはAI生成のみです。',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _skipRoom,
                child: Text(
                  _index < _roomIds.length - 1
                      ? 'この部屋はデフォルトのまま次へ'
                      : 'デフォルトのまま完了する',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
