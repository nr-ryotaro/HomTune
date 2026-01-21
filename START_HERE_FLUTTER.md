# 🚀 HomTune Flutter版 - 起動ガイド

## クイックスタート

### ステップ1: Flutterの確認

```powershell
flutter --version
```

✅ Flutterがインストールされていることを確認

### ステップ2: 依存関係のインストール（初回のみ）

```powershell
flutter pub get
```

✅ 依存関係のインストールが完了

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

## 実行中の操作

アプリ実行中に：
- **`r`**: ホットリロード（変更を即座に反映）
- **`R`**: ホットリスタート
- **`q`**: 終了

## 確認できる機能

✅ **間取り図**: 各部屋にデバイス数バッジが表示

✅ **部屋タップ**: 間取り図の部屋をタップすると、その部屋のデバイスのみ表示

✅ **デバイス一覧**: 3つのサンプルデバイスが表示

✅ **サマリーカード**: 警告数、メンテナンス予定、登録デバイス数が表示

## トラブルシューティング

### エミュレータが見つからない

```powershell
# エミュレータを確認
flutter devices

# エミュレータを起動（Android Studioから）
```

### ビルドエラー

```powershell
flutter clean
flutter pub get
flutter run
```

## 詳細情報

- [Flutter実行ガイド](docs/FLUTTER_EXECUTION.md)
- [Flutterセットアップガイド](docs/FLUTTER_SETUP.md)
- [README Flutter版](README_FLUTTER.md)
