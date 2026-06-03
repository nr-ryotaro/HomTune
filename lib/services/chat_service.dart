import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/device.dart';
import '../models/local_response_plan.dart';
import 'config_service.dart';
import 'device_query_matcher.dart';
import 'local_response_planner.dart';

/// AI チャットサービス — Gemini API によるデバイストラブルシューティング
///
/// 機能:
/// - デバイスコンテキスト（型番・カテゴリ・安全情報）をプロンプトに注入
/// - 会話履歴の保持（セッション内）
/// - ダミーモードとリアルAPI モードの切り替え
class ChatService {
  final ConfigService _configService;

  /// Gemini セッション（会話履歴を保持）
  ChatSession? _chatSession;

  /// 現在コンテキストに設定されているデバイスリスト
  List<Device> _contextDevices = [];

  ChatService(this._configService);

  /// デバイスコンテキストを設定してセッションを初期化
  Future<void> initializeWithDevices(List<Device> devices) async {
    _contextDevices = devices;
    _chatSession = null; // 新しいコンテキストでリセット

    if (_configService.isUsingRealApi) {
      await _openChatSession(devices);
    }
  }

  /// メッセージを送信し、AI 応答を取得
  ///
  /// [userMessage] ユーザーの質問テキスト
  /// 戻り値: AI の応答テキスト
  Future<String> sendMessage(String userMessage) async {
    if (!_configService.isUsingRealApi || _chatSession == null) {
      return _generateLocalResponse(userMessage);
    }

    try {
      final response = await _chatSession!.sendMessage(
        Content.text(userMessage),
      );
      final text = response.text?.trim() ?? '';
      if (text.isEmpty) {
        return 'すみません、回答を生成できませんでした。もう一度お試しください。';
      }
      return text;
    } catch (e) {
      print('ChatService Error: $e');
      await _openChatSession(_contextDevices);
      if (_chatSession != null) {
        try {
          final retry = await _chatSession!.sendMessage(
            Content.text(userMessage),
          );
          final retryText = retry.text?.trim() ?? '';
          if (retryText.isNotEmpty) return retryText;
        } catch (retryError) {
          print('ChatService retry error: $retryError');
        }
      }
      return _generateLocalResponse(userMessage);
    }
  }

  /// ローカルテンプレート応答を強制利用（コスト制御向け）
  String sendLocalMessage(String userMessage) {
    return _generateLocalResponse(userMessage);
  }

  /// 登録デバイスに対するローカル回答計画（ルーティング用）
  LocalResponsePlan planLocalResponse(String userMessage) {
    return LocalResponsePlanner.plan(userMessage, _contextDevices);
  }

  static LocalResponsePlan planLocalResponseForDevices(
    String userMessage,
    List<Device> devices,
  ) {
    return LocalResponsePlanner.plan(userMessage, devices);
  }

  Future<void> _openChatSession(List<Device> devices) async {
    final apiKey = _configService.geminiApiKey;
    if (apiKey.isEmpty) {
      _chatSession = null;
      return;
    }

    final systemPrompt = await _buildSystemPrompt(devices);
    final primaryModel = _configService.geminiModel;

    try {
      _chatSession = _createChatSession(
        apiKey: apiKey,
        modelId: primaryModel,
        systemPrompt: systemPrompt,
      );
      return;
    } catch (e) {
      print('ChatService initialize error ($primaryModel): $e');
    }

    final probe = await _configService.testCloudConnection();
    if (!probe.success) {
      _chatSession = null;
      return;
    }

    if (probe.modelId != primaryModel) {
      await _configService.setGeminiModel(probe.modelId);
    }

    try {
      _chatSession = _createChatSession(
        apiKey: apiKey,
        modelId: probe.modelId,
        systemPrompt: systemPrompt,
      );
    } catch (e) {
      _chatSession = null;
      print('ChatService initialize error (${probe.modelId}): $e');
    }
  }

  ChatSession _createChatSession({
    required String apiKey,
    required String modelId,
    required String systemPrompt,
  }) {
    final model = GenerativeModel(
      model: modelId,
      apiKey: apiKey,
      systemInstruction: Content.text(systemPrompt),
    );
    return model.startChat();
  }

