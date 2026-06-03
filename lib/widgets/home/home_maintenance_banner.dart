import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../screens/maintenance_calendar_screen.dart';
import '../../services/maintenance_calendar_service.dart';

/// ホーム画面のメンテナンス予定バナー。
class HomeMaintenanceBanner extends StatelessWidget {
  const HomeMaintenanceBanner({
    super.key,
    required this.devices,
  });

  final List<Device> devices;

  @override
  Widget build(BuildContext context) {
    final overdue = MaintenanceCalendarService.getOverdueTasks(devices);
    final upcoming = MaintenanceCalendarService.getUpcomingTasks(devices);
    final totalCount = overdue.length + upcoming.length;

    if (totalCount == 0) return const SizedBox.shrink();

    final topTask = overdue.isNotEmpty ? overdue.first : upcoming.first;
    final isOverdue = overdue.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MaintenanceCalendarScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isOverdue ? Colors.orange.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOverdue ? Colors.orange.shade200 : Colors.blue.shade200,
            ),
          ),
          child: Row(
            children: [
              const Text('🧹', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOverdue
                          ? '$totalCount件のお手入れが期限を迎えています'
                          : '$totalCount件のお手入れが予定されています',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isOverdue
                            ? Colors.orange.shade800
                            : Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${topTask.device.name} の${topTask.task.name}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color:
                    isOverdue ? Colors.orange.shade400 : Colors.blue.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
