import 'dart:io';

/// OCR解析サービス（モック実装）
/// 実際の実装では、Google ML Kit、Tesseract OCR、またはクラウドAPIを使用
class OCRService {
  /// 画像からテキストを解析し、デバイス情報を抽出
  Future<Map<String, String>> scanImage(File image) async {
    // モック実装: 実際のOCR処理をシミュレート
    await Future.delayed(const Duration(milliseconds: 500));

    // モックデータ: 実際のOCR結果を返す
    // 実際の実装では、OCRライブラリを使用して画像からテキストを抽出し、
    // 正規表現やNLPで型番、メーカー、製品名を抽出する
    
    return {
      // 型番の例（実際のOCR結果から抽出）
      'modelNumber': _extractModelNumber(image),
      'manufacturer': _extractManufacturer(image),
      'name': _extractName(image),
      'category': _extractCategory(image),
      'serialNumber': _extractSerialNumber(image),
    };
  }

  /// 型番を抽出（モック）
  String _extractModelNumber(File image) {
    // 実際の実装では、OCR結果から正規表現で型番パターンを検出
    // 例: "CS-ZX2811", "MacBookPro16,1", "VT-4A" など
    final mockModelNumbers = [
      'CS-ZX2811',
      'MacBookPro16,1',
      'VT-4A',
      'KDL-55A8H',
      'WH-1000XM5',
    ];
    return mockModelNumbers[DateTime.now().millisecond % mockModelNumbers.length];
  }

  /// メーカーを抽出（モック）
  String _extractManufacturer(File image) {
    // 実際の実装では、OCR結果からメーカー名を検出
    final mockManufacturers = [
      'ダイキン',
      'Apple',
      'Yamaha',
      'Sony',
      'Panasonic',
    ];
    return mockManufacturers[DateTime.now().millisecond % mockManufacturers.length];
  }

  /// 製品名を抽出（モック）
  String _extractName(File image) {
    // 実際の実装では、OCR結果から製品名を検出
    final mockNames = [
      'エアコン リビング',
      'MacBook Pro',
      '真空管アンプ',
      'BRAVIA',
      'ワイヤレスヘッドホン',
    ];
    return mockNames[DateTime.now().millisecond % mockNames.length];
  }

  /// カテゴリを抽出（モック）
  String _extractCategory(File image) {
    // 実際の実装では、OCR結果や製品名からカテゴリを推測
    final mockCategories = [
      'エアコン',
      'PC',
      'オーディオ',
      'TV',
      'ヘッドホン',
    ];
    return mockCategories[DateTime.now().millisecond % mockCategories.length];
  }

  /// シリアル番号を抽出（モック）
  String _extractSerialNumber(File image) {
    // 実際の実装では、OCR結果からシリアル番号パターンを検出
    // 多くの場合、シリアル番号は見つからない
    return '';
  }
}
