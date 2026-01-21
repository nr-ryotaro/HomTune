import 'package:flutter/material.dart';
import '../models/device.dart';

class ChatWidget extends StatefulWidget {
  final List<Device> devices;

  const ChatWidget({
    super.key,
    required this.devices,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // ユーザーメッセージを追加
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();

    // スクロールを最下部に
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // ダミーAI応答を生成（実際のLLM API呼び出しは将来実装）
    Future.delayed(const Duration(milliseconds: 800), () {
      final response = _generateDummyResponse(text);
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });

      // 応答後にスクロール
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  String _generateDummyResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    // 型番を聞く質問
    if (lowerMessage.contains('型番') || lowerMessage.contains('モデル')) {
      if (lowerMessage.contains('エアコン') || lowerMessage.contains('リビング')) {
        final acDevice = widget.devices.firstWhere(
          (d) => d.room == 'living-room' || d.category == 'エアコン' || d.name.toLowerCase().contains('エアコン'),
          orElse: () => widget.devices.firstWhere(
            (d) => d.category == 'エアコン',
            orElse: () => widget.devices.first,
          ),
        );
        return '''リビングのエアコンの型番は「${acDevice.modelNumber}」です。

メーカー：${acDevice.manufacturer}
製品名：${acDevice.name}

詳細情報やマニュアルはこちら：
${acDevice.manual?.url ?? 'https://www.daikin.co.jp/manual'}''';
      }
    }

    // 電源がつかない問題
    if (lowerMessage.contains('電源') && (lowerMessage.contains('つかない') || lowerMessage.contains('つか') || lowerMessage.contains('起動'))) {
      if (lowerMessage.contains('パソコン') || lowerMessage.contains('pc') || lowerMessage.contains('macbook') || lowerMessage.contains('mac')) {
        final pcDevice = widget.devices.firstWhere(
          (d) => d.category == 'PC' || d.name.toLowerCase().contains('macbook') || d.name.toLowerCase().contains('pc'),
          orElse: () => widget.devices.first,
        );
        return '''${pcDevice.name}の電源がつかない場合の対処法：

【基本的な確認】
1. 電源ケーブルが正しく接続されているか確認
2. コンセントに電源が供給されているか確認
3. バッテリーが完全に消耗していないか確認

【トラブルシューティング】
- 電源ボタンを10秒間長押し（強制リセット）
- 電源アダプターを一度外して再接続
- 別のコンセントで試す

【MacBookの場合】
- SMCリセット：Shift + Control + Option + 電源ボタンを同時に10秒間押す
- PRAMリセット：起動時にCommand + Option + P + Rを押し続ける

問題が解決しない場合は、公式サポートにご連絡ください：
${pcDevice.manual?.url ?? 'https://support.apple.com'}''';
      }
    }

    // 電球のサイズ
    if (lowerMessage.contains('電球') || lowerMessage.contains('ライト') || lowerMessage.contains('サイズ')) {
      return '''部屋のライトの電球サイズについて：

登録されているデバイス情報を確認しましたが、電球のサイズ情報が登録されていないようです。

一般的な電球サイズ：
- E26（一般的な口金サイズ）
- E17（小型の口金サイズ）
- E12（キャンドル型）

電球を取り外して、口金部分に記載されているサイズを確認してください。
（例：「E26」など）

電球を交換する際は、ワット数も確認してください。''';
    }

    // エアコン関連
    if (lowerMessage.contains('エアコン') || lowerMessage.contains('air')) {
      final acDevice = widget.devices.firstWhere(
        (d) => d.category == 'エアコン' || d.name.toLowerCase().contains('エアコン'),
        orElse: () => widget.devices.first,
      );

      if (lowerMessage.contains('操作') || lowerMessage.contains('使い方')) {
        return '''${acDevice.name}の操作方法について：

【基本的な操作】
1. リモコンの電源ボタンを押して起動
2. 温度設定ボタンで希望温度を設定（推奨：夏28℃、冬20℃）
3. 運転モードを選択（冷房/暖房/除湿/送風）

【リモコン操作】
- 温度調整：上下ボタンで1℃ずつ調整
- 風量調整：風量ボタンで5段階調整
- タイマー：タイマーボタンで運転時間を設定

【メンテナンス】
- フィルターは2週間に1回程度の清掃を推奨
- エアコン本体の清掃は年1回程度

詳細な操作手順は、公式マニュアルをご確認ください：
${acDevice.manual?.url ?? 'https://www.daikin.co.jp/manual'}''';
      }
    }

    // MacBook関連
    if (lowerMessage.contains('macbook') || lowerMessage.contains('mac')) {
      final macDevice = widget.devices.firstWhere(
        (d) => d.name.toLowerCase().contains('macbook'),
        orElse: () => widget.devices.first,
      );

      if (lowerMessage.contains('操作') || lowerMessage.contains('使い方')) {
        return '''${macDevice.name}の基本的な操作方法：

【起動・シャットダウン】
- 起動：電源ボタンを長押し
- シャットダウン：Appleメニュー > システム終了

【トラブルシューティング】
- フリーズ時：Command + Option + Esc で強制終了
- 再起動：電源ボタンを10秒間長押し

【メンテナンス】
- 定期的なmacOSアップデートを推奨
- ストレージの空き容量を確認（10%以上推奨）

詳細は公式サポートページをご確認ください：
${macDevice.manual?.url ?? 'https://support.apple.com'}''';
      }
    }

    // デフォルト応答
    return '''ご質問ありがとうございます。

登録されているデバイスに関する情報をお答えできます。

例えば：
- 「リビングのエアコンの型番を教えて」
- 「使っているパソコンの電源がつかない」
- 「部屋のライトの電球のサイズなんだったっけ」

具体的なデバイス名や問題内容を教えていただければ、より詳しくご案内できます。''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE5E5E5),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 質問テキスト
          if (_messages.isEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: const Text(
                '今日はどうしましたか？',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF333333),
                ),
              ),
            ),

          // メッセージリスト
          if (_messages.isNotEmpty)
            Flexible(
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMessageBubble(_messages[index]),
                  );
                },
              ),
            ),

          // 入力欄
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFE5E5E5),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _getPlaceholderText(),
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF999999),
                          fontWeight: FontWeight.w300,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E5E5),
                            width: 0.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E5E5),
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFF3b82f6),
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                      ),
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? Colors.grey[300]
                          : const Color(0xFF3b82f6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPlaceholderText() {
    final placeholders = [
      'リビングのエアコンの型番を教えて',
      '使っているパソコンの電源がつかない',
      '部屋のライトの電球のサイズなんだったっけ',
    ];
    // 現在の時刻に基づいてプレースホルダーをローテーション
    final index = DateTime.now().millisecond % placeholders.length;
    return placeholders[index];
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Row(
      mainAxisAlignment:
          message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!message.isUser) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF3b82f6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 16,
              color: Color(0xFF3b82f6),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: message.isUser
                  ? const Color(0xFF3b82f6)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                color: message.isUser ? Colors.white : const Color(0xFF333333),
                height: 1.5,
              ),
            ),
          ),
        ),
        if (message.isUser) ...[
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 16,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ],
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
