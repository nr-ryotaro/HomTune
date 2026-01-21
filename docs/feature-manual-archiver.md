# ハイブリッド・マニュアル・アーカイブ機能

## 概要

公式サイトでPDFが見つからない場合や、手元に独自の資料がある場合に、以下の2つの経路でマニュアルを機材データに紐づけられる機能。

1. **画像からの生成**: 複数枚の写真を撮影・選択し、1つのPDFに統合して登録
2. **PDF直接登録**: 既存のPDFファイルを直接アップロードして登録

## アーキテクチャ

### データモデル

#### Manual クラス拡張
`lib/models/device.dart`の`Manual`クラスに以下を追加：

- `source`: マニュアルのソース
  - `'official'`: 公式サイトから取得
  - `'scanned'`: スキャンして生成
  - `'uploaded'`: アップロード

- `url`: 外部URLまたはローカルファイルパス
  - 外部URL: `https://example.com/manual.pdf`
  - ローカルファイル: `file:///path/to/manual.pdf`

### サービス層

#### PdfGenerationService
`lib/services/pdf_generation_service.dart`

- `generatePdfFromImages(List<File> images)`: 複数画像からPDFを生成
- A4サイズに最適化
- 画像のアスペクト比を維持

#### ManualService 拡張
`lib/services/manual_service.dart`に以下を追加：

- `saveLocalManual(File pdfFile, String deviceId, String deviceName, String modelNumber)`: ローカルPDFを保存
- `generatePdfFromImages(List<File> images, ...)`: 画像からPDFを生成して保存
- `getManualFile(String manualUrl)`: URLまたはローカルパスからFileを取得

## UI/UX設計

### 登録導線

#### 1. デバイス詳細画面
- 説明書ボタンをタップ
- マニュアル未登録の場合 → 登録画面へ遷移
- マニュアル登録済みの場合 → PDFビューアーを表示

#### 2. デバイス登録フロー
- 「マニュアル設定」セクションを追加
- 登録済みマニュアルのプレビュー表示
- 「マニュアルを登録」ボタンから登録画面へ

### マニュアル登録画面

#### 選択画面
- [A] スキャンして作成: カメラで撮影
- [B] ファイルを選択: PDFをインポート

#### スキャンフロー
1. 撮影/ギャラリー選択ボタン
2. 画像サムネイル一覧（順序番号表示）
3. 削除ボタン（各画像）
4. 追加ボタン
5. PDF生成ボタン

#### アップロードフロー
1. ファイル選択ボタン
2. 選択されたPDFのプレビュー
3. 保存ボタン

## 技術的詳細

### PDF生成ロジック

```dart
// 各画像をPDFページとして配置
for (final imageFile in images) {
  final imageBytes = await imageFile.readAsBytes();
  final pdfImage = pw.MemoryImage(imageBytes);
  
  // A4サイズに最適化（余白20ポイント）
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Image(
            pdfImage,
            fit: pw.BoxFit.contain,
          ),
        );
      },
    ),
  );
}
```

### ファイルパス形式

- **ローカルファイル**: `file:///path/to/manual.pdf`
- **外部URL**: `https://example.com/manual.pdf`

`Manual.isLocalFile`プロパティで判別可能。

### ストレージ

- 保存先: `{アプリドキュメント}/manuals/manual_{型番}.pdf`
- ファイル名: `manual_{型番（特殊文字を_に置換）}.pdf`

## エラーハンドリング

- 画像読み込み失敗: エラー画像をスキップして続行
- PDF生成失敗: エラーメッセージを表示
- ファイル保存失敗: エラーメッセージを表示
- ユーザーフレンドリーなメッセージ:
  - 処理中: "調律されたPDFを生成中..." / "記録を同期中..."
  - 完了: "あなたの機材知識がアーカイブされました"

## 使用パッケージ

- `pdf: ^3.11.3` - PDF生成
- `file_picker: ^8.1.2` - PDFファイル選択
- `image: ^4.3.0` - 画像処理
- `image_picker: ^1.0.5` - カメラ/ギャラリー（既存）

## 将来の拡張

- 画像の自動トリミング・コントラスト調整
- OCR機能による自動テキスト抽出
- マニュアルのバージョン管理
- クラウドストレージへの同期
