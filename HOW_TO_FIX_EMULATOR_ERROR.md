# エミュレータエラーの修正方法

## エラー内容

```
No supported devices connected.
The following devices were found, but are not supported by this project:
Windows (desktop) • windows • windows-x64
Chrome (web) • chrome • web-javascript
Edge (web) • edge • web-javascript
```

## 原因

**Androidエミュレータが起動していない**ことが原因です。

## 解決手順

### ✅ ステップ1: Androidプラットフォームのサポートを追加（完了済み）

```powershell
flutter create . --platforms=android
```

### ✅ ステップ2: エミュレータを起動

#### 方法A: Android Studioから起動（推奨）

1. **Android Studioを開く**
2. **Tools > Device Manager** をクリック
3. エミュレータのリストから **Pixel 5** を選択
4. **▶** ボタンをクリック
5. エミュレータが完全に起動するまで待つ（ホーム画面が表示されるまで）

#### 方法B: コマンドラインから起動

```powershell
# 利用可能なエミュレータを確認
flutter emulators

# エミュレータを起動
flutter emulators --launch Pixel_5
```

### ✅ ステップ3: エミュレータが起動していることを確認

```powershell
flutter devices
```

**出力例（正常）:**
```
2 connected devices:

sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64  • Android 13 (API 33)
Chrome (web)                 • chrome        • web-javascript • Google Chrome 120.0.6099.109
```

`emulator-5554` のようなエミュレータが表示されていればOKです。

### ✅ ステップ4: アプリを実行

```powershell
flutter run
```

## クイックチェック

エミュレータが起動しているか確認：

```powershell
flutter devices
```

エミュレータが表示されない場合：
1. Android Studioからエミュレータを起動
2. エミュレータが完全に起動するまで待つ（30秒〜1分）
3. 再度 `flutter devices` を実行

## トラブルシューティング

### エミュレータが起動しない

- Android Studioを再起動
- エミュレータの設定を確認（Device Manager > Edit）
- システム要件を確認（RAM、ディスク容量）

### エミュレータが表示されない

```powershell
# ADBを再起動
adb kill-server
adb start-server

# デバイスを再確認
flutter devices
```

## 実行スクリプトの改善

`run.ps1` スクリプトを更新して、エミュレータが起動していない場合に警告を表示するようにしました。

```powershell
.\run.ps1
```

スクリプトが自動的にエミュレータの状態を確認し、起動していない場合は案内を表示します。
