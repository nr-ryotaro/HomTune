# Smart Ingester セットアップ

Smart Ingester（バーコード＋製品プレート撮影で家電登録）の利用に必要な設定です。

## 1. Gemini API キー

OCR で得たテキストから「メーカー・型番・カテゴリ」を抽出するために **Gemini 2.0 Flash** を使用します。

- [Google AI Studio](https://aistudio.google.com/) で API キーを取得
- ビルド時に `--dart-define` で渡す:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
```

iOS 実機などでは Xcode の Scheme に `GEMINI_API_KEY` を User-Defined で追加するか、環境変数で渡してください。

## 2. iOS 15.5+ 向け

`ios/Runner/Info.plist` にカメラ利用の説明を追加します:

```xml
<key>NSCameraUsageDescription</key>
<string>バーコードおよび製品プレートの撮影にカメラを使用します。</string>
```

`mobile_scanner` 利用のため必須です。

## 3. 依存パッケージ

- `mobile_scanner` … バーコードスキャン
- `google_mlkit_text_recognition` … OCR（ML Kit）
- `google_generative_ai` … Gemini 構造化抽出
- `sqflite` … 説明書検索結果のキャッシュ

## 4. 機能概要

| 機能 | 説明 |
|------|------|
| **バーコード** | JAN 読み取り → 製品取得フローへ（現状は手入力案内） |
| **プレート撮影** | シャッターで撮影 → ML Kit OCR → Gemini で構造化 → 登録 or 手入力 |
| **説明書検索** | 登録後バックグラウンドでメーカー＋型番から URL 検索し、`manualUrl` に保存 |
| **キャッシュ** | 検索結果を SQLite に保存し API 呼び出しを削減 |

## 5. 手入力へのフォールバック

- 型番が特定できない場合
- ネットワークエラー時
- API キー未設定時

上記のときは「手入力で登録」を案内し、`AddDeviceScreen` に遷移します。