  /// システムプロンプトを構築（デバイスコンテキスト注入）
  Future<String> _buildSystemPrompt(List<Device> devices) async {
    final deviceSummaries = <String>[];

    for (final device in devices) {
      final parts = <String>[
        '- ${device.name}（${device.manufacturer} ${device.modelNumber}）',
        '  カテゴリ: ${device.category}',
        '  設置場所: ${_roomLabel(device.room)} / ${device.location}',
        '  所有期間: ${device.yearsOwned}年',
      ];

      // 安全情報
      if (device.safetyInfo?.isRecallActive == true) {
        final recall = device.safetyInfo!.recallDetails;
        parts.add('  ⚠️ リコール対象: ${recall?.description ?? "詳細不明"}');
        if (recall?.reason != null && recall!.reason.isNotEmpty) {
          parts.add('  リコール原因: ${recall.reason}');
        }
      }

      // メンテナンス情報
      if (device.maintenance != null) {
        if (device.maintenance!.lastMaintenance != null) {
          parts.add('  最終メンテナンス: ${device.maintenance!.lastMaintenance}');
        }
        if (device.maintenance!.nextMaintenance != null) {
          parts.add('  次回メンテナンス: ${device.maintenance!.nextMaintenance}');
        }
      }

      // 保証情報
      if (device.warranty?.manufacturer != null) {
        final warranty = device.warranty!.manufacturer!;
        parts.add(
            '  メーカー保証: ${warranty.expired ? "期限切れ" : "${warranty.expiryDate}まで有効"}');
      }

      // マニュアル URL
      if (device.manual?.url != null && device.manual!.url.isNotEmpty) {
        parts.add('  マニュアル: ${device.manual!.url}');
      }

      deviceSummaries.add(parts.join('\n'));
    }

    return '''あなたは HomTune（ホームチューン）アプリの AI アシスタントです。
ユーザーの家にある家電製品のトラブルシューティング、使い方の案内、メンテナンスアドバイスを行います。

## あなたの性格
- 親しみやすく、丁寧な口調
- 具体的で実用的なアドバイスを提供
- 安全に関わる問題は特に慎重に対応
- リコール対象製品については必ず注意喚起

## 登録デバイス一覧
${deviceSummaries.join('\n\n')}

## 回答ルール
1. ユーザーの質問に対して、上記デバイス情報を参照して具体的に回答してください
2. デバイス名、型番、メーカー名が質問に含まれる場合、該当デバイスの情報を活用してください
3. リコール対象製品について質問された場合、リコール情報を必ず含めてください
4. トラブルシューティングは段階的に（簡単な確認 → 本格的な対処）案内してください
5. 修理が必要と判断される場合は、メーカーサポートへの連絡を推奨してください
6. マニュアル URL がある場合は、関連する回答で案内してください
7. 回答は日本語で、マークダウン形式（リスト・太字など）を適度に使用してください
8. 安全に直結する問題（感電、発火、ガス漏れ等）は、まず使用中止を勧め、専門家への相談を推奨してください
''';
  }

  /// 部屋 ID をラベルに変換
  String _roomLabel(String roomId) {
    switch (roomId) {
      case 'living-room':
        return 'リビング';
      case 'study':
        return '書斎';
      case 'bedroom':
        return '寝室';
      case 'kitchen':
      case 'kitchen-01':
        return 'キッチン';
      case 'entrance':
        return '玄関';
      default:
        return roomId;
    }
  }

  Device? get _firstContextDevice =>
      _contextDevices.isEmpty ? null : _contextDevices.first;

  String _noDevicesResponse() =>
      'まだ家電が登録されていません。スキャンまたは手入力でデバイスを追加してください。';

