import 'dart:convert';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/ai_usage_policy.dart';
import 'ai_usage_service.dart';
import 'config_service.dart';
import 'web_search_service.dart';

/// Smart Ingester: OCR（ML Kit）+ Gemini による製品プレートからの構造化データ抽出
class ScannerService {
  final ConfigService _configService;
  late final WebSearchService _webSearchService;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);

  ScannerService(this._configService, {WebSearchService? webSearchService}) {
    _webSearchService = webSearchService ?? WebSearchService(_configService);
  }

  /// 画像からテキストを抽出（ML Kit）
  Future<String> extractTextFromImage(File image) async {
    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final recognized = await _textRecognizer.processImage(inputImage);
      return recognized.text;
    } catch (e) {
      throw ScannerException('OCR に失敗しました: $e');
    }
  }

  /// ダミーモード: OCRテキストから簡易パース。失敗時は固定サンプル
  ExtractedProductInfo _extractProductInfoDummy(String rawText) {
    String manufacturer = '';
    String modelNumber = '';
    String category = '';

    final mfRegex = RegExp(
      r'(ダイキン|パナソニック|三菱|シャープ|ソニー|Apple|LG|サムスン|日立|東芝|Panasonic|Mitsubishi|Sharp|Sony|Samsung|Hitachi|Toshiba|Daikin)',
      caseSensitive: false,
    );
    final mfMatch = mfRegex.firstMatch(rawText);
    if (mfMatch != null) manufacturer = mfMatch.group(1)!;

    final modelRegex = RegExp(
      r'(?:Model\s*No\.?|型番|型式|Model|TYPE)\s*[:\s]*([A-Za-z0-9\-_,\.]+)',
      caseSensitive: false,
    );
    final modelMatch = modelRegex.firstMatch(rawText);
    if (modelMatch != null) modelNumber = modelMatch.group(1)!.trim();

    if (modelNumber.isNotEmpty) {
      if (modelNumber.startsWith('CS-') || modelNumber.startsWith('RXC')) {
        category = 'エアコン';
      } else if (modelNumber.startsWith('KDL-') || modelNumber.startsWith('XBR')) {
        category = 'テレビ';
      } else if (modelNumber.startsWith('WH-') || modelNumber.contains('XM')) {
        category = 'ヘッドホン';
      } else if (modelNumber.startsWith('Mac') || modelNumber.startsWith('iPhone')) {
        category = 'PC';
      } else if (modelNumber.contains('Viera') || modelNumber.startsWith('TH-')) {
        category = 'テレビ';
      } else {
        category = 'その他';
      }
    }
    if (category.isEmpty && manufacturer.isNotEmpty) {
      category = 'その他';
    }

    if (manufacturer.isEmpty && modelNumber.isEmpty) {
      return ExtractedProductInfo(
        manufacturer: 'ダイキン',
        modelNumber: 'CS-ZX2811',
        category: 'エアコン',
      );
    }
    return ExtractedProductInfo(
      manufacturer: manufacturer,
      modelNumber: modelNumber,
      category: category.isEmpty ? 'その他' : category,
    );
  }

  /// 生テキストを Gemini に投げ、メーカー・型番・カテゴリを構造化 JSON で取得
  /// ダミーモード時は簡易パース or 固定サンプルを返す
  Future<ExtractedProductInfo> extractProductInfo(String rawText) async {
    if (rawText.trim().isEmpty) {
      throw ScannerException('読み取れたテキストがありません。プレートがはっきり写っているか確認してください。');
    }

    if (!_configService.isUsingRealApi) {
      return _extractProductInfoDummy(rawText);
    }
    final requestedCredits = AiUsageService.instance.defaultFeatureCredits(
      AiFeature.scanner,
    );
    final budget = await AiUsageService.instance.canRunFeature(
      _configService,
      feature: AiFeature.scanner,
      requestedCredits: requestedCredits,
    );
    if (!budget.allowed) {
      throw ScannerException('${budget.reason}（ローカル判定に切替してください）');
    }

    final apiKey = _configService.geminiApiKey;
    if (apiKey.isEmpty) {
      throw ScannerException('Gemini API キーが設定されていません。--dart-define=GEMINI_API_KEY=xxx で指定してください。');
    }

    const systemPrompt = '''
あなたは家電の製品プレート（取説ラベル、裏面の型番シールなど）のOCR結果を解析する専門家です。
以下の表記パターンを理解し、最も可能性の高い型番を1つだけ特定してください。

- 型番の表記例: Model No. / Model No / 型番 / 型式 / Model / Type / TYPE / MODEL
- メーカー表記例: メーカー名、製造者、Manufacturer、© の近くの企業名
- シリアル番号(S/N)は型番ではありません。型番は製品ラインを表す英数字（例: CS-ZX2811, KDL-55A8H, WH-1000XM5）です。
- ノイズや誤認識は無視し、意味のある表記のみを採用してください。
''';

    const userPromptPrefix = '''
以下は家電製品プレートのOCRで得られた生テキストです。ノイズが含まれている可能性があります。

【OCR 生テキスト】
''';
    const userPromptSuffix = '''

【指示】
上記から以下を抽出し、**必ず以下のJSON形式のみ**で回答してください。他の説明文は一切書かないでください。

{
  "manufacturer": "メーカー名（日本語または英語）",
  "modelNumber": "型番（1つだけ、最も確度の高いもの）",
  "category": "製品カテゴリ（例: エアコン, 冷蔵庫, 洗濯機, テレビ, PC, オーディオ, 掃除機, その他）"
}

不明な項目は空文字 "" にしてください。型番が複数候補ある場合は、製品識別に最も使われる1つを選んでください。
''';

    try {
      final model = GenerativeModel(
        model: _configService.geminiModelFor(AiFeature.scanner),
        apiKey: apiKey,
      );
      final fullPrompt = '$systemPrompt\n\n$userPromptPrefix$rawText$userPromptSuffix';
      final response = await model.generateContent([Content.text(fullPrompt)]);

      final text = response.text?.trim() ?? '';
      if (text.isEmpty) throw ScannerException('Gemini から有効な応答が得られませんでした。');

      // JSON ブロックのみ抽出（```json ... ``` の可能性あり）
      String jsonStr = text;
      final codeBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
      final m = codeBlock.firstMatch(text);
      if (m != null) jsonStr = m.group(1)?.trim() ?? text;

      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      await AiUsageService.instance.recordUsage(
        _configService,
        feature: AiFeature.scanner,
        consumedCredits: requestedCredits,
        route: 'scanner_extract',
      );
      return ExtractedProductInfo(
        manufacturer: (decoded['manufacturer'] as String?)?.trim() ?? '',
        modelNumber: (decoded['modelNumber'] as String?)?.trim() ?? '',
        category: (decoded['category'] as String?)?.trim() ?? '',
      );
    } on FormatException catch (e) {
      throw ScannerException('解析結果の形式が不正です: $e');
    } catch (e) {
      if (e is ScannerException) rethrow;
      throw ScannerException('Gemini API の呼び出しに失敗しました: $e');
    }
  }

  /// 画像 → OCR → Gemini の一括処理
  Future<ExtractedProductInfo> processPlateImage(File image) async {
    final raw = await extractTextFromImage(image);
    return extractProductInfo(raw);
  }

  /// 抽出された情報をWeb検索で洗練させる（OCR後の補正用）
  Future<ExtractedProductInfo> refineProductInfo(ExtractedProductInfo info) async {
    if (info.isEmpty || info.modelNumber.isEmpty) return info;

    try {
      final query = '${info.manufacturer} ${info.modelNumber}';
      final searchResult = await _webSearchService.search(query);
      return await _parseSearchResultWithGemini(searchResult, query: query);
    } catch (e) {
      return info;
    }
  }

  /// JANコードから製品情報を検索・取得
  Future<ExtractedProductInfo> getProductInfoFromJan(String janCode) async {
    try {
      // 1. Web検索 (JAN code)
      final query = 'JANコード $janCode';
      final searchResult = await _webSearchService.search(query);
      
      // 2. Geminiで解析
      return await _parseSearchResultWithGemini(searchResult, query: query, janCode: janCode);
    } catch (e) {
      return ExtractedProductInfo(manufacturer: '', modelNumber: '', category: '');
    }
  }

  /// 検索結果テキスト(HTML/Snippet)を解析して製品情報を抽出
  Future<ExtractedProductInfo> _parseSearchResultWithGemini(String rawText, {required String query, String? janCode}) async {
      if (!_configService.isUsingRealApi) {
        if (janCode == '4901234567890') {
           return ExtractedProductInfo(manufacturer: 'サンプルメーカー', modelNumber: 'SMP-001', category: 'その他');
        }
        return ExtractedProductInfo(manufacturer: '', modelNumber: '', category: '');
      }

      final apiKey = _configService.geminiApiKey;
      if (apiKey.isEmpty) {
        return ExtractedProductInfo(manufacturer: '', modelNumber: '', category: '');
      }
      final requestedCredits = AiUsageService.instance.defaultFeatureCredits(
        AiFeature.scanner,
      );
      final budget = await AiUsageService.instance.canRunFeature(
        _configService,
        feature: AiFeature.scanner,
        requestedCredits: requestedCredits,
      );
      if (!budget.allowed) {
        return ExtractedProductInfo(
          manufacturer: '',
          modelNumber: '',
          category: '',
        );
      }

      const systemPrompt = '''
あなたは家電製品のWeb検索結果（HTMLまたはテキスト）を解析する専門家です。
検索結果から、検索クエリに該当する「メーカー名」「製品名（型番含む）」「カテゴリ」を特定してください。
''';

      final userPrompt = '''
【検索クエリ】
$query
${janCode != null ? '\n【JANコード】\n$janCode' : ''}

【検索結果テキスト】
$rawText

【指示】
上記から以下を抽出し、**必ず以下のJSON形式のみ**で回答してください。
{
  "manufacturer": "メーカー名",
  "modelNumber": "製品名または型番（例: WH-1000XM5, iPhone 15 Pro）",
  "category": "製品カテゴリ（例: エアコン, テレビ, ヘッドホン）"
}
情報が見つからない場合は空文字にしてください。
''';

      try {
        final model =
            GenerativeModel(
                model: _configService.geminiModelFor(AiFeature.scanner),
                apiKey: apiKey);
        final response = await model.generateContent([Content.text('$systemPrompt\n\n$userPrompt')]);
        
        final text = response.text?.trim() ?? '';
        String jsonStr = text;
        final codeBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
        final m = codeBlock.firstMatch(text);
        if (m != null) jsonStr = m.group(1)?.trim() ?? text;

        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        await AiUsageService.instance.recordUsage(
          _configService,
          feature: AiFeature.scanner,
          consumedCredits: requestedCredits,
          route: 'scanner_search_refine',
        );
        return ExtractedProductInfo(
          manufacturer: (decoded['manufacturer'] as String?)?.trim() ?? '',
          modelNumber: (decoded['modelNumber'] as String?)?.trim() ?? '',
          category: (decoded['category'] as String?)?.trim() ?? '',
        );
      } catch (e) {
        print('Gemini parse failed: $e');
        return ExtractedProductInfo(manufacturer: '', modelNumber: '', category: '');
      }
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class ScannerException implements Exception {
  final String message;
  ScannerException(this.message);
  @override
  String toString() => message;
}

class ExtractedProductInfo {
  final String manufacturer;
  final String modelNumber;
  final String category;

  ExtractedProductInfo({
    required this.manufacturer,
    required this.modelNumber,
    required this.category,
  });

  bool get isEmpty =>
      manufacturer.isEmpty && modelNumber.isEmpty && category.isEmpty;
}
