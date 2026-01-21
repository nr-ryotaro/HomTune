import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;

/// PDF生成サービス
/// 複数の画像から1つのPDFを生成
class PdfGenerationService {
  static final PdfGenerationService _instance = PdfGenerationService._internal();
  factory PdfGenerationService() => _instance;
  PdfGenerationService._internal();

  /// 複数の画像からPDFを生成
  /// 
  /// [images] 画像ファイルのリスト
  /// 戻り値: PDFファイルのバイトデータ
  Future<Uint8List> generatePdfFromImages(List<File> images) async {
    if (images.isEmpty) {
      throw Exception('画像が選択されていません');
    }

    final pdf = pw.Document();
    const a4PageSize = PdfPageFormat.a4;
    final pageWidth = a4PageSize.width;
    final pageHeight = a4PageSize.height;
    int pagesAdded = 0;

    for (final imageFile in images) {
      try {
        // 画像を読み込み
        final imageBytes = await imageFile.readAsBytes();
        final image = img.decodeImage(imageBytes);

        if (image == null) {
          print('Warning: Failed to decode image ${imageFile.path}');
          continue;
        }

        // 画像をPDF用に変換
        final pdfImage = pw.MemoryImage(imageBytes);

        // 画像のアスペクト比を計算
        final imageAspectRatio = image.width / image.height;
        final pageAspectRatio = pageWidth / pageHeight;

        // ページサイズに合わせて画像サイズを計算（余白を考慮）
        double imageWidth;
        double imageHeight;
        const margin = 20.0;

        if (imageAspectRatio > pageAspectRatio) {
          // 横長の画像
          imageWidth = pageWidth - (margin * 2);
          imageHeight = imageWidth / imageAspectRatio;
        } else {
          // 縦長の画像
          imageHeight = pageHeight - (margin * 2);
          imageWidth = imageHeight * imageAspectRatio;
        }

        // PDFページに画像を追加
        pdf.addPage(
          pw.Page(
            pageFormat: a4PageSize,
            margin: const pw.EdgeInsets.all(margin),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(
                  pdfImage,
                  width: imageWidth,
                  height: imageHeight,
                  fit: pw.BoxFit.contain,
                ),
              );
            },
          ),
        );
        pagesAdded++;
      } catch (e) {
        print('Error processing image ${imageFile.path}: $e');
        // エラーが発生した画像はスキップして続行
        continue;
      }
    }

    // 有効なページが追加されたか確認
    if (pagesAdded == 0) {
      throw Exception('有効な画像がありませんでした');
    }

    // PDFをバイトデータに変換
    return pdf.save();
  }
}
