class RoomCardModel {
  final String id;
  final String title;
  // styleName removed
  final String imagePath;
  final double totalAssetValue;
  final double maintenanceHealth; // 0.0 ~ 1.0
  final bool isAiGenerated;
  final int alertCount;
  final int maintenanceCount;
  final int deviceCount;
  final double achievementRate; // 今月のお手入れ達成率 0.0〜1.0
  final int streakWeeks; // 連続完了週数

  const RoomCardModel({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.totalAssetValue,
    required this.maintenanceHealth,
    this.isAiGenerated = false,
    this.alertCount = 0,
    this.maintenanceCount = 0,
    this.deviceCount = 0,
    this.achievementRate = 0.0,
    this.streakWeeks = 0,
  });
}
