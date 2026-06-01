import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/source_attribution.dart';

class ComplianceService {
  static const _auditKey = 'compliance_audit_logs';
  static const Set<String> _allowedDomains = {
    'daikin.co.jp',
    'panasonic.jp',
    'mitsubishi-electric.co.jp',
    'sharp.co.jp',
    'sony.com',
    'apple.com',
    'lg.com',
    'samsung.com',
    'hitachi.co.jp',
    'toshiba-lifestyle.com',
    'toshiba-consumer.co.jp',
  };

  static bool isAllowedSourceUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return false;
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return false;
    if (uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    return _allowedDomains.any((domain) => host == domain || host.endsWith('.$domain'));
  }

  static bool canDistribute(SourceAttribution attribution) {
    if (attribution.reviewState != ReviewState.approved) return false;
    if (attribution.sourceType == SourceType.internal) return true;
    return isAllowedSourceUrl(attribution.sourceUrl);
  }

  static Future<void> logEvent({
    required String action,
    required String targetId,
    required String result,
    String? reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_auditKey) ?? <String>[];
    final payload = jsonEncode({
      'at': DateTime.now().toIso8601String(),
      'action': action,
      'targetId': targetId,
      'result': result,
      'reason': reason ?? '',
    });
    list.add(payload);
    if (list.length > 500) {
      list.removeRange(0, list.length - 500);
    }
    await prefs.setStringList(_auditKey, list);
  }
}
