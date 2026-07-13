import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/device_remote_link.dart';
import '../../models/remote_compatibility_assessment.dart';

/// 型番・カテゴリ・アーキタイプからリモコン操作可否を判定
class RemoteCompatibilityService {
  RemoteCompatibilityService._();
  static final RemoteCompatibilityService instance =
      RemoteCompatibilityService._();

  Map<String, dynamic>? _raw;
  List<_CategoryRule> _categoryRules = [];
  List<_ArchetypeRule> _archetypeRules = [];
  List<_ModelPatternRule> _modelPatterns = [];
  Future<void>? _loadingFuture;

  Future<void> _ensureLoaded() async {
    if (_raw != null) return;
    _loadingFuture ??= _loadCatalog();
    await _loadingFuture;
  }

  Future<void> _loadCatalog() async {
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/data/remote-compatibility-catalog.json',
      );
      final raw = jsonDecode(jsonStr) as Map<String, dynamic>;
      _raw = raw;
      _categoryRules = (raw['categoryRules'] as List<dynamic>? ?? [])
          .map((e) => _CategoryRule.fromJson(e as Map<String, dynamic>))
          .toList();
      _archetypeRules = (raw['archetypeRules'] as List<dynamic>? ?? [])
          .map((e) => _ArchetypeRule.fromJson(e as Map<String, dynamic>))
          .toList();
      _modelPatterns = (raw['modelPatterns'] as List<dynamic>? ?? [])
          .map((e) => _ModelPatternRule.tryFromJson(e as Map<String, dynamic>))
          .whereType<_ModelPatternRule>()
          .toList();
    } catch (e) {
      _raw = const {};
      _categoryRules = [];
      _archetypeRules = [];
      _modelPatterns = [];
    }
  }

  /// テスト用: メモリ上のカタログを直接注入
  void loadCatalogForTest(Map<String, dynamic> raw) {
    _loadingFuture = null;
    _raw = raw;
    _categoryRules = (raw['categoryRules'] as List<dynamic>? ?? [])
        .map((e) => _CategoryRule.fromJson(e as Map<String, dynamic>))
        .toList();
    _archetypeRules = (raw['archetypeRules'] as List<dynamic>? ?? [])
        .map((e) => _ArchetypeRule.fromJson(e as Map<String, dynamic>))
        .toList();
    _modelPatterns = (raw['modelPatterns'] as List<dynamic>? ?? [])
        .map((e) => _ModelPatternRule.tryFromJson(e as Map<String, dynamic>))
        .whereType<_ModelPatternRule>()
        .toList();
  }

  /// テスト用リセット
  void resetForTest() {
    _raw = null;
    _categoryRules = [];
    _archetypeRules = [];
    _modelPatterns = [];
    _loadingFuture = null;
  }

  Future<RemoteCompatibilityAssessment> assess({
    required String modelNumber,
    required String category,
    String manufacturer = '',
    String? archetypeId,
  }) async {
    try {
      await _ensureLoaded();

    final model = modelNumber.trim().toUpperCase();
    final cat = category.trim();
    final mfr = manufacturer.trim();

    if (model.isEmpty && cat.isEmpty && (archetypeId == null || archetypeId.isEmpty)) {
      return RemoteCompatibilityAssessment.notEligible;
    }

    final modelMatch = _matchModelPattern(model, mfr);
    if (modelMatch != null) {
      return _buildAssessment(
        rule: modelMatch,
        source: RemoteCompatibilitySource.modelPattern,
        confidence: RemoteCompatibilityConfidence.high,
      );
    }

    if (archetypeId != null && archetypeId.isNotEmpty) {
      final archetypeMatch = _archetypeRules
          .where((r) => r.archetypeId == archetypeId && r.eligible)
          .toList();
      if (archetypeMatch.isNotEmpty) {
        final rule = archetypeMatch.first;
        return _buildAssessment(
          rule: rule,
          source: RemoteCompatibilitySource.archetype,
          confidence: RemoteCompatibilityConfidence.medium,
        );
      }
    }

    final categoryMatch = _matchCategory(cat, eligibleOnly: true);
    if (categoryMatch != null) {
      return _buildAssessment(
        rule: categoryMatch,
        source: RemoteCompatibilitySource.category,
        confidence: RemoteCompatibilityConfidence.medium,
      );
    }

    final excluded = _matchCategory(cat, eligibleOnly: false);
    if (excluded != null && !excluded.eligible) {
      return RemoteCompatibilityAssessment.notEligible;
    }

    return RemoteCompatibilityAssessment.notEligible;
    } catch (_) {
      return RemoteCompatibilityAssessment.notEligible;
    }
  }

  _CategoryRule? _matchCategory(String category, {required bool eligibleOnly}) {
    if (category.isEmpty) return null;
    final normalized = category.toLowerCase();
    for (final rule in _categoryRules) {
      final matches = rule.categories.any(
        (c) =>
            c.toLowerCase() == normalized ||
            normalized.contains(c.toLowerCase()) ||
            c.toLowerCase().contains(normalized),
      );
      if (!matches) continue;
      if (eligibleOnly && !rule.eligible) continue;
      if (!eligibleOnly && !rule.eligible) return rule;
      if (eligibleOnly && rule.eligible) return rule;
    }
    return null;
  }

  _ModelPatternRule? _matchModelPattern(String model, String manufacturer) {
    if (model.isEmpty) return null;
    for (final rule in _modelPatterns) {
      if (!_manufacturerMatches(rule.manufacturer, manufacturer)) continue;
      if (rule.regex.hasMatch(model)) return rule;
    }
    return null;
  }

  bool _manufacturerMatches(String ruleManufacturer, String inputManufacturer) {
    if (ruleManufacturer.isEmpty) return true;
    if (inputManufacturer.isEmpty) return true;
    return ruleManufacturer.toLowerCase() ==
        inputManufacturer.toLowerCase();
  }

  RemoteCompatibilityAssessment _buildAssessment({
    required dynamic rule,
    required RemoteCompatibilitySource source,
    required RemoteCompatibilityConfidence confidence,
  }) {
    final profile = _parseProfile(rule.profile);
    final providers = _parseProviders(rule.providers);
    final label = rule.label?.toString();

    return RemoteCompatibilityAssessment(
      isEligible: true,
      profile: profile,
      label: label,
      suggestedProviders: providers,
      source: source,
      confidence: confidence,
      userMessage: label != null
          ? '$labelはスマートリモコンで操作できる可能性があります'
          : 'この家電はスマートリモコンで操作できる可能性があります',
    );
  }

  RemoteCapabilityProfile? _parseProfile(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return RemoteCapabilityProfile.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => RemoteCapabilityProfile.genericIr,
    );
  }

  List<RemoteProvider> _parseProviders(List<dynamic>? raw) {
    if (raw == null || raw.isEmpty) {
      return const [RemoteProvider.remo, RemoteProvider.switchbot];
    }
    return raw
        .map((e) => RemoteProvider.values.firstWhere(
              (p) => p.name == e.toString(),
              orElse: () => RemoteProvider.remo,
            ))
        .toList();
  }
}

