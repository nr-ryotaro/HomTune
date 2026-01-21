# 🚀 HomTune Flutter版 - 実行方法

## Cursorターミナルから実行する方法

### 前提条件

✅ Flutter SDKがインストール済み（確認済み）
✅ Android Studioがインストール済み
✅ エミュレータが作成済み（Pixel 5、Medium Phone API 36.1）

## 実行手順

### 方法1: 実行スクリプトを使用（推奨）

```powershell
.\run.ps1
```

このスクリプトが以下を自動実行します：
1. Flutterのバージョン確認
2. 依存関係のインストール
3. 利用可能なデバイスの確認
4. アプリの実行

### 方法2: 手動で実行

#### ステップ1: エミュレータを起動

**Android Studioから:**
1. Android Studioを開く
2. **Tools > Device Manager**
3. エミュレータを選択（例: Pixel 5）
4. **▶** ボタンをクリックして起動
5. エミュレータが完全に起動するまで待つ（ホーム画面が表示される）

**または、コマンドラインから:**
```powershell
flutter emulators --launch Pixel_5
```

#### ステップ2: アプリを実行

Cursorのターミナルで：

```powershell
flutter run
```

## 実行中の操作

アプリが実行されると、以下のキーで操作できます：

- **`r`**: ホットリロード（コード変更を即座に反映）
- **`R`**: ホットリスタート（アプリを再起動）
- **`q`**: 終了

## 確認できる機能

✅ **間取り図**: 各部屋にデバイス数バッジが表示されます

✅ **部屋タップ**: 間取り図の部屋をタップすると、その部屋のデバイスのみが表示されます

✅ **デバイス一覧**: 3つのサンプルデバイスが表示されます

✅ **サマリーカード**: 警告数、メンテナンス予定、登録デバイス数が表示されます

## トラブルシューティング

### エラー: "No devices found"

エミュレータを起動してください：

```powershell
# Android Studioから起動するか
flutter emulators --launch Pixel_5
```

### エラー: "Gradle build failed"

```powershell
cd android
.\gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### エラー: "SDK location not found"

`android/local.properties` ファイルを作成：

```properties
sdk.dir=C:\\Users\\81806\\AppData\\Local\\Android\\Sdk
```

## 詳細情報

- [Flutter実行ガイド](docs/FLUTTER_EXECUTION.md)
- [Android Studioエミュレータガイド](docs/ANDROID_STUDIO_EMULATOR.md)
- [Flutterセットアップガイド](docs/FLUTTER_SETUP.md)
