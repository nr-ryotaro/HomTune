# HomTune Flutter版

## プロジェクト概要

HomTuneをFlutter（Dart）で実装したモバイルアプリです。

## 技術スタック

- **フレームワーク**: Flutter 3.x
- **言語**: Dart 3.0+
- **状態管理**: Provider
- **プラットフォーム**: Android / iOS

## セットアップ

### 1. Flutterのインストール確認

```powershell
flutter --version
```

Flutterがインストールされていない場合：
- https://flutter.dev/docs/get-started/install/windows からインストール

### 2. 依存関係のインストール

```powershell
flutter pub get
```

### 3. エミュレータ/デバイスの確認

```powershell
flutter devices
```

### 4. アプリの実行

#### Androidエミュレータで実行

```powershell
# エミュレータを起動（Android Studioから起動するか）
flutter run
```

#### 特定のデバイスを指定

```powershell
flutter devices  # 利用可能なデバイスを確認
flutter run -d <device-id>
```

## 開発ワークフロー

### ホットリロード

アプリ実行中に：
- `r` キー: ホットリロード
- `R` キー: ホットリスタート
- `q` キー: 終了

### ビルド

```powershell
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS（macOSのみ）
flutter build ios
```

## プロジェクト構造

```
lib/
├── main.dart              # アプリエントリーポイント
├── models/                # データモデル
│   ├── device.dart
│   └── room.dart
├── screens/               # 画面
│   └── home_screen.dart
├── widgets/              # ウィジェット
│   ├── device_card.dart
│   ├── floor_plan_widget.dart
│   └── summary_card.dart
└── services/              # サービス
    └── device_service.dart
```

## Android Studioでの実行

1. Android Studioを開く
2. 「Open」でプロジェクトを開く
3. エミュレータを起動
4. 「Run」ボタン（▶）をクリック

または、Cursorのターミナルから：

```powershell
flutter run
```

## トラブルシューティング

### Flutterがインストールされていない

```powershell
# Flutterをインストール
# https://flutter.dev/docs/get-started/install/windows
```

### エミュレータが見つからない

```powershell
# Android Studioでエミュレータを作成
# Tools > Device Manager > Create Device
```

### ビルドエラー

```powershell
flutter clean
flutter pub get
flutter run
```
