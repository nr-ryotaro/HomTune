import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static const String _eventsKey = 'analytics_events_v1';

  static Future<void> logEvent({
    required String event,
    required Map<String, Object?> properties,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_eventsKey) ?? <String>[];
    final payload = jsonEncode({
      'at': DateTime.now().toIso8601String(),
      'event': event,
      'properties': properties,
    });
    list.add(payload);
    if (list.length > 1000) {
      list.removeRange(0, list.length - 1000);
    }
    await prefs.setStringList(_eventsKey, list);
  }
}
