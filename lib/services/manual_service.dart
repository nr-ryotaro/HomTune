import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'pdf_generation_service.dart';
import 'compliance_service.dart';

/// 説明書管理サービス
/// 型番から公式サイトのPDFを検索・ダウンロード・ローカル保存・表示を管理
class ManualService {
  static final ManualService _instance = ManualService._internal();
  factory ManualService() => _instance;
  ManualService._internal();

  /// 説明書のローカル保存ディレクトリを取得
  Future<Directory> _getManualDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final manualDir = Directory(path.join(appDir.path, 'manuals'));
    if (!await manualDir.exists()) {
      await manualDir.create(recursive: true);
    }
    return manualDir;
  }

  /// 型番からローカルファイルパスを生成
  String _getLocalFilePath(String modelNumber) {
    return 'manual_${modelNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf';
  }

  /// 説明書がローカルに保存されているか確認
  Future<bool> isManualDownloaded(String modelNumber) async {
    try {
      final manualDir = await _getManualDirectory();
      final fileName = _getLocalFilePath(modelNumber);
      final file = File(path.join(manualDir.path, fileName));
      return await file.exists();
    } catch (e) {
      print('Error checking manual: $e');
      return false;
    }
  }

  /// ローカルに保存された説明書のパスを取得
  Future<File?> getLocalManual(String modelNumber) async {
    try {
      if (!await isManualDownloaded(modelNumber)) {
        return null;
      }
      final manualDir = await _getManualDirectory();
      final fileName = _getLocalFilePath(modelNumber);
      return File(path.join(manualDir.path, fileName));
    } catch (e) {
      print('Error getting local manual: $e');
      return null;
    }
  }

  /// 型番から公式サイトのPDF URLを検索（モック実装）
  Future<String?> _searchManualUrl(String modelNumber, String manufacturer) async {
    // モック実装: 実際の実装では、メーカーの公式サイトを検索
    // または、メーカーのAPIを使用してPDF URLを取得
    
    // ダイキンの場合
    if (manufacturer.contains('ダイキン') || manufacturer.toLowerCase().contains('daikin')) {
      // 実際の実装では、型番に基づいて適切なURLを返す
      // 例: https://www.daikin.co.jp/manual/{modelNumber}.pdf
      return 'https://www.daikin.co.jp/manual/$modelNumber.pdf';
    }
    
    // Appleの場合
    if (manufacturer.toLowerCase().contains('apple')) {
      // 実際の実装では、Apple Support APIを使用
      return 'https://support.apple.com/manuals/$modelNumber.pdf';
    }
    
    // その他のメーカー（モック）
    // 実際の実装では、メーカーごとの検索ロジックを実装
    return 'https://example.com/manuals/$modelNumber.pdf';
  }

  /// 説明書PDFをダウンロードしてローカルに保存
  Future<File?> downloadManual(String modelNumber, String manufacturer) async {
    try {
      if (kReleaseMode) {
        await ComplianceService.logEvent(
          action: 'manual_download_blocked',
          targetId: '$manufacturer:$modelNumber',
          result: 'blocked',
          reason: 'pdf_persistence_disabled_in_release',
        );
        throw Exception('商用モードでは公式PDFの自動保存は無効です。');
      }

      // 既にダウンロード済みの場合はローカルファイルを返す
      final localFile = await getLocalManual(modelNumber);
      if (localFile != null) {
        return localFile;
      }

      // PDF URLを検索
      final pdfUrl = await _searchManualUrl(modelNumber, manufacturer);
      if (pdfUrl == null) {
        throw Exception('説明書のURLが見つかりませんでした');
      }
      if (!ComplianceService.isAllowedSourceUrl(pdfUrl)) {
        await ComplianceService.logEvent(
          action: 'manual_download_blocked',
          targetId: '$manufacturer:$modelNumber',
          result: 'blocked',
          reason: 'unapproved_source',
        );
        throw Exception('許可されていないソースのため取得できません');
      }

      // PDFをダウンロード
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode != 200) {
        throw Exception('PDFのダウンロードに失敗しました: ${response.statusCode}');
      }

      // ローカルに保存
      final manualDir = await _getManualDirectory();
      final fileName = _getLocalFilePath(modelNumber);
      final file = File(path.join(manualDir.path, fileName));
      await file.writeAsBytes(response.bodyBytes);

      return file;
    } catch (e) {
      print('Error downloading manual: $e');
      rethrow;
    }
  }

  /// 説明書を取得（ローカルにあれば返す、なければダウンロード）
  /// 
  /// [modelNumber] 型番
  /// [manufacturer] メーカー名
  /// [manualUrl] オプション: 既存のマニュアルURL（Manual.url）
  /// 戻り値: PDFファイル
  Future<File?> getManual(
    String modelNumber,
    String manufacturer, {
    String? manualUrl,
  }) async {
    try {
      // manualUrlが指定されている場合、それを優先
      if (manualUrl != null && manualUrl.isNotEmpty) {
        // ローカルファイルの場合
        if (manualUrl.startsWith('file://')) {
          final filePath = manualUrl.replaceFirst('file://', '');
          final file = File(filePath);
          if (await file.exists()) {
            return file;
          }
        }
        // 外部URLの場合は、既存のダウンロードロジックを使用
        // （この場合はmodelNumberとmanufacturerから検索）
      }

      // まずローカルを確認
      final localFile = await getLocalManual(modelNumber);
      if (localFile != null) {
        return localFile;
      }

      // ローカルになければダウンロード
      return await downloadManual(modelNumber, manufacturer);
    } catch (e) {
      print('Error getting manual: $e');
      return null;
    }
  }

  /// ローカルPDFファイルを保存
  /// 
  /// [pdfFile] 保存するPDFファイル
  /// [deviceId] デバイスID
  /// [deviceName] デバイス名
  /// [modelNumber] 型番
  /// 戻り値: 保存されたファイルのパス（file://プレフィックス付き）
  Future<String> saveLocalManual(
    File pdfFile,
    String deviceId,
    String deviceName,
    String modelNumber,
  ) async {
    try {
      final manualDir = await _getManualDirectory();
      final fileName = _getLocalFilePath(modelNumber);
      final targetFile = File(path.join(manualDir.path, fileName));

      // PDFファイルをコピー
      await pdfFile.copy(targetFile.path);

      // file://プレフィックスを付けて返す
      return 'file://${targetFile.path}';
    } catch (e) {
      print('Error saving local manual: $e');
      rethrow;
    }
  }

  /// 複数の画像からPDFを生成して保存
  /// 
  /// [images] 画像ファイルのリスト
  /// [deviceId] デバイスID
  /// [deviceName] デバイス名
  /// [modelNumber] 型番
  /// 戻り値: 生成されたPDFファイル
  Future<File> generatePdfFromImages(
    List<File> images,
    String deviceId,
    String deviceName,
    String modelNumber,
  ) async {
    try {
      // PDFを生成
      final pdfService = PdfGenerationService();
      final pdfBytes = await pdfService.generatePdfFromImages(images);

      // 一時ファイルに保存
      final manualDir = await _getManualDirectory();
      final fileName = _getLocalFilePath(modelNumber);
      final pdfFile = File(path.join(manualDir.path, fileName));
      await pdfFile.writeAsBytes(pdfBytes);

      return pdfFile;
    } catch (e) {
      print('Error generating PDF from images: $e');
      rethrow;
    }
  }

  /// URLまたはローカルパスからFileを取得
  /// 
  /// [manualUrl] 外部URLまたはローカルファイルパス（file://プレフィックス付き）
  /// 戻り値: Fileオブジェクト（外部URLの場合はnull）
  Future<File?> getManualFile(String manualUrl) async {
    try {
      if (manualUrl.isEmpty) {
        return null;
      }

      // ローカルファイルの場合
      if (manualUrl.startsWith('file://')) {
        final filePath = manualUrl.replaceFirst('file://', '');
        final file = File(filePath);
        if (await file.exists()) {
          return file;
        }
        return null;
      }

      // 外部URLの場合は、既存のgetManualメソッドを使用
      // ただし、このメソッドはmodelNumberとmanufacturerが必要なので、
      // 外部URLの場合は直接ダウンロードする必要がある
      // ここではローカルファイルのみを処理
      return null;
    } catch (e) {
      print('Error getting manual file: $e');
      return null;
    }
  }
}
