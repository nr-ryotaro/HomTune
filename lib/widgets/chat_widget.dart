import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_route_preview.dart';
import '../models/device.dart';
import '../widgets/ads/pro_upgrade_dialog.dart';
import '../widgets/ai/credit_exhaustion_dialog.dart';
import '../models/ai_usage_policy.dart';
import '../services/config_service.dart';
import '../services/ai_routing_service.dart';
import '../services/ai_usage_service.dart';
import '../services/remote_control/remote_command_intent_parser.dart';
import '../services/remote_control/remote_control_service.dart';
import '../services/chat_route_preview_builder.dart';
import '../services/chat_service.dart';

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
  ChatService? _chatService;
  bool _isChatReady = false;
  int _deviceCount = 0;
  String _responseModeLabel = 'ローカル';
  AiUsageSnapshot? _usageSnapshot;
  ChatRoutePreview _routePreview = ChatRoutePreview.empty;
  Timer? _previewDebounce;

  @override
  void initState() {
    super.initState();
    _deviceCount = widget.devices.length;
    _messageController.addListener(_onInputChanged);
    _initChatService();
  }

  Future<void> _initChatService() async {
    final configService = Provider.of<ConfigService>(context, listen: false);
    final service = ChatService(configService);
    AiUsageSnapshot? snapshot;
    try {
      await service.initializeWithDevices(widget.devices);
      snapshot = await AiUsageService.instance.getSnapshot(configService);
    } catch (e) {
      // 初期化失敗時もチャット自体は使えるようにする（ローカル専用）
      print('ChatWidget init error: $e');
    }
    if (!mounted) {
      service.dispose();
      return;
    }
    setState(() {
      _chatService = service;
      _isChatReady = true;
      _usageSnapshot = snapshot;
      _responseModeLabel = 'ローカル';
    });
  }

  Future<void> _refreshDeviceContext(List<Device> devices) async {
    final service = _chatService;
    if (service == null || !_isChatReady) return;
    try {
      await service.initializeWithDevices(devices);
    } catch (e) {
      print('ChatWidget refresh context error: $e');
    }
  }

  @override
  void didUpdateWidget(covariant ChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.devices.length != _deviceCount) {
      _deviceCount = widget.devices.length;
      _refreshDeviceContext(widget.devices);
    }
  }

  void _onInputChanged() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final config = Provider.of<ConfigService>(context, listen: false);
      setState(() {
        _routePreview = ChatRoutePreviewBuilder.build(
          message: _messageController.text,
          devices: widget.devices,
          config: config,
        );
      });
    });
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _messageController.removeListener(_onInputChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _chatService?.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading || !_isChatReady || _chatService == null) {
      return;
    }

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    setState(() => _routePreview = ChatRoutePreview.empty);
    _scrollToBottom();

    try {
      final configService = Provider.of<ConfigService>(context, listen: false);

      if (RemoteCommandIntentParser.looksLikeRemoteCommand(text)) {
        final remoteService =
            Provider.of<RemoteControlService>(context, listen: false);
        final remoteReply = await remoteService.executeChatIntent(
          configService,
          text,
          widget.devices,
        );
        if (remoteReply != null && mounted) {
          final isProRemoteUpsell = remoteReply.contains('Pro プラン');
          setState(() {
            _messages.add(ChatMessage(
              text: remoteReply,
              isUser: false,
              timestamp: DateTime.now(),
              responseMode: 'リモコン',
              routeReason: '登録家電への操作',
            ));
            _responseModeLabel = 'リモコン';
            _isLoading = false;
          });
          if (isProRemoteUpsell) {
            await showProUpgradeDialog(
              context,
              upsellContext: ProUpsellContext.remoteControl,
            );
          }
          _scrollToBottom();
          return;
        }
      }

      // APIキー/モデル/実APIトグルの変更を常に反映するため、
      // 送信直前にセッションを再初期化する。
      await _chatService!.initializeWithDevices(widget.devices);
      final localPlan = _chatService!.planLocalResponse(text);
      final decision = AiRoutingService.instance.decideChatRoute(
        text,
        devices: widget.devices,
        localPlan: localPlan,
        subscriptionTier: configService.subscriptionTier,
      );
      final routeReason = decision.reason;
      final requestedCredits = decision.routeType == AiRouteType.localOnly
          ? 0
          : decision.estimatedCredits;

      final canUseRealAi = configService.canUseCloudInference;
      final shouldTryAi =
          decision.shouldUseAi && canUseRealAi && requestedCredits > 0;
      if (decision.shouldUseAi &&
          configService.isCloudAiEnabled &&
          !configService.canUseCloudInference &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('接続情報が未設定のためローカル回答に切替しました。')),
        );
      }
      if (shouldTryAi && decision.needsConfirmation) {
        final proceed = await _confirmAiExecution(requestedCredits);
        if (proceed != true) {
          final localResponse = _chatService!.sendLocalMessage(text);
          if (!mounted) return;
          setState(() {
            _messages.add(ChatMessage(
              text: localResponse,
              isUser: false,
              timestamp: DateTime.now(),
              responseMode: 'ローカル',
              routeReason: routeReason,
            ));
            _responseModeLabel = 'ローカル';
            _isLoading = false;
          });
          _scrollToBottom();
          return;
        }
      }

      late final String response;
      late final String responseMode;
      if (shouldTryAi) {
        final budgetCheck = await AiUsageService.instance.canRunFeature(
          configService,
          feature: AiFeature.chat,
          requestedCredits: requestedCredits,
        );
        if (budgetCheck.allowed) {
          response = await _chatService!.sendMessage(text);
          await AiUsageService.instance.recordUsage(
            configService,
            feature: AiFeature.chat,
            consumedCredits: requestedCredits,
            route: decision.routeType.name,
          );
          _usageSnapshot = await AiUsageService.instance.getSnapshot(configService);
          _responseModeLabel = 'AI';
          responseMode = 'AI';
        } else {
          response = _chatService!.sendLocalMessage(text);
          _responseModeLabel = 'ローカル';
          responseMode = 'ローカル';
          if (mounted && budgetCheck.reason.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${budgetCheck.reason}（ローカル回答に切替）'),
                action: SnackBarAction(
                  label: configService.subscriptionTier == SubscriptionTier.free
                      ? 'Proを見る'
                      : 'クレジット追加',
                  onPressed: () => showCreditExhaustionDialog(
                    context,
                    config: configService,
                    check: budgetCheck,
                    upsellContext: ProUpsellContext.general,
                  ),
                ),
              ),
            );
          }
          _usageSnapshot = budgetCheck.snapshot;
        }
      } else {
        response = _chatService!.sendLocalMessage(text);
        _responseModeLabel = 'ローカル';
        responseMode = 'ローカル';
        _usageSnapshot = await AiUsageService.instance.getSnapshot(configService);
      }

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
            responseMode: responseMode,
            routeReason: routeReason,
          ));
          _routePreview = ChatRoutePreview.empty;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'エラーが発生しました。もう一度お試しください。',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<bool?> _confirmAiExecution(int credits) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('AI回答を使用しますか？'),
          content: Text(
            'この質問はAI回答が有効です。約$creditsクレジット消費します。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ローカル回答'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('AIで回答'),
            ),
          ],
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
        children: [
          if (_messages.isEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text(
                _isChatReady ? '今日はどうしましたか？' : 'チャットを準備しています…',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF333333),
                ),
              ),
            ),

          if (_messages.isNotEmpty)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMessageBubble(_messages[index]),
                  );
                },
              ),
            ),

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
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _responseModeLabel == 'AI'
                              ? const Color(0xFFDBEAFE)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '回答モード: $_responseModeLabel',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'AI残量: ${_usageSnapshot?.remainingCredits ?? '--'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                  if (_routePreview.hintLine.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _routePreview.hintLine,
                        style: TextStyle(
                          fontSize: 11,
                          color: _routePreview.willUseAi
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          enabled: _isChatReady,
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
                          color: _isLoading || !_isChatReady
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                          onPressed:
                              _isLoading || !_isChatReady ? null : _sendMessage,
                        ),
                      ),
                    ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        message.isUser ? Colors.white : const Color(0xFF333333),
                    height: 1.5,
                  ),
                ),
                if (!message.isUser &&
                    message.responseMode != null &&
                    message.responseMode!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    kDebugMode && message.routeReason != null
                        ? '${message.responseMode} · ${message.routeReason}'
                        : message.responseMode!,
                    style: TextStyle(
                      fontSize: 10,
                      color: message.isUser
                          ? Colors.white70
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
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
  final String? responseMode;
  final String? routeReason;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.responseMode,
    this.routeReason,
  });
}
