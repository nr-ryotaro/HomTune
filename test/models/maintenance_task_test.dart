import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/maintenance_task.dart';

void main() {
  group('MaintenanceTask.isDueSoon', () {
    test('includes task due exactly 7 days from now', () {
      final now = DateTime.now();
      final dueInSevenDays = now.add(const Duration(days: 7));

      final task = MaintenanceTask(
        taskId: 'test',
        deviceId: 'dev1',
        name: 'Filter',
        intervalDays: 7,
        priority: 'high',
        nextDue: dueInSevenDays,
      );

      expect(task.isDueSoon, isTrue);
    });

    test('excludes overdue tasks', () {
      final task = MaintenanceTask(
        taskId: 'test',
        deviceId: 'dev1',
        name: 'Filter',
        intervalDays: 7,
        priority: 'high',
        nextDue: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(task.isDueSoon, isFalse);
      expect(task.isOverdue, isTrue);
    });
  });
}
