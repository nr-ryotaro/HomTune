import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('category-defaults has no long shortMethod text', () async {
    final jsonStr = await rootBundle
        .loadString('assets/data/category-defaults.json');
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    final tasks = json['maintenanceTasks'] as Map<String, dynamic>;

    for (final entry in tasks.entries) {
      final list = entry.value as List<dynamic>;
      for (final raw in list) {
        final task = raw as Map<String, dynamic>;
        final short = task['shortMethod']?.toString() ?? '';
        expect(
          short.length,
          lessThan(80),
          reason: '${entry.key}/${task['taskId']} has long shortMethod',
        );
        expect(task['sourceAttribution'], isNotNull);
        final attr = task['sourceAttribution'] as Map<String, dynamic>;
        expect(attr['reviewState'], 'approved');
      }
    }
  });
}
