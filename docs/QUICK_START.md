# HomTune クイックスタートガイド

## 最短でモバイルアプリを起動する

### 1. 依存関係のインストール

```bash
npm install
```

### 2. Webアプリのビルド

```bash
npm run build
```

### 3. Capacitorプラットフォームの追加（初回のみ）

```bash
# Android
npx cap add android

# iOS（macOSのみ）
npx cap add ios
```

### 4. ネイティブコードの同期

```bash
npx cap sync
```

### 5. 開発環境で開く

```bash
# Android Studio
npx cap open android

# Xcode（macOSのみ）
npx cap open ios
```

### 6. 実行

- **Android**: Android Studioからエミュレータまたは実機で実行
- **iOS**: Xcodeからシミュレータまたは実機で実行

## 開発時のワークフロー

### Webアプリの開発

```bash
# 開発サーバー起動
npm run dev
```

ブラウザで `http://localhost:5173` を開いて開発・テスト

### 変更をネイティブアプリに反映

```bash
# 1. ビルド
npm run build

# 2. 同期
npx cap sync

# 3. ネイティブIDEで再実行
```

## トラブルシューティング

### エラー: "Capacitor not found"

```bash
npm install
npx cap sync
```

### エラー: プラットフォームが見つからない

```bash
npx cap add android
npx cap add ios
npx cap sync
```

### 変更が反映されない

```bash
# クリーンビルド
rm -rf dist
npm run build
npx cap sync
```

## 次のステップ

- [モバイルアプリセットアップガイド](mobile-app-setup.md) で詳細を確認
- [アーキテクチャ設計](architecture.md) で全体像を把握
