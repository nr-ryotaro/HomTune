import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/ai_usage_policy.dart';
import 'ai_routing_service.dart';
import 'ai_usage_service.dart';
import 'analytics_service.dart';
import 'config_service.dart';

class RoomImageGenerationService {
  Future<String> generateRoomImage({
    required ConfigService configService,
    required String roomId,
    required String roomName,
    required String stylePrompt,
  }) async {
    final credits = AiRoutingService.instance.defaultCreditsForFeature(
      AiFeature.roomImage,
    );
    final budget = await AiUsageService.instance.canRunRoomImage(
      configService,
      roomId: roomId,
      requestedCredits: credits,
    );
    if (!budget.allowed) {
      throw RoomImageGenerationException(budget.reason, budget: budget);
    }
    final apiKey = configService.geminiApiKey;
    if (apiKey.isEmpty) {
      throw RoomImageGenerationException(
        '接続情報が未設定のため、AI画像生成を利用できません。',
      );
    }

    final style = await _buildStyleSpec(
      apiKey: apiKey,
      modelId: configService.geminiModelFor(AiFeature.roomImage),
      roomName: roomName,
      stylePrompt: stylePrompt,
    );
    final outputPath = await _renderImageLocally(
      roomName: roomName,
      styleSpec: style,
    );

    await AiUsageService.instance.recordRoomImageUsage(
      configService,
      roomId: roomId,
      consumedCredits: credits,
    );
    await AnalyticsService.logEvent(
      event: 'room_image_generated',
      properties: {
        'roomName': roomName,
        'stylePromptLength': stylePrompt.length,
      },
    );
    return outputPath;
  }

  Future<Map<String, dynamic>> _buildStyleSpec({
    required String apiKey,
    required String modelId,
    required String roomName,
    required String stylePrompt,
  }) async {
    final model = GenerativeModel(model: modelId, apiKey: apiKey);
    final prompt = '''
あなたはインテリアコンセプトを作るデザイナーです。
部屋カード向けに、次の条件でJSONだけ返してください。

部屋名: $roomName
要望: $stylePrompt

{
  "palette": ["#RRGGBB", "#RRGGBB", "#RRGGBB"],
  "accent": "#RRGGBB",
  "headline": "12文字以内の短いタイトル",
  "motifs": ["家具/家電モチーフ1", "モチーフ2", "モチーフ3"]
}
''';
    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text?.trim() ?? '';
    if (text.isEmpty) {
      return _fallbackStyle(roomName);
    }
    try {
      var jsonText = text;
      final codeBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
      final match = codeBlock.firstMatch(text);
      if (match != null) {
        jsonText = match.group(1)?.trim() ?? text;
      }
      return jsonDecode(jsonText) as Map<String, dynamic>;
    } catch (_) {
      return _fallbackStyle(roomName);
    }
  }

  Future<String> _renderImageLocally({
    required String roomName,
    required Map<String, dynamic> styleSpec,
  }) async {
    final palette = (styleSpec['palette'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.startsWith('#') && e.length == 7)
            .toList() ??
        ['#D7E3FC', '#EDF2FB', '#CCDBFD'];
    final accent = _toColor(styleSpec['accent']?.toString() ?? '#3B82F6');
    final headline = (styleSpec['headline']?.toString().trim().isNotEmpty ?? false)
        ? styleSpec['headline'].toString().trim()
        : roomName;
    final motifs = (styleSpec['motifs'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList() ??
        const ['Sofa', 'Lamp', 'Plant'];

    final image = img.Image(width: 1024, height: 768);
    final c0 = _toColor(palette[0]);
    final c1 = _toColor(palette[min(1, palette.length - 1)]);
    final c2 = _toColor(palette[min(2, palette.length - 1)]);
    _drawGradient(image, c0, c1, c2);

    final rand = Random(DateTime.now().millisecondsSinceEpoch);
    for (var i = 0; i < 14; i++) {
      final x = rand.nextInt(1024);
      final y = rand.nextInt(768);
      final radius = 16 + rand.nextInt(78);
      img.fillCircle(image, x: x, y: y, radius: radius, color: accent);
    }

    img.fillRect(image,
        x1: 40,
        y1: 560,
        x2: 984,
        y2: 728,
        color: img.ColorUint8.rgba(255, 255, 255, 210));
    img.drawString(
      image,
      headline,
      font: img.arial48,
      x: 56,
      y: 586,
      color: img.ColorUint8.rgb(40, 40, 40),
    );
    img.drawString(
      image,
      motifs.take(3).join('  |  '),
      font: img.arial24,
      x: 58,
      y: 652,
      color: img.ColorUint8.rgb(80, 80, 80),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'room_ai_${roomName.replaceAll(RegExp(r"\\s+"), "_")}_${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = '${dir.path}/$fileName';
    final bytes = img.encodePng(image, level: 4);
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  void _drawGradient(img.Image image, img.Color c0, img.Color c1, img.Color c2) {
    for (var y = 0; y < image.height; y++) {
      final t = y / image.height;
      final top = _lerpColor(c0, c1, t);
      final bottom = _lerpColor(c1, c2, t);
      for (var x = 0; x < image.width; x++) {
        final tx = x / image.width;
        image.setPixel(x, y, _lerpColor(top, bottom, tx));
      }
    }
  }

  img.Color _lerpColor(img.Color a, img.Color b, double t) {
    final r = (a.r + (b.r - a.r) * t).round();
    final g = (a.g + (b.g - a.g) * t).round();
    final bl = (a.b + (b.b - a.b) * t).round();
    return img.ColorUint8.rgb(r, g, bl);
  }

  img.Color _toColor(String hex) {
    final sanitized = hex.replaceAll('#', '');
    if (sanitized.length != 6) return img.ColorUint8.rgb(59, 130, 246);
    final value = int.tryParse(sanitized, radix: 16) ?? 0x3B82F6;
    return img.ColorUint8.rgb(
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    );
  }

  Map<String, dynamic> _fallbackStyle(String roomName) {
    return {
      'palette': ['#D7E3FC', '#EDF2FB', '#CCDBFD'],
      'accent': '#3B82F6',
      'headline': '$roomName Style',
      'motifs': ['Lighting', 'Wood', 'Comfort'],
    };
  }
}

class RoomImageGenerationException implements Exception {
  final String message;
  final AiBudgetCheck? budget;

  RoomImageGenerationException(this.message, {this.budget});

  @override
  String toString() => message;
}
