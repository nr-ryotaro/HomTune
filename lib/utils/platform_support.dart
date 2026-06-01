import 'package:flutter/foundation.dart';

/// プラットフォーム別の機能可否（Web プレビュー用）
class PlatformSupport {
  PlatformSupport._();

  /// Flutter Web で UI 確認ビルドか
  static bool get isWebUiPreview => kIsWeb;

  /// Smart Ingester（カメラ・バーコード・ML Kit OCR）
  static bool get supportsSmartIngester => !kIsWeb;

  /// 機材写真（dart:io / カメラ）
  static bool get supportsDevicePhotoPick => !kIsWeb;

  /// マニュアル URL の SQLite キャッシュ
  static bool get supportsManualSqliteCache => !kIsWeb;
}
