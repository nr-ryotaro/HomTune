# HomTune 起動ガイド

## クイックスタート

### 方法1: Webブラウザで起動（推奨：開発・テスト用）

最も簡単にアプリを起動する方法です。

#### 1. 依存関係のインストール

```bash
npm install
```

#### 2. 開発サーバーを起動

```bash
npm run dev
```

ブラウザが自動的に開き、`http://localhost:5173` でアプリが表示されます。

#### 3. 機能確認

- デバイス一覧が表示される
- 間取り図が表示される
- サマリーカード（警告数、メンテナンス予定、登録デバイス数）が表示される

---

### 方法2: モバイルアプリとして起動（Android）

#### 必要な環境

- Node.js 18以上
- Java JDK 11以上
- Android Studio
- Android SDK

#### 手順

##### 1. 依存関係のインストール

```bash
npm install
```

##### 2. Webアプリをビルド

```bash
npm run build
```

##### 3. Capacitorプラットフォームを追加（初回のみ）

```bash
npx cap add android
```

##### 4. ネイティブコードを同期

```bash
npx cap sync
```

##### 5. Android Studioで開く

```bash
npx cap open android
```

##### 6. Android Studioで実行

- エミュレータを起動するか、実機を接続
- 実行ボタン（▶）をクリック

---

### 方法3: モバイルアプリとして起動（iOS - macOSのみ）

#### 必要な環境

- macOS
- Node.js 18以上
- Xcode 14以上
- CocoaPods

#### 手順

##### 1. 依存関係のインストール

```bash
npm install
```

##### 2. Webアプリをビルド

```bash
npm run build
```

##### 3. Capacitorプラットフォームを追加（初回のみ）

```bash
npx cap add ios
```

##### 4. CocoaPodsの依存関係をインストール

```bash
cd ios/App
pod install
cd ../..
```

##### 5. ネイティブコードを同期

```bash
npx cap sync
```

##### 6. Xcodeで開く

```bash
npx cap open ios
```

##### 7. Xcodeで実行

- シミュレータを選択するか、実機を接続
- 実行ボタン（▶）をクリック

---

## 一括コマンド

### Android

```bash
# ビルド + 同期 + Android Studio起動
npm run cap:build:android
```

### iOS

```bash
# ビルド + 同期 + Xcode起動
npm run cap:build:ios
```

---

## トラブルシューティング

### Webブラウザで起動できない場合

#### エラー: "Cannot find module '@capacitor/core'"

```bash
npm install
```

#### エラー: "Failed to load mock-data.json"

`public/mock-data.json` が存在するか確認：

```bash
# Windows (PowerShell)
Test-Path public\mock-data.json

# macOS/Linux
ls public/mock-data.json
```

存在しない場合：

```bash
# Windows (PowerShell)
Copy-Item data\mock-data.json public\mock-data.json

# macOS/Linux
cp data/mock-data.json public/mock-data.json
```

#### ポート5173が使用中

別のポートを使用：

```bash
# vite.config.jsのserver.portを変更するか
npm run dev -- --port 3000
```

---

### モバイルアプリで起動できない場合

#### エラー: "Capacitor not found"

```bash
npm install
npx cap sync
```

#### エラー: プラットフォームが見つからない

```bash
# Android
npx cap add android
npx cap sync

# iOS
npx cap add ios
cd ios/App && pod install && cd ../..
npx cap sync
```

#### 変更が反映されない

```bash
# クリーンビルド
rm -rf dist
npm run build
npx cap sync
```

#### Android Studioでビルドエラー

1. Android Studioで `File > Invalidate Caches / Restart` を実行
2. `Build > Clean Project` を実行
3. `Build > Rebuild Project` を実行

#### Xcodeでビルドエラー

1. `Product > Clean Build Folder` (Shift + Cmd + K)
2. `ios/App` ディレクトリで `pod install` を再実行
3. Xcodeを再起動

---

## 開発時の推奨ワークフロー

### 1. Webブラウザで開発・テスト

```bash
npm run dev
```

- 高速なホットリロード
- ブラウザの開発者ツールでデバッグ
- モバイルビューでレスポンシブデザインを確認

### 2. 変更をモバイルアプリに反映

```bash
# ビルド
npm run build

# 同期
npx cap sync

# ネイティブIDEで再実行
```

---

## 次のステップ

- [アーキテクチャ設計](architecture.md) で全体像を把握
- [モバイルアプリセットアップガイド](mobile-app-setup.md) で詳細を確認
- [クイックスタートガイド](QUICK_START.md) で基本操作を確認
