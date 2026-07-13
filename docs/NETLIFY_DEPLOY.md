# Netlify デプロイ手順（現状版）

HomTune の **Web UI プレビュー** を Netlify に公開する手順です。  
モバイル向けフル機能ではなく、UI・導線の共有用ビルドです。

## 前提

- Windows + PowerShell
- Flutter SDK 3.x（`flutter doctor` が通ること）
- 本番 API キー・Remo トークンは **ビルドに含めない**

## 1. ビルド（必須）

```powershell
cd HomTune
.\scripts\build_web_preview.ps1
```

### 成果物

| パス | 用途 |
|------|------|
| `build/web/` | Netlify にアップロードするフォルダ |
| `dist/homtune-web-deploy.zip` | Drop 用 zip（中身は `build/web` と同じ） |
| `build/web/deploy-meta.json` | バージョン・ビルド日時の確認用 |
| `build/web/_redirects` | SPA ルーティング（深い URL 対応） |
| `build/web/_headers` | MIME / キャッシュ / セキュリティヘッダ |

## 2. デプロイ方法

### A. Netlify Drop（最速・推奨）

1. [Netlify Drop](https://app.netlify.com/drop) を開く
2. **`build/web` フォルダ全体** または **`dist/homtune-web-deploy.zip`** をドラッグ
3. 表示された URL を共有

> **注意:** リポジトリ直下の `web/` だけをアップロードすると **白画面** になります（`main.dart.js` が無いため）。

### B. Netlify CLI

```powershell
npm install -g netlify-cli
netlify login
.\scripts\deploy_netlify.ps1
```

ドラフト確認のみ:

```powershell
.\scripts\deploy_netlify.ps1 -Draft
```

### C. 既存サイトへ手動アップロード

Netlify ダッシュボード → **Deploys** → フォルダ / zip をドラッグ。

## 3. デプロイ後チェックリスト

| 確認 | URL / 操作 |
|------|------------|
| トップ表示 | `https://<site>.netlify.app/` |
| JS 配信 | `https://<site>.netlify.app/main.dart.js` が 404 でない |
| バージョン | `https://<site>.netlify.app/deploy-meta.json` |
| 深いリンク | `https://<site>.netlify.app/` 以外のパスでもリロードで表示される |
| オンボーディング | 初回起動フローが表示される |
| ホーム | 部屋カルーセル・メンテ UI |

## 4. 現状版で Web から触れるもの

- オンボーディング（住居・部屋・スキップ）
- ホーム・家電手入力登録
- デバイス詳細・メンテナンス画面
- **リモコン UI**（メーカー別テンプレート・カスタマイズ含む・API 送信なし）

### リモコンの見方

| 場所 | 内容 |
|------|------|
| ホーム右上のリモコンアイコン | 全シナリオ比較プレビュー（エアコン / TV 等） |
| `/remote-control-preview` | 上記と同じ（直リンク可） |
| 家電詳細（エアコン・テレビ等） | 型番に応じたテンプレート UI |

## 5. Web で無効なもの

- Smart Ingester（バーコード / 型番スキャン）
- ML Kit OCR・カメラ
- Nature Remo / SwitchBot の実 API 連携
- クライアント埋め込み Gemini キー（公開ビルド非推奨）

## 6. 設定ファイル

| ファイル | 役割 |
|----------|------|
| [`netlify.toml`](../netlify.toml) | Git 連携サイト用（redirects / headers） |
| [`web/_redirects`](../web/_redirects) | Drop 用 SPA ルーティング |
| [`web/_headers`](../web/_headers) | Drop 用 HTTP ヘッダ |

Flutter は Netlify 標準ビルドイメージに含まれないため、**ローカルで `build/web` を生成してアップロード**する運用を推奨します。

## 7. トラブルシュート

| 症状 | 対処 |
|------|------|
| 白画面 | `build/web` をアップロードしたか確認。`main.dart.js` の URL を開く |
| リロードで 404 | `_redirects` が zip に含まれているか確認。ビルドスクリプトを再実行 |
| 読み込みが終わらない | PC Chrome 推奨。初回は数十秒かかることがある |
| 古い UI が見える | Netlify のキャッシュをクリア、または新しい Deploy を作成 |

## 関連

- [WEB_PREVIEW.md](WEB_PREVIEW.md)
- [REMOTE_CONTROL.md](REMOTE_CONTROL.md)（リモコン UI は Web では表示のみ）
