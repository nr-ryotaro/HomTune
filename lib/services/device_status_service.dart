import 'package:flutter/material.dart';
import '../models/device.dart';

/// デバイスの状態を表すenum
enum DeviceStatus {
  /// 健康：アラートなし、または低優先度のみ
  healthy,
  
  /// メンテナンス必要：中優先度アラートあり
  needsMaintenance,
  
  /// エラー：高優先度アラートあり
  error,
  
  /// リコール：リコール対象
  recall,
}

/// デバイス状態判定サービス
class DeviceStatusService {
  static final DeviceStatusService _instance = DeviceStatusService._internal();
  factory DeviceStatusService() => _instance;
  DeviceStatusService._internal();

  /// デバイスの状態を判定
  DeviceStatus getDeviceStatus(Device device) {
    // リコールチェック（最優先）
    if (device.safetyInfo?.isRecallActive == true) {
      return DeviceStatus.recall;
    }

    // メンテナンス情報がない場合は健康とみなす
    if (device.maintenance == null || device.maintenance!.alerts.isEmpty) {
      return DeviceStatus.healthy;
    }

    final alerts = device.maintenance!.alerts;

    // 高優先度アラートがある場合はエラー
    final hasHighPriority = alerts.any((alert) => alert.priority == 'high');
    if (hasHighPriority) {
      return DeviceStatus.error;
    }

    // 中優先度アラートがある場合はメンテナンス必要
    final hasMediumPriority = alerts.any((alert) => alert.priority == 'medium');
    if (hasMediumPriority) {
      return DeviceStatus.needsMaintenance;
    }

    // 低優先度のみ、またはアラートなしの場合は健康
    return DeviceStatus.healthy;
  }

  /// 状態に応じた色を取得
  static Color getStatusColor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.healthy:
        return const Color(0xFF3b82f6); // 青
      case DeviceStatus.needsMaintenance:
        return const Color(0xFFf59e0b); // オレンジ
      case DeviceStatus.error:
        return const Color(0xFFef4444); // 赤
      case DeviceStatus.recall:
        return const Color(0xFFdc2626); // 濃い赤（リコール）
    }
  }
}
