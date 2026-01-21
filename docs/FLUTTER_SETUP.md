# Flutterセットアップガイド

## Flutterのインストール

### Windows

1. **Flutter SDKをダウンロード**
   - https://flutter.dev/docs/get-started/install/windows
   - ZIPファイルをダウンロードして展開

2. **環境変数に追加**
   - Flutter SDKのパスをPATH環境変数に追加
   - 例: `C:\src\flutter\bin`

3. **確認**
   ```powershell
   flutter doctor
   ```

### 必要なツール

- Git（通常は既にインストール済み）
- Android Studio（既にインストール済み）
- Android SDK

## プロジェクトのセットアップ

### 1. 依存関係のインストール

```powershell
cd C:\Users\81806\Desktop\HomTune
flutter pub get
```

### 2. エミュレータの準備

#### Android Studioでエミュレータを作成

1. Android Studioを開く
2. **Tools > Device Manager**
3. **Create Device** をクリック
4. デバイスを選択（例: Pixel 5）
5. システムイメージを選択（例: API 33）
6. **Finish** でエミュレータを作成

### 3. エミュレータを起動

#### 方法1: Android Studioから

1. Device Managerでエミュレータを起動
2. Cursorのターミナルで `flutter run`

#### 方法2: コマンドラインから

```powershell
# エミュレータを起動
flutter emulators --launch <emulator-id>

# アプリを実行
flutter run
```

## Cursorターミナルからの実行

### 基本的な実行

```powershell
# プロジェクトディレクトリに移動
cd C:\Users\81806\Desktop\HomTune

# 依存関係をインストール（初回のみ）
flutter pub get

# アプリを実行
flutter run
```

### 利用可能なデバイスを確認

```powershell
flutter devices
```

出力例：
```
2 connected devices:

sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64  • Android 13 (API 33)
Chrome (web)                 • chrome        • web-javascript • Google Chrome 120.0.6099.109
```

### 特定のデバイスを指定

```powershell
flutter run -d emulator-5554
```

## 開発時の便利なコマンド

### ホットリロード

アプリ実行中に：
- `r`: ホットリロード（変更を即座に反映）
- `R`: ホットリスタート（アプリを再起動）
- `q`: 終了

### ビルド

```powershell
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle（Google Play用）
flutter build appbundle
```

### クリーンビルド

```powershell
flutter clean
flutter pub get
flutter run
```

## トラブルシューティング

### エラー: "Flutter command not found"

FlutterがPATHに追加されていない可能性があります。

1. Flutter SDKのパスを確認
2. 環境変数に追加
3. PowerShellを再起動

### エラー: "No devices found"

```powershell
# エミュレータを起動
flutter emulators --launch <emulator-id>

# またはAndroid Studioからエミュレータを起動
```

### エラー: "Gradle build failed"

```powershell
cd android
./gradlew clean
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

## 参考リンク

- [Flutter公式ドキュメント](https://flutter.dev/docs)
- [Flutter日本語ドキュメント](https://flutter.dev/docs/get-started/install/windows)
- [Dart公式ドキュメント](https://dart.dev/guides)
