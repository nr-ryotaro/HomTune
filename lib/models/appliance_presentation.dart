/// 家電カード表示用（アーキタイプ絵文字＋わかりやすい名称）
class AppliancePresentation {
  final String icon;
  final String title;
  final String? subtitle;

  const AppliancePresentation({
    required this.icon,
    required this.title,
    this.subtitle,
  });
}
