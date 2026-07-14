import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/remote_api_config.dart';
import '../models/ai_usage_policy.dart';
import 'config_service.dart';

class AiContentMessage {
  final String role; // user | model
  final String text;

  const AiContentMessage({required this.role, required this.text});

  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}

class AiGenerateUsage {
  final int creditsCharged;
  final int remainingCredits;
  final int creditLimit;
  final double estimatedCostUsd;

  const AiGenerateUsage({
    required this.creditsCharged,
    required this.remainingCredits,
    required this.creditLimit,
    required this.estimatedCostUsd,
  });

  factory AiGenerateUsage.fromJson(Map<String, dynamic>? json) {
    return AiGenerateUsage(
      creditsCharged: (json?['creditsCharged'] as num?)?.toInt() ?? 0,
      remainingCredits: (json?['remainingCredits'] as num?)?.toInt() ?? 0,
      creditLimit: (json?['creditLimit'] as num?)?.toInt() ?? 0,
      estimatedCostUsd: (json?['estimatedCostUsd'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AiGenerateResult {
  final String text;
  final String modelId;
  final AiFeature feature;
  final bool mocked;
  final AiGenerateUsage usage;

  const AiGenerateResult({
    required this.text,
    required this.modelId,
    required this.feature,
    required this.mocked,
    required this.usage,
  });
}

class AiApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  final bool retryable;
  final AiGenerateUsage? usage;

  const AiApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.retryable = false,
    this.usage,
  });

  @override
  String toString() => message;
}

/// HomTune `POST /v1/ai/generate` クライアント（Phase 0）
class AiApiClient {
  AiApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  static String featureName(AiFeature feature) {
    switch (feature) {
      case AiFeature.chat:
        return 'chat';
      case AiFeature.scanner:
        return 'scanner';
      case AiFeature.roomImage:
        return 'roomImage';
      case AiFeature.maintenance:
        return 'maintenance';
      case AiFeature.marketValuation:
        return 'marketValuation';
    }
  }

  static AiFeature? featureFromName(String name) {
    switch (name) {
      case 'chat':
        return AiFeature.chat;
      case 'scanner':
        return AiFeature.scanner;
      case 'roomImage':
        return AiFeature.roomImage;
      case 'maintenance':
        return AiFeature.maintenance;
      case 'marketValuation':
        return AiFeature.marketValuation;
      default:
        return null;
    }
  }

  Future<AiGenerateResult> generate({
    required ConfigService config,
    required AiFeature feature,
    required List<AiContentMessage> contents,
    String? systemInstruction,
    String responseFormat = 'text',
    int? requestedCredits,
    String? clientRequestId,
    String? model,
  }) async {
    return generateRaw(
      config: config,
      feature: featureName(feature),
      contents: contents,
      systemInstruction: systemInstruction,
      responseFormat: responseFormat,
      requestedCredits: requestedCredits,
      clientRequestId: clientRequestId,
      model: model ?? config.geminiModelFor(feature),
      parsedFeature: feature,
    );
  }

  /// connectionTest など、AiFeature に無い feature 文字列用
  Future<AiGenerateResult> generateRaw({
    required ConfigService config,
    required String feature,
    required List<AiContentMessage> contents,
    String? systemInstruction,
    String responseFormat = 'text',
    int? requestedCredits,
    String? clientRequestId,
    String? model,
    AiFeature? parsedFeature,
  }) async {
    final uri = Uri.parse('${RemoteApiConfig.baseUrl}/v1/ai/generate');
    final payload = <String, dynamic>{
      'feature': feature,
      'model': model ?? ConfigService.releaseCostOptimizedModel,
      'contents': contents.map((e) => e.toJson()).toList(),
      'responseFormat': responseFormat,
      if (systemInstruction != null && systemInstruction.isNotEmpty)
        'systemInstruction': systemInstruction,
      if (requestedCredits != null) 'requestedCredits': requestedCredits,
      if (clientRequestId != null) 'clientRequestId': clientRequestId,
    };

    late http.Response res;
    try {
      res = await _http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-HomTune-User-Id': RemoteApiConfig.devUserId,
          'X-HomTune-Pro':
              (config.subscriptionTier == SubscriptionTier.pro).toString(),
        },
        body: jsonEncode(payload),
      );
    } catch (e) {
      throw AiApiException(
        code: 'network_error',
        message: 'AIプロキシへ接続できません: $e',
        retryable: true,
      );
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw AiApiException(
        code: 'bad_response',
        message: 'AIプロキシ応答の解析に失敗しました (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }

    final usage = AiGenerateUsage.fromJson(
      decoded['usage'] is Map
          ? (decoded['usage'] as Map).cast<String, dynamic>()
          : null,
    );

    if (res.statusCode < 200 ||
        res.statusCode >= 300 ||
        decoded['ok'] != true) {
      final err = decoded['error'];
      final errMap = err is Map ? err.cast<String, dynamic>() : null;
      throw AiApiException(
        code: errMap?['code']?.toString() ?? 'upstream_error',
        message: errMap?['message']?.toString() ??
            decoded['message']?.toString() ??
            'AIプロキシエラー (${res.statusCode})',
        statusCode: res.statusCode,
        retryable: errMap?['retryable'] == true || res.statusCode >= 500,
        usage: usage,
      );
    }

    return AiGenerateResult(
      text: decoded['text']?.toString() ?? '',
      modelId: decoded['modelId']?.toString() ??
          ConfigService.releaseCostOptimizedModel,
      feature: parsedFeature ??
          featureFromName(decoded['feature']?.toString() ?? feature) ??
          AiFeature.chat,
      mocked: decoded['mocked'] == true,
      usage: usage,
    );
  }

  void dispose() => _http.close();
}
