enum SourceType {
  internal,
  officialApi,
  licensedProvider,
  userProvided,
}

enum ReviewState {
  approved,
  pending,
  blocked,
}

class SourceAttribution {
  final SourceType sourceType;
  final String sourceUrl;
  final String publisher;
  final String licenseType;
  final DateTime capturedAt;
  final double confidence;
  final ReviewState reviewState;

  const SourceAttribution({
    required this.sourceType,
    required this.sourceUrl,
    required this.publisher,
    required this.licenseType,
    required this.capturedAt,
    required this.confidence,
    required this.reviewState,
  });

  factory SourceAttribution.fromJson(Map<String, dynamic> json) {
    SourceType parseSourceType(String? raw) {
      return SourceType.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => SourceType.internal,
      );
    }

    ReviewState parseReviewState(String? raw) {
      return ReviewState.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => ReviewState.pending,
      );
    }

    return SourceAttribution(
      sourceType: parseSourceType(json['sourceType']?.toString()),
      sourceUrl: json['sourceUrl']?.toString() ?? '',
      publisher: json['publisher']?.toString() ?? '',
      licenseType: json['licenseType']?.toString() ?? '',
      capturedAt:
          DateTime.tryParse(json['capturedAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      reviewState: parseReviewState(json['reviewState']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceType': sourceType.name,
      'sourceUrl': sourceUrl,
      'publisher': publisher,
      'licenseType': licenseType,
      'capturedAt': capturedAt.toIso8601String(),
      'confidence': confidence,
      'reviewState': reviewState.name,
    };
  }
}
