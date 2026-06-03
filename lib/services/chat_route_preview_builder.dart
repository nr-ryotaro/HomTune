import '../models/chat_route_preview.dart';
import '../models/device.dart';
import 'ai_routing_service.dart';
import 'config_service.dart';
import 'local_response_planner.dart';

/// チャット入力の送信前プレビュー生成
class ChatRoutePreviewBuilder {
  ChatRoutePreviewBuilder._();

  static ChatRoutePreview build({
    required String message,
    required List<Device> devices,
    required ConfigService config,
  }) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return ChatRoutePreview.empty;

    final localPlan = LocalResponsePlanner.plan(trimmed, devices);
    final decision = AiRoutingService.instance.decideChatRoute(
      trimmed,
      devices: devices,
      localPlan: localPlan,
      subscriptionTier: config.subscriptionTier,
    );

    final canUseRealAi =
        config.isUsingRealApi && config.hasGeminiApiKey;
    final willUseAi = decision.shouldUseAi &&
        canUseRealAi &&
        decision.estimatedCredits > 0;

    if (!willUseAi) {
      final topic = localTopicLabel(localPlan.topic);
      final detail = topic.isNotEmpty ? '（$topic）' : '';
      return ChatRoutePreview(
        modeLabel: 'ローカル',
        hintLine: '次の回答: ローカル$detail',
        willUseAi: false,
        estimatedCredits: 0,
        needsConfirmation: false,
        reason: decision.reason,
      );
    }

    final creditsText = '約${decision.estimatedCredits} cr';
    final confirmNote = decision.needsConfirmation ? '・確認あり' : '';
    return ChatRoutePreview(
      modeLabel: 'AI',
      hintLine: '次の回答: AI（$creditsText$confirmNote）',
      willUseAi: true,
      estimatedCredits: decision.estimatedCredits,
      needsConfirmation: decision.needsConfirmation,
      reason: decision.reason,
    );
  }
}
