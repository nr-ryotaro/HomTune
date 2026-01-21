# Flutterアプリ実行ガイド（Cursorターミナルから）

## 前提条件

- Flutter SDKがインストールされている
- Android Studioがインストールされている（既にインストール済み）
- エミュレータが作成されている

## Cursorターミナルからの実行手順

### 方法1: 実行スクリプトを使用（推奨）

```powershell
.\run.ps1
```

このスクリプトは以下を自動実行します：
1. Flutterのバージョン確認
2. 依存関係のインストール
3. 利用可能なデバイスの確認
4. アプリの実行

### 方法2: 手動で実行

#### ステップ1: Flutterの確認

```powershell
flutter --version
```

#### ステップ2: 依存関係のインストール

```powershell
flutter pub get
```

#### ステップ3: エミュレータを起動

**Android Studioから:**
1. Android Studioを開く
2. **Tools > Device Manager**
3. エミュレータを選択して起動（▶ボタン）

または、コマンドラインから：

```powershell
# 利用可能なエミュレータを確認
flutter emulators

# エミュレータを起動
flutter emulators --launch <emulator-id>
```

#### ステップ4: アプリを実行

```powershell
flutter run
```

## 実行中の操作

アプリが実行されると、以下のキーで操作できます：

- **`r`**: ホットリロード（変更を即座に反映）
- **`R`**: ホットリスタート（アプリを再起動）
- **`q`**: 終了
- **`h`**: ヘルプを表示

## 利用可能なデバイスを確認

```powershell
flutter devices
```

出力例：
```
2 connected devices:

sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64  • Android 13 (API 33)
Chrome (web)                 • chrome        • web-javascript • Google Chrome 120.0.6099.109
```

## 特定のデバイスを指定

```powershell
flutter run -d emulator-5554
```

## トラブルシューティング

### エラー: "Flutter command not found"

FlutterがPATHに追加されていません。

1. Flutter SDKのパスを確認
2. 環境変数に追加
3. PowerShellを再起動

### エラー: "No devices found"

エミュレータを起動してください：

```powershell
# Android Studioから起動するか
flutter emulators --launch <emulator-id>
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
sdk.dir=C:\\Users\\<ユーザー名>\\AppData\\Local\\Android\\Sdk
```

## 開発ワークフロー

### 1. コードを編集

`lib/` ディレクトリ内のファイルを編集

### 2. ホットリロード

アプリ実行中に `r` キーを押すと、変更が即座に反映されます

### 3. エミュレータで確認

タップ操作やUIの動作をエミュレータで確認

## ビルド

### Debug APK

```powershell
flutter build apk --debug
```

### Release APK

```powershell
flutter build apk --release
```

APKファイルは `build/app/outputs/flutter-apk/` に生成されます。
