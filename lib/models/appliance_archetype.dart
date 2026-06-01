/// 部屋別の想定家電（アーキタイプ）
class ApplianceArchetype {
  final String id;
  final String roomId;
  final String displayName;
  final String category;
  final String icon;
  final String defaultLocationHint;

  const ApplianceArchetype({
    required this.id,
    required this.roomId,
    required this.displayName,
    required this.category,
    required this.icon,
    this.defaultLocationHint = '',
  });

  factory ApplianceArchetype.fromJson(
    String roomId,
    Map<String, dynamic> json,
  ) {
    return ApplianceArchetype(
      id: json['id']?.toString() ?? '',
      roomId: roomId,
      displayName: json['displayName']?.toString() ?? '',
      category: json['category']?.toString() ?? 'その他',
      icon: json['icon']?.toString() ?? '📦',
      defaultLocationHint: json['defaultLocationHint']?.toString() ?? '',
    );
  }
}

/// オンボーディングで選択した未登録アーキタイプ
class SelectedArchetypeRef {
  final String archetypeId;
  final String roomId;

  const SelectedArchetypeRef({
    required this.archetypeId,
    required this.roomId,
  });

  Map<String, dynamic> toJson() => {
        'archetypeId': archetypeId,
        'roomId': roomId,
      };

  factory SelectedArchetypeRef.fromJson(Map<String, dynamic> json) {
    return SelectedArchetypeRef(
      archetypeId: json['archetypeId']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
    );
  }
}
