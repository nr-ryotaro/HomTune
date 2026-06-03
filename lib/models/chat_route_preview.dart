import 'local_response_plan.dart';

/// 送信前に表示するルート予告
class ChatRoutePreview {
  final String modeLabel;
  final String hintLine;
  final bool willUseAi;
  final int estimatedCredits;
  final bool needsConfirmation;
  final String reason;

  const ChatRoutePreview({
    required this.modeLabel,
    required this.hintLine,
    required this.willUseAi,
    required this.estimatedCredits,
    required this.needsConfirmation,
    required this.reason,
  });

  static const ChatRoutePreview empty = ChatRoutePreview(
    modeLabel: 'ローカル',
    hintLine: '',
    willUseAi: false,
    estimatedCredits: 0,
    needsConfirmation: false,
    reason: 'empty_message',
  );
}

/// プレビュー用のトピック表示名
String localTopicLabel(LocalResponseTopic topic) {
  switch (topic) {
    case LocalResponseTopic.recall:
      return 'リコール';
    case LocalResponseTopic.modelNumber:
      return '型番';
    case LocalResponseTopic.power:
      return '電源トラブル';
    case LocalResponseTopic.acFilter:
      return 'エアコンフィルター';
    case LocalResponseTopic.acUsage:
      return 'エアコン操作';
    case LocalResponseTopic.maintenance:
      return 'メンテナンス';
    case LocalResponseTopic.warranty:
      return '保証';
    case LocalResponseTopic.deviceCount:
      return '登録台数';
    case LocalResponseTopic.deviceHint:
      return '登録家電';
    case LocalResponseTopic.genericCatalog:
      return 'FAQ';
    case LocalResponseTopic.noDevices:
      return '未登録';
    case LocalResponseTopic.none:
      return '';
  }
}