class _CategoryRule {
  final List<String> categories;
  final bool eligible;
  final String? profile;
  final String? label;
  final List<String> providers;

  _CategoryRule({
    required this.categories,
    required this.eligible,
    this.profile,
    this.label,
    this.providers = const [],
  });

  factory _CategoryRule.fromJson(Map<String, dynamic> json) {
    return _CategoryRule(
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      eligible: json['eligible'] == true,
      profile: json['profile']?.toString(),
      label: json['label']?.toString(),
      providers: (json['providers'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class _ArchetypeRule {
  final String archetypeId;
  final bool eligible;
  final String? profile;
  final String? label;
  final List<String> providers;

  _ArchetypeRule({
    required this.archetypeId,
    required this.eligible,
    this.profile,
    this.label,
    this.providers = const [],
  });

  factory _ArchetypeRule.fromJson(Map<String, dynamic> json) {
    return _ArchetypeRule(
      archetypeId: json['archetypeId']?.toString() ?? '',
      eligible: json['eligible'] == true,
      profile: json['profile']?.toString(),
      label: json['label']?.toString(),
      providers: (json['providers'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class _ModelPatternRule {
  final String manufacturer;
  final RegExp regex;
  final bool eligible;
  final String? profile;
  final String? label;
  final List<String> providers;

  _ModelPatternRule({
    required this.manufacturer,
    required this.regex,
    required this.eligible,
    this.profile,
    this.label,
    this.providers = const [],
  });

  factory _ModelPatternRule.fromJson(Map<String, dynamic> json) {
    final parsed = tryFromJson(json);
    if (parsed == null) {
      throw FormatException('Invalid model pattern: ${json['pattern']}');
    }
    return parsed;
  }

  static _ModelPatternRule? tryFromJson(Map<String, dynamic> json) {
    final pattern = json['pattern']?.toString() ?? '';
    if (pattern.isEmpty) return null;
    try {
      return _ModelPatternRule(
        manufacturer: json['manufacturer']?.toString() ?? '',
        regex: RegExp(pattern, caseSensitive: false),
        eligible: json['eligible'] == true,
        profile: json['profile']?.toString(),
        label: json['label']?.toString(),
        providers: (json['providers'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }
}
