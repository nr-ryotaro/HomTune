import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/appliance_archetype.dart';
import '../models/appliance_presentation.dart';
import '../models/device.dart';
import '../models/maintenance_task.dart';
import 'compliance_service.dart';

/// 部屋別家電アーキタイプとケア項目テンプレート
class ApplianceTemplateService {
  ApplianceTemplateService._();
  static final ApplianceTemplateService instance = ApplianceTemplateService._();

  Map<String, dynamic>? _raw;
  final Map<String, List<ApplianceArchetype>> _archetypesByRoom = {};

  static const _approvedAttribution = {
    'sourceType': 'internal',
    'sourceUrl': '',
    'publisher': 'HomTune Editorial',
    'licenseType': 'internal-curated',
    'capturedAt': '2026-06-01T00:00:00.000Z',
    'confidence': 0.9,
    'reviewState': 'approved',
  };

  Future<void> _ensureLoaded() async {
    if (_raw != null) return;
    final jsonStr =
        await rootBundle.loadString('assets/data/room-appliance-templates.json');
    _raw = jsonDecode(jsonStr) as Map<String, dynamic>;
    final rooms = _raw!['rooms'] as Map<String, dynamic>? ?? {};
    for (final entry in rooms.entries) {
      final roomId = entry.key;
      final roomData = entry.value as Map<String, dynamic>;
      final list = roomData['archetypes'] as List<dynamic>? ?? [];
      _archetypesByRoom[roomId] = list
          .map((e) => ApplianceArchetype.fromJson(
              roomId, e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<List<ApplianceArchetype>> getArchetypesForRoom(String roomId) async {
    await _ensureLoaded();
    return List.unmodifiable(_archetypesByRoom[roomId] ?? []);
  }

  Future<List<ApplianceArchetype>> getArchetypesForRooms(
    Iterable<String> roomIds,
  ) async {
    await _ensureLoaded();
    final result = <ApplianceArchetype>[];
    for (final id in roomIds) {
      result.addAll(_archetypesByRoom[id] ?? []);
    }
    return result;
  }

  Future<ApplianceArchetype?> getArchetypeById(String archetypeId) async {
    await _ensureLoaded();
    for (final list in _archetypesByRoom.values) {
      for (final a in list) {
        if (a.id == archetypeId) return a;
      }
    }
    return null;
  }

  Future<List<MaintenanceTask>> buildTasksForArchetype(
    String archetypeId,
    String deviceId,
  ) async {
    await _ensureLoaded();
    final careItems = _findCareItems(archetypeId);
    if (careItems == null) return [];

    final tasks = <MaintenanceTask>[];
    for (final item in careItems) {
      final type = item['type']?.toString() ?? 'maintenance';
      if (type == 'seasonal') {
        continue;
      }
      final template = Map<String, dynamic>.from(item);
      template['sourceAttribution'] = _approvedAttribution;
      if (!template.containsKey('shortMethod')) {
        template['shortMethod'] = '';
      }
      final task = MaintenanceTask.fromCategoryDefault(template, deviceId);
      final attribution = task.sourceAttribution;
      if (attribution != null && !ComplianceService.canDistribute(attribution)) {
        continue;
      }
      tasks.add(task);
    }
    return tasks;
  }

  List<Map<String, dynamic>>? _findCareItems(String archetypeId) {
    final rooms = _raw?['rooms'] as Map<String, dynamic>?;
    if (rooms == null) return null;
    for (final roomData in rooms.values) {
      final archetypes = roomData['archetypes'] as List<dynamic>? ?? [];
      for (final raw in archetypes) {
        final map = raw as Map<String, dynamic>;
        if (map['id']?.toString() == archetypeId) {
          return (map['careItems'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList();
        }
      }
    }
    return null;
  }

  static const Map<String, String> _categoryFallbackIcons = {
    'エアコン': '❄️',
    'テレビ': '📺',
    '空気清浄機': '🌬️',
    '加湿器': '💧',
    '掃除機': '🧹',
    '冷蔵庫': '🧊',
    '電子レンジ': '📡',
    '食洗機': '🍽️',
    '炊飯器': '🍚',
    'コンロ': '🔥',
    'オーブン': '🔥',
    'レンジフード': '💨',
    '洗濯機': '🧺',
    'PC': '💻',
    'オーディオ': '🔊',
  };

  /// ホームのコンパクトカード用表示（カスタム > テンプレ > カテゴリ）
  Future<AppliancePresentation> resolvePresentation(Device device) async {
    await _ensureLoaded();
    final archetype = await _findArchetypeForDevice(device);

    AppliancePresentation base;
    if (archetype != null) {
      base = AppliancePresentation(
        icon: archetype.icon,
        title: archetype.displayName,
        subtitle: _modelSubtitle(device, archetype.displayName),
      );
    } else {
      final categoryTitle =
          device.category.trim().isNotEmpty ? device.category.trim() : null;
      final title = categoryTitle ?? _shortName(device.name);
      base = AppliancePresentation(
        icon: _categoryFallbackIcons[device.category] ?? '📦',
        title: title,
        subtitle: _modelSubtitle(device, title),
      );
    }

    final customIcon = device.customIcon?.trim();
    final customTitle = device.customDisplayName?.trim();
    final title = (customTitle != null && customTitle.isNotEmpty)
        ? customTitle
        : base.title;
    return AppliancePresentation(
      icon: (customIcon != null && customIcon.isNotEmpty)
          ? customIcon
          : base.icon,
      title: title,
      subtitle: _detailModelLine(device, title),
    );
  }

  /// 詳細一覧用（型番・製品名を優先表示）
  String? _detailModelLine(Device device, String displayTitle) {
    final model = device.modelNumber.trim();
    if (model.isNotEmpty) return model;
    final productName = device.name.trim();
    if (productName.isNotEmpty &&
        productName.toLowerCase() != displayTitle.toLowerCase()) {
      return productName;
    }
    final maker = device.manufacturer.trim();
    if (maker.isNotEmpty) return maker;
    return null;
  }

  Future<ApplianceArchetype?> _findArchetypeForDevice(Device device) async {
    if (device.archetypeId != null && device.archetypeId!.isNotEmpty) {
      final byId = await getArchetypeById(device.archetypeId!);
      if (byId != null) return byId;
    }

    final cat = device.category.trim().toLowerCase();
    final name = device.name.trim().toLowerCase();
    ApplianceArchetype? categoryMatch;

    for (final list in _archetypesByRoom.values) {
      for (final a in list) {
        final archetypeCat = a.category.trim().toLowerCase();
        if (cat.isNotEmpty && archetypeCat == cat) {
          categoryMatch ??= a;
        }
        final display = a.displayName.trim().toLowerCase();
        if (name.isNotEmpty &&
            (name.contains(display) || display.contains(name))) {
          return a;
        }
      }
    }
    return categoryMatch;
  }

  String? _modelSubtitle(Device device, String title) {
    final model = device.modelNumber.trim();
    if (model.isEmpty) return null;
    if (model.toLowerCase() == title.toLowerCase()) return null;
    if (device.name.trim().toLowerCase().contains(model.toLowerCase())) {
      return null;
    }
    return model;
  }

  String _shortName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '家電';
    if (trimmed.length <= 12) return trimmed;
    return '${trimmed.substring(0, 11)}…';
  }

  /// 登録済みデバイスと照合し、未登録のアーキタイプを返す
  Future<List<({ApplianceArchetype archetype, SelectedArchetypeRef ref})>>
      getUnregisteredSuggestions({
    required List<SelectedArchetypeRef> selected,
    required List<String> registeredCategories,
    required List<String> registeredNames,
  }) async {
    final out = <({ApplianceArchetype archetype, SelectedArchetypeRef ref})>[];
    for (final ref in selected) {
      final archetype = await getArchetypeById(ref.archetypeId);
      if (archetype == null) continue;
      final catMatch = registeredCategories.any((c) =>
          c.toLowerCase() == archetype.category.toLowerCase() ||
          c == archetype.category);
      final nameMatch = registeredNames.any((n) =>
          n.contains(archetype.displayName) ||
          archetype.displayName.contains(n));
      if (!catMatch && !nameMatch) {
        out.add((archetype: archetype, ref: ref));
      }
    }
    return out;
  }
}
