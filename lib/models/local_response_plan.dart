import 'device.dart';

/// ローカルテンプレで回答可能なトピック
enum LocalResponseTopic {
  none,
  noDevices,
  recall,
  modelNumber,
  power,
  acFilter,
  acUsage,
  maintenance,
  warranty,
  deviceCount,
  deviceHint,
  genericCatalog,
}

/// ローカル回答の実行計画（ルーティングと ChatService で共有）
class LocalResponsePlan {
  final bool canAnswer;
  final double confidence;
  final LocalResponseTopic topic;
  final Device? matchedDevice;
  final bool hasRegisteredDeviceMatch;

  const LocalResponsePlan({
    required this.canAnswer,
    required this.confidence,
    required this.topic,
    this.matchedDevice,
    this.hasRegisteredDeviceMatch = false,
  });

  static const LocalResponsePlan empty = LocalResponsePlan(
    canAnswer: false,
    confidence: 0,
    topic: LocalResponseTopic.none,
  );
}
