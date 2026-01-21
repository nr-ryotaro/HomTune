# 🚀 HomTune Flutter版 - クイックスタート

## 前提条件

- Flutter SDKがインストールされていること
- Android Studioがインストールされていること（既にインストール済み）

## 最短で起動する方法

### ステップ1: Flutterの確認

```powershell
flutter --version
```

エラーが出る場合 → [Flutterセットアップガイド](docs/FLUTTER_SETUP.md) を参照

### ステップ2: 依存関係のインストール

```powershell
flutter pub get
```

### ステップ3: エミュレータを起動

**Android Studioから:**
1. Android Studioを開く
2. **Tools > Device Manager**
3. エミュレータを選択して起動（▶ボタン）

### ステップ4: アプリを実行

```powershell
flutter run
```

または、実行スクリプトを使用：

```powershell
.\run.ps1
```

## 確認できる機能

✅ **間取り図**: 各部屋にデバイス数バッジが表示されます

✅ **部屋タップ**: 間取り図の部屋をタップすると、その部屋のデバイスのみが表示されます

✅ **デバイス一覧**: 3つのサンプルデバイスが表示されます

✅ **サマリーカード**: 警告数、メンテナンス予定、登録デバイス数が表示されます

## 開発時の便利なコマンド

### ホットリロード

アプリ実行中に：
- `r` キー: ホットリロード
- `R` キー: ホットリスタート
- `q` キー: 終了

### 利用可能なデバイスを確認

```powershell
flutter devices
```

### 特定のデバイスを指定

```powershell
flutter run -d <device-id>
```

## トラブルシューティング

### Flutterがインストールされていない

[Flutterセットアップガイド](docs/FLUTTER_SETUP.md) を参照

### エミュレータが見つからない

Android Studioでエミュレータを作成：
1. **Tools > Device Manager**
2. **Create Device**
3. デバイスとシステムイメージを選択

### ビルドエラー

```powershell
flutter clean
flutter pub get
flutter run
```

## 詳細情報

- [Flutterセットアップガイド](docs/FLUTTER_SETUP.md)
- [README Flutter版](README_FLUTTER.md)
