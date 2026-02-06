class RoomCardModel {
  final String id;
  final String title;
  final String styleName;
  final String imagePath;
  final double totalAssetValue;
  final double maintenanceHealth; // 0.0 ~ 1.0
  final bool isAiGenerated;
  final int alertCount;
  final int maintenanceCount;
  final int deviceCount;

  const RoomCardModel({
    required this.id,
    required this.title,
    required this.styleName,
    required this.imagePath,
    required this.totalAssetValue,
    required this.maintenanceHealth,
    this.isAiGenerated = false,
    this.alertCount = 0,
    this.maintenanceCount = 0,
    this.deviceCount = 0,
  });
}
