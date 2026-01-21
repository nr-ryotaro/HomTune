# モバイルアプリセットアップガイド

## 概要

HomTuneはCapacitorを使用してAndroid/iOSネイティブアプリとして動作します。既存のWeb技術（HTML/CSS/JavaScript）を活用しつつ、ネイティブ機能にアクセスできます。

## 必要な環境

### Android開発
- Node.js 18以上
- Java JDK 11以上
- Android Studio
- Android SDK

### iOS開発（macOSのみ）
- Node.js 18以上
- Xcode 14以上
- CocoaPods

## セットアップ手順

### 1. 依存関係のインストール

```bash
npm install
```

### 2. Webアプリのビルド

```bash
npm run build
```

### 3. Capacitorの初期化（初回のみ）

```bash
# Androidプラットフォームを追加
npm run cap:add android

# iOSプラットフォームを追加（macOSのみ）
npm run cap:add ios
```

### 4. ネイティブコードの同期

```bash
npm run cap:sync
```

このコマンドは、Webアプリのビルド成果物をネイティブプロジェクトにコピーします。

## 開発ワークフロー

### Android開発

1. Webアプリをビルド
   ```bash
   npm run build
   ```

2. Capacitorで同期
   ```bash
   npm run cap:sync
   ```

3. Android Studioで開く
   ```bash
   npm run cap:open:android
   ```

4. Android Studioからエミュレータまたは実機で実行

### iOS開発（macOSのみ）

1. Webアプリをビルド
   ```bash
   npm run build
   ```

2. Capacitorで同期
   ```bash
   npm run cap:sync
   ```

3. Xcodeで開く
   ```bash
   npm run cap:open:ios
   ```

4. Xcodeからシミュレータまたは実機で実行

### 一括コマンド

```bash
# Android: ビルド + 同期 + Android Studio起動
npm run cap:build:android

# iOS: ビルド + 同期 + Xcode起動
npm run cap:build:ios
```

## ネイティブ機能

### 利用可能な機能

- **カメラ**: デバイスの写真撮影（`CapacitorService.takePicture()`）
- **フォトライブラリ**: 画像の選択（`CapacitorService.pickFromGallery()`）
- **ファイルシステム**: ファイルの保存・読み込み
- **ストレージ**: キー・バリューストレージ（`CapacitorService.setPreference()`）
- **ステータスバー**: ステータスバーの制御
- **スプラッシュスクリーン**: 起動画面の制御

### 使用例

```javascript
import { CapacitorService } from './js/capacitor.js';

// 写真を撮影
const image = await CapacitorService.takePicture();

// データを保存
await CapacitorService.setPreference('devices', JSON.stringify(devices));

// データを読み込み
const devices = await CapacitorService.getPreference('devices');
```

## プラットフォーム固有の設定

### Android

- **設定ファイル**: `android/app/src/main/AndroidManifest.xml`
- **アプリID**: `capacitor.config.ts`の`appId`で設定
- **権限**: `AndroidManifest.xml`でカメラ等の権限を設定

### iOS

- **設定ファイル**: `ios/App/App/Info.plist`
- **アプリID**: Xcodeのプロジェクト設定で設定
- **権限**: `Info.plist`でカメラ等の権限を設定

## デバッグ

### Webビューでのデバッグ

#### Android
1. Chromeで `chrome://inspect` を開く
2. デバイスを接続
3. アプリのWebViewを選択

#### iOS
1. Safariの開発メニューを有効化
2. デバイスを接続
3. Safari > 開発 > [デバイス名] > [アプリ名] を選択

### ログの確認

```bash
# Android
adb logcat | grep "Capacitor"

# iOS
# Xcodeのコンソールで確認
```

## ビルドとリリース

### Android APK/AABのビルド

```bash
cd android
./gradlew assembleRelease
```

### iOSアーカイブ

1. Xcodeで開く
2. Product > Archive
3. App Store Connectにアップロード

## トラブルシューティング

### 同期がうまくいかない場合

```bash
# クリーンビルド
rm -rf android ios
npm run cap:add android
npm run cap:add ios
npm run cap:sync
```

### プラグインが動作しない場合

```bash
# プラグインを再インストール
npm install
npm run cap:sync
```

### パーミッションエラー

- Android: `AndroidManifest.xml`で権限を確認
- iOS: `Info.plist`で権限を確認

## 参考リンク

- [Capacitor公式ドキュメント](https://capacitorjs.com/docs)
- [Capacitor GitHub](https://github.com/ionic-team/capacitor)
