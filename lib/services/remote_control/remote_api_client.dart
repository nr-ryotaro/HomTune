import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/remote_api_config.dart';
import '../../models/ai_usage_policy.dart';
import '../../models/remote_appliance.dart';
import '../config_service.dart';

class RemoteApiException implements Exception {
  final String message;
  final int? statusCode;

  const RemoteApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class IntegrationStatus {
  final bool linked;
  final String provider;
  final int remainingMonthlyQuota;
  final int monthlyLimit;

  const IntegrationStatus({
    required this.linked,
    required this.provider,
    required this.remainingMonthlyQuota,
    required this.monthlyLimit,
  });

  factory IntegrationStatus.fromJson(Map<String, dynamic> json) {
    return IntegrationStatus(
      linked: json['linked'] == true,
      provider: json['provider']?.toString() ?? '',
      remainingMonthlyQuota:
          (json['remainingMonthlyQuota'] as num?)?.toInt() ?? 0,
      monthlyLimit: (json['monthlyLimit'] as num?)?.toInt() ?? 300,
    );
  }
}

class RemoteApiClient {
  RemoteApiClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Map<String, String> _headers(ConfigService config) => {
        'Content-Type': 'application/json',
        'X-HomTune-User-Id': RemoteApiConfig.devUserId,
        'X-HomTune-Pro':
            (config.subscriptionTier == SubscriptionTier.pro).toString(),
      };

  Future<Map<String, dynamic>> _request(
    ConfigService config,
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${RemoteApiConfig.baseUrl}$path');
    late http.Response res;
    switch (method) {
      case 'GET':
        res = await _http.get(uri, headers: _headers(config));
        break;
      case 'POST':
        res = await _http.post(
          uri,
          headers: _headers(config),
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        res = await _http.delete(uri, headers: _headers(config));
        break;
      default:
        throw RemoteApiException('Unsupported method: $method');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw RemoteApiException(
        'API応答の解析に失敗しました (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw RemoteApiException(
        decoded['message']?.toString() ?? 'APIエラー (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return decoded;
  }

  Future<IntegrationStatus> getRemoStatus(ConfigService config) async {
    final json = await _request(config, 'GET', '/v1/integrations/remo/status');
    return IntegrationStatus.fromJson(json);
  }

  Future<IntegrationStatus> getSwitchBotStatus(ConfigService config) async {
    final json =
        await _request(config, 'GET', '/v1/integrations/switchbot/status');
    return IntegrationStatus.fromJson(json);
  }

  Future<void> linkRemo(ConfigService config, String token) async {
    await _request(
      config,
      'POST',
      '/v1/integrations/remo/link',
      body: {'token': token},
    );
  }

  Future<void> unlinkRemo(ConfigService config) async {
    await _request(config, 'DELETE', '/v1/integrations/remo/link');
  }

  Future<void> linkSwitchBot(
    ConfigService config, {
    required String token,
    required String secret,
  }) async {
    await _request(
      config,
      'POST',
      '/v1/integrations/switchbot/link',
      body: {'token': token, 'secret': secret},
    );
  }

  Future<void> unlinkSwitchBot(ConfigService config) async {
    await _request(config, 'DELETE', '/v1/integrations/switchbot/link');
  }

  Future<List<RemoteAppliance>> listRemoAppliances(
    ConfigService config,
  ) async {
    final json =
        await _request(config, 'GET', '/v1/integrations/remo/appliances');
    final list = json['appliances'] as List<dynamic>? ?? [];
    return list
        .map((e) => RemoteAppliance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RemoteAppliance>> listSwitchBotAppliances(
    ConfigService config,
  ) async {
    final json =
        await _request(config, 'GET', '/v1/integrations/switchbot/appliances');
    final list = json['appliances'] as List<dynamic>? ?? [];
    return list
        .map((e) => RemoteAppliance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RemoteControlResult> sendCommand(
    ConfigService config,
    RemoteCommand command,
  ) async {
    final json = await _request(
      config,
      'POST',
      '/v1/remote/command',
      body: command.toJson(),
    );
    return RemoteControlResult.fromJson(json);
  }

  void dispose() => _http.close();
}
