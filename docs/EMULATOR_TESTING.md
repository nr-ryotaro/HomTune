# エミュレータでのテストガイド

## Capacitorアプリのエミュレータテスト

Capacitorアプリは、Android StudioやXcodeのエミュレータで完全にテスト可能です。

## Androidエミュレータでのテスト

### 前提条件

- Android Studioがインストールされている
- Android SDKが設定されている
- エミュレータが作成されている

### 手順

#### 1. Webアプリをビルド

```powershell
npm run build
```

#### 2. Capacitorで同期

```powershell
npx cap sync
```

#### 3. Android Studioで開く

```powershell
npx cap open android
```

#### 4. エミュレータを起動

1. Android Studioで「Device Manager」を開く
2. エミュレータを選択して起動（▶ボタン）
3. エミュレータが起動するまで待つ（数分かかる場合あり）

#### 5. アプリを実行

1. Android Studioのツールバーでエミュレータを選択
2. 「Run」ボタン（▶）をクリック
3. アプリがエミュレータにインストールされ、自動的に起動

### テスト項目

- ✅ 間取り図の表示
- ✅ 部屋のタップ機能
- ✅ デバイス数のバッジ表示
- ✅ フィルタリング機能
- ✅ デバイス一覧の表示
- ✅ タッチ操作の反応

## iOSシミュレータでのテスト（macOSのみ）

### 前提条件

- macOS
- Xcodeがインストールされている
- CocoaPodsがインストールされている

### 手順

#### 1. Webアプリをビルド

```powershell
npm run build
```

#### 2. CocoaPodsの依存関係をインストール

```powershell
cd ios/App
pod install
cd ../..
```

#### 3. Capacitorで同期

```powershell
npx cap sync
```

#### 4. Xcodeで開く

```powershell
npx cap open ios
```

#### 5. シミュレータを選択

1. Xcodeのツールバーでシミュレータを選択（例: iPhone 15 Pro）
2. 「Run」ボタン（▶）をクリック
3. シミュレータが起動し、アプリが自動的にインストール・起動

### テスト項目

- ✅ 間取り図の表示
- ✅ 部屋のタップ機能
- ✅ デバイス数のバッジ表示
- ✅ フィルタリング機能
- ✅ デバイス一覧の表示
- ✅ タッチ操作の反応

## デバッグ方法

### Android

1. **Chrome DevToolsを使用**
   - Chromeで `chrome://inspect` を開く
   - エミュレータでアプリを起動
   - 「inspect」をクリックしてデバッグ

2. **Logcatでログを確認**
   ```powershell
   adb logcat | grep "Capacitor"
   ```

### iOS

1. **Safari Web Inspectorを使用**
   - Safari > 環境設定 > 詳細 > 「メニューバーに"開発"メニューを表示」を有効化
   - シミュレータでアプリを起動
   - Safari > 開発 > [シミュレータ名] > [アプリ名] を選択

2. **Xcodeコンソールでログを確認**
   - Xcodeの下部にあるコンソールパネルでログを確認

## ホットリロード（開発中）

開発中は、Webブラウザで開発してからエミュレータで確認するワークフローが効率的です：

1. **Webブラウザで開発**
   ```powershell
   npm run dev
   ```
   - 高速なホットリロード
   - ブラウザの開発者ツールでデバッグ

2. **変更をエミュレータに反映**
   ```powershell
   npm run build
   npx cap sync
   ```
   - Android Studio/Xcodeで再実行

## トラブルシューティング

### エミュレータが起動しない

- Android Studio/Xcodeを再起動
- エミュレータの設定を確認
- システム要件を確認（RAM、ディスク容量）

### アプリがエミュレータに表示されない

- `npx cap sync` を再実行
- Android Studio/Xcodeで「Clean Build」を実行
- エミュレータを再起動

### 変更が反映されない

```powershell
# クリーンビルド
rm -rf dist
npm run build
npx cap sync
```

## 実機でのテスト

エミュレータでのテストが完了したら、実機でもテスト：

### Android

1. USBデバッグを有効化
2. デバイスを接続
3. Android Studioでデバイスを選択して実行

### iOS

1. XcodeでApple Developerアカウントを設定
2. デバイスを接続
3. Xcodeでデバイスを選択して実行
