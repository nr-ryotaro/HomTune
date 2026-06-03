class Maintenance {
  final String? lastMaintenance;
  final String? nextMaintenance;
  final int? maintenanceInterval;
  final List<Alert> alerts;
  final List<MaintenanceHistory> history;

  Maintenance({
    this.lastMaintenance,
    this.nextMaintenance,
    this.maintenanceInterval,
    required this.alerts,
    required this.history,
  });

  factory Maintenance.fromJson(Map<String, dynamic> json) {
    try {
      return Maintenance(
        lastMaintenance: json['lastMaintenance']?.toString(),
        nextMaintenance: json['nextMaintenance']?.toString(),
        maintenanceInterval: (json['maintenanceInterval'] as num?)?.toInt(),
        alerts: (json['alerts'] as List<dynamic>?)
                ?.map((e) {
                  try {
                    return Alert.fromJson(e as Map<String, dynamic>);
                  } catch (e) {
                    print('Error parsing Alert: $e');
                    return null;
                  }
                })
                .whereType<Alert>()
                .toList() ??
            [],
        history: (json['history'] as List<dynamic>?)
                ?.map((e) {
                  try {
                    return MaintenanceHistory.fromJson(
                        e as Map<String, dynamic>);
                  } catch (e) {
                    print('Error parsing MaintenanceHistory: $e');
                    return null;
                  }
                })
                .whereType<MaintenanceHistory>()
                .toList() ??
            [],
      );
    } catch (e) {
      print('Error parsing Maintenance: $e');
      // エラー時は空のMaintenanceを返す
      return Maintenance(
        alerts: [],
        history: [],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'lastMaintenance': lastMaintenance,
      'nextMaintenance': nextMaintenance,
      'maintenanceInterval': maintenanceInterval,
      'alerts': alerts.map((e) => e.toJson()).toList(),
      'history': history.map((e) => e.toJson()).toList(),
    };
  }
}

class Alert {
  final String type;
  final String message;
  final String priority;
  final String createdAt;

  Alert({
    required this.type,
    required this.message,
    required this.priority,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    try {
      return Alert(
        type: json['type']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        priority: json['priority']?.toString() ?? 'low',
        createdAt: json['createdAt']?.toString() ?? '',
      );
    } catch (e) {
      print('Error parsing Alert: $e');
      return Alert(
        type: '',
        message: '',
        priority: 'low',
        createdAt: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
      'priority': priority,
      'createdAt': createdAt,
    };
  }
}

class MaintenanceHistory {
  final String date;
  final String type;
  final String notes;

  MaintenanceHistory({
    required this.date,
    required this.type,
    required this.notes,
  });

  factory MaintenanceHistory.fromJson(Map<String, dynamic> json) {
    try {
      return MaintenanceHistory(
        date: json['date']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
      );
    } catch (e) {
      print('Error parsing MaintenanceHistory: $e');
      return MaintenanceHistory(
        date: '',
        type: '',
        notes: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'type': type,
      'notes': notes,
    };
  }
}
