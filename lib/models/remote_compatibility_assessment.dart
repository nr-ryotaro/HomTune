import 'device_remote_link.dart';

enum RemoteCompatibilitySource {
  none,
  modelPattern,
  archetype,
  category,
}

enum RemoteCompatibilityConfidence {
  high,
  medium,
  low,
}

class RemoteCompatibilityAssessment {
  final bool isEligible;
  final RemoteCapabilityProfile? profile;
  final String? label;
  final List<RemoteProvider> suggestedProviders;
  final RemoteCompatibilitySource source;
  final RemoteCompatibilityConfidence confidence;
  final String? userMessage;

  const RemoteCompatibilityAssessment({
    required this.isEligible,
    this.profile,
    this.label,
    this.suggestedProviders = const [],
    this.source = RemoteCompatibilitySource.none,
    this.confidence = RemoteCompatibilityConfidence.low,
    this.userMessage,
  });

  static const notEligible = RemoteCompatibilityAssessment(
    isEligible: false,
    source: RemoteCompatibilitySource.none,
    confidence: RemoteCompatibilityConfidence.low,
  );

  bool get shouldPromptOnRegistration => isEligible;

  String get registrationHint {
    if (!isEligible) return '';
    final name = label ?? 'この家電';
    return '$nameはスマートリモコン（Remo / SwitchBot）で操作できる可能性があります';
  }
}
