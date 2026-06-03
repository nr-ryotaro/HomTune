import '../models/device.dart';
import '../models/local_response_plan.dart';
import 'device_query_matcher.dart';

/// ローカルテンプレで回答可能かを判定（ChatService とルータで共有）
class LocalResponsePlanner {
  LocalResponsePlanner._();

  static LocalResponsePlan plan(String message, List<Device> devices) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return LocalResponsePlan.empty;

    if (devices.isEmpty) {
      return const LocalResponsePlan(
        canAnswer: true,
        confidence: 1,
        topic: LocalResponseTopic.noDevices,
      );
    }

    final lower = trimmed.toLowerCase();
    final matched = DeviceQueryMatcher.findRelevant(trimmed, devices);
    final hasMatch = DeviceQueryMatcher.hasDeviceMatch(trimmed, devices);

    if (_containsRecall(lower)) {
      return LocalResponsePlan(
        canAnswer: true,
        confidence: 0.95,
        topic: LocalResponseTopic.recall,
        matchedDevice: matched,
        hasRegisteredDeviceMatch: hasMatch,
      );
    }

    if (lower.contains('何台') ||
        lower.contains('何個') ||
        (lower.contains('登録') &&
            (lower.contains('何') || lower.contains('一覧')))) {
      return LocalResponsePlan(
        canAnswer: true,
        confidence: 0.95,
        topic: LocalResponseTopic.deviceCount,
        matchedDevice: matched,
        hasRegisteredDeviceMatch: hasMatch,
      );
    }

    if (lower.contains('型番') || lower.contains('モデル')) {
      final confidence = matched != null ? 0.9 : 0.35;
      return LocalResponsePlan(
        canAnswer: matched != null,
        confidence: confidence,
        topic: LocalResponseTopic.modelNumber,
        matchedDevice: matched,
        hasRegisteredDeviceMatch: hasMatch,
      );
    }

    if (lower.contains('電源') &&
        (lower.contains('つかない') ||
            lower.contains('起動') ||
            lower.contains('入らない'))) {
      return LocalResponsePlan(
        canAnswer: true,
        confidence: matched != null ? 0.88 : 0.75,
        topic: LocalResponseTopic.power,
        matchedDevice: matched,
        hasRegisteredDeviceMatch: hasMatch,
      );
    }

    if (_isAcContext(lower)) {
      final ac = DeviceQueryMatcher.findAirConditioner(devices) ?? matched;
      if (lower.contains('フィルター') ||
          lower.contains('掃除') ||
          lower.contains('クリーニング')) {
        return LocalResponsePlan(
          canAnswer: ac != null,
          confidence: ac != null ? 0.88 : 0.4,
          topic: LocalResponseTopic.acFilter,
          matchedDevice: ac,
          hasRegisteredDeviceMatch: hasMatch,
        );
      }
      if (lower.contains('操作') ||
          lower.contains('使い方') ||
          lower.contains('設定')) {
        return LocalResponsePlan(
          canAnswer: ac != null,
          confidence: ac != null ? 0.85 : 0.4,
          topic: LocalResponseTopic.acUsage,
          matchedDevice: ac,
          hasRegisteredDeviceMatch: hasMatch,
        );
      }
    }

    if (lower.contains('メンテナンス') ||
        lower.contains('点検') ||
        lower.contains('お手入れ')) {
      return LocalResponsePlan(
        canAnswer: true,
        confidence: 0.82,
        topic: LocalResponseTopic.maintenance,
        matchedDevice: matched,
        hasRegisteredDeviceMatch: hasMatch,
      );
    }

    if (lower.contains('保証') || lower.contains('修理')) {
      return LocalResponsePlan(
        canAnswer: true,
        confidence: 0.82,
        topic: LocalResponseTopic.warranty,
        matchedDevice: matched,
        hasRegisteredDeviceMatch: hasMatch,
      );
    }

    if (matched != null &&
        (lower.contains('使い方') ||
            lower.contains('どう') ||
            lower.contains('教えて'))) {
      return LocalResponsePlan(
        canAnswer: true,
        confidence: 0.55,
        topic: LocalResponseTopic.deviceHint,
        matchedDevice: matched,
        hasRegisteredDeviceMatch: true,
      );
    }

    if (matched != null) {
      return LocalResponsePlan(
        canAnswer: true,
        confidence: 0.5,
        topic: LocalResponseTopic.deviceHint,
        matchedDevice: matched,
        hasRegisteredDeviceMatch: true,
      );
    }

    if (_isCatalogQuestion(lower)) {
      return const LocalResponsePlan(
        canAnswer: true,
        confidence: 0.55,
        topic: LocalResponseTopic.genericCatalog,
      );
    }

    return LocalResponsePlan(
      canAnswer: false,
      confidence: 0.2,
      topic: LocalResponseTopic.none,
      hasRegisteredDeviceMatch: hasMatch,
    );
  }

  static bool _containsRecall(String lower) =>
      lower.contains('リコール') ||
      lower.contains('安全') ||
      lower.contains('危険');

  static bool _isAcContext(String lower) =>
      lower.contains('エアコン') ||
      lower.contains('冷房') ||
      lower.contains('暖房');

  static bool _isCatalogQuestion(String lower) =>
      lower.contains('例') ||
      lower.contains('できる') ||
      lower.contains('質問');
}
