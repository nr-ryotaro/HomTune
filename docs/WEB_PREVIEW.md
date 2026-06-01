# HomTune Web UI プレビュー

友人・関係者に **UI と導線だけ** をブラウザで見せるための手順です。  
スキャン・OCR・カメラ・SQLite キャッシュは **無効** です（モバイルアプリで確認）。

## ローカル確認

```powershell
cd HomTune
flutter pub get
flutter run -d chrome
```

## 本番用ビルド

```powershell
.\scripts\build_web_preview.ps1
```

成果物: `build/web/`

## 公開（Netlify Drop が最速）

1. [Netlify Drop](https://app.netlify.com/drop) を開く
2. `build/web` フォルダをドラッグ＆ドロップ
3. 表示された URL を共有

## 公開（Netlify CLI）

```bash
npm install -g netlify-cli
netlify deploy --prod --dir=build/web
```

## 公開（Firebase Hosting）

```bash
firebase init hosting
# public directory: build/web
firebase deploy --only hosting
```

## Web で触れること

- オンボーディング（住居・部屋・想定家電・スキップ）
- ホーム（部屋カルーセル・メンテバナー・チャット UI）
- 家電の **手入力** 登録
- デバイス詳細・メンテナンス画面

## Web で触れないこと

- Smart Ingester（バーコード / 型番スキャン）
- ML Kit OCR
- 機材写真のカメラ撮影
- 実 API キーをクライアントに埋め込んだ Gemini 連携（公開ビルドでは非推奨）

## 注意

- データは **各ブラウザのローカル** にのみ保存されます
- 初回ロードは数十秒かかることがあります（PC の Chrome 推奨）