  /// ローカル応答生成（ダミーモード or API フォールバック）
  ///
  /// デバイスコンテキストを活用した高品質なローカル応答
  String _generateLocalResponse(String userMessage) {
    if (_contextDevices.isEmpty) {
      return _noDevicesResponse();
    }

    final lowerMessage = userMessage.toLowerCase();

    final matchedDevice = DeviceQueryMatcher.findRelevant(
      userMessage,
      _contextDevices,
    );

    if (lowerMessage.contains('何台') ||
        lowerMessage.contains('何個') ||
        (lowerMessage.contains('登録') &&
            (lowerMessage.contains('何') || lowerMessage.contains('一覧')))) {
      return '現在 ${_contextDevices.length} 台の家電が登録されています。';
    }

    // リコール関連の質問
    if (lowerMessage.contains('リコール') ||
        lowerMessage.contains('安全') ||
        lowerMessage.contains('危険')) {
      final recalledDevices = _contextDevices
          .where((d) => d.safetyInfo?.isRecallActive == true)
          .toList();
      if (recalledDevices.isNotEmpty) {
        final buffer = StringBuffer('⚠️ リコール対象製品が見つかりました：\n\n');
        for (final d in recalledDevices) {
          buffer.writeln('**${d.name}**（${d.manufacturer} ${d.modelNumber}）');
          if (d.safetyInfo?.recallDetails != null) {
            buffer.writeln('・${d.safetyInfo!.recallDetails!.description}');
            buffer.writeln('・原因: ${d.safetyInfo!.recallDetails!.reason}');
            if (d.safetyInfo!.recallDetails!.manufacturerContactUrl != null) {
              buffer.writeln(
                  '・メーカー連絡先: ${d.safetyInfo!.recallDetails!.manufacturerContactUrl}');
            }
          }
          buffer.writeln();
        }
        buffer.writeln('対象製品をお持ちの場合は、直ちにメーカーの窓口にお問い合わせください。');
        return buffer.toString();
      } else {
        return '現在、登録されているデバイスにリコール対象の製品はありません。\n\n安心してご利用いただけます。';
      }
    }

    // 型番を聞く質問
    if (lowerMessage.contains('型番') || lowerMessage.contains('モデル')) {
      if (matchedDevice != null) {
        return '${matchedDevice.name}の型番は「${matchedDevice.modelNumber}」です。\n\n'
            'メーカー：${matchedDevice.manufacturer}\n'
            '${matchedDevice.manual?.url != null ? '\nマニュアル：${matchedDevice.manual!.url}' : ''}';
      }
    }

    // 電源がつかない問題
    if (lowerMessage.contains('電源') &&
        (lowerMessage.contains('つかない') || lowerMessage.contains('起動'))) {
      final device = matchedDevice ?? _firstContextDevice;
      if (device == null) return _noDevicesResponse();
      return '''${device.name}の電源がつかない場合の対処法：

**【基本的な確認】**
1. 電源ケーブルが正しく接続されているか確認
2. コンセントに電源が供給されているか確認
3. ブレーカーが落ちていないか確認

**【トラブルシューティング】**
- 電源ボタンを10秒間長押し（強制リセット）
- 電源ケーブルを一度外して30秒待ってから再接続
- 別のコンセントで試す

${device.category == 'PC' ? '**【PCの場合】**\n- SMCリセット（Mac）: Shift + Control + Option + 電源ボタンを同時に10秒間\n- バッテリーが完全に消耗していないか確認\n' : ''}問題が解決しない場合は、${device.manufacturer}のサポートにご連絡ください。
${device.manual?.url != null ? '\nマニュアル：${device.manual!.url}' : ''}''';
    }

    // エアコン関連
    if (lowerMessage.contains('エアコン') ||
        lowerMessage.contains('冷房') ||
        lowerMessage.contains('暖房')) {
      final acDevice =
          DeviceQueryMatcher.findAirConditioner(_contextDevices) ??
              matchedDevice ??
              _firstContextDevice;
      if (acDevice == null) return _noDevicesResponse();

      if (lowerMessage.contains('フィルター') ||
          lowerMessage.contains('掃除') ||
          lowerMessage.contains('クリーニング')) {
        return '''${acDevice.name}のフィルター掃除方法：

**【手順】**
1. エアコンの電源を切り、プラグを抜く
2. 前面パネルを開けてフィルターを取り外す
3. 掃除機でホコリを吸い取る
4. 汚れがひどい場合は水洗い（中性洗剤OK）
5. 完全に乾燥させてから再装着

**【推奨頻度】**
- フィルター掃除：2週間に1回
- 本体クリーニング：年1回（専門業者推奨）

${acDevice.maintenance?.nextMaintenance != null ? '次回メンテナンス予定：${acDevice.maintenance!.nextMaintenance}' : ''}
${acDevice.manual?.url != null ? '\n詳細はマニュアルをご確認ください：${acDevice.manual!.url}' : ''}''';
      }

      if (lowerMessage.contains('操作') ||
          lowerMessage.contains('使い方') ||
          lowerMessage.contains('設定')) {
        return '''${acDevice.name}の基本操作：

**【運転モード】**
- 冷房：夏の冷却（推奨設定温度 28℃）
- 暖房：冬の暖房（推奨設定温度 20℃）
- 除湿：湿度を下げる
- 送風：ファンのみ運転

**【リモコン操作】**
- 温度調整：上下ボタンで1℃ずつ
- 風量：自動/弱/中/強/ターボ
- タイマー：運転/停止時間を設定

**【省エネのコツ】**
- 自動運転モードがおすすめ
- カーテンを閉めて断熱効果アップ
- フィルターは定期的に清掃

${acDevice.manual?.url != null ? '\n詳細はマニュアルをご確認ください：${acDevice.manual!.url}' : ''}''';
      }
    }

    // メンテナンス関連
    if (lowerMessage.contains('メンテナンス') ||
        lowerMessage.contains('点検') ||
        lowerMessage.contains('お手入れ')) {
      final device = matchedDevice ?? _firstContextDevice;
      if (device == null) return _noDevicesResponse();
      final buffer = StringBuffer('${device.name}のメンテナンス情報：\n\n');
      if (device.maintenance?.lastMaintenance != null) {
        buffer.writeln('最終メンテナンス：${device.maintenance!.lastMaintenance}');
      }
      if (device.maintenance?.nextMaintenance != null) {
        buffer.writeln('次回予定：${device.maintenance!.nextMaintenance}');
      }
      buffer.writeln('\n定期的な点検で製品寿命を延ばすことができます。');
      if (device.manual?.url != null) {
        buffer.writeln('\n詳細はマニュアルをご確認ください：${device.manual!.url}');
      }
      return buffer.toString();
    }

    // 保証関連
    if (lowerMessage.contains('保証') || lowerMessage.contains('修理')) {
      final device = matchedDevice ?? _firstContextDevice;
      if (device == null) return _noDevicesResponse();
      final buffer = StringBuffer('${device.name}の保証情報：\n\n');
      if (device.warranty?.manufacturer != null) {
        final warranty = device.warranty!.manufacturer!;
        if (warranty.expired) {
          buffer.writeln('メーカー保証は**期限切れ**です。');
          buffer.writeln('修理の場合は有償修理となります。');
        } else {
          buffer.writeln('メーカー保証：${warranty.expiryDate}まで有効');
          buffer.writeln('保証期間内であれば無償修理の対象になる可能性があります。');
        }
      } else {
        buffer.writeln('保証情報が登録されていません。');
      }
      buffer.writeln('\n${device.manufacturer}のサポート窓口にお問い合わせください。');
      return buffer.toString();
    }

    // デフォルト応答
    if (matchedDevice != null) {
      return '''${matchedDevice.name}についてのご質問ですね。

以下のような質問にお答えできます：
- 「${matchedDevice.name}の操作方法を教えて」
- 「${matchedDevice.name}の電源がつかない」
- 「${matchedDevice.name}のメンテナンス方法は？」
- 「${matchedDevice.name}の保証はまだある？」

具体的な問題や知りたいことを教えてください。''';
    }

    return '''ご質問ありがとうございます。

登録されている ${_contextDevices.length} 台のデバイスについてお答えできます。

例えば：
- 「リビングのエアコンの型番を教えて」
- 「パソコンの電源がつかない」
- 「エアコンのフィルター掃除の方法は？」
- 「リコール対象の製品はある？」
- 「保証期間はまだ残ってる？」

デバイス名や問題内容を具体的に教えていただければ、より詳しくご案内できます。''';
  }

  /// セッションをリセット
  void resetSession() {
    _chatSession = null;
  }

  /// リソースを解放
  void dispose() {
    _chatSession = null;
    _contextDevices = [];
  }
}
