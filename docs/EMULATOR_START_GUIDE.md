# エミュレータ起動ガイド

## 問題

`flutter run`を実行した際に以下のエラーが表示される場合：

```
No supported devices connected.
The following devices were found, but are not supported by this project:
Windows (desktop) • windows • windows-x64
Chrome (web) • chrome • web-javascript
Edge (web) • edge • web-javascript
```

これは、**Androidエミュレータが起動していない**ことを意味します。

## 解決方法

### ステップ1: Androidプラットフォームのサポートを確認

プロジェクトにAndroidプラットフォームのサポートが追加されていることを確認：

```powershell
flutter create . --platforms=android
```

（既に実行済み）

### ステップ2: エミュレータを起動

#### 方法1: Android Studioから起動（推奨）

1. **Android Studioを開く**
2. **Tools > Device Manager** をクリック
3. エミュレータのリストから **Pixel 5** または **Medium Phone API 36.1** を選択
4. **▶** ボタンをクリックしてエミュレータを起動
5. エミュレータが完全に起動するまで待つ（ホーム画面が表示されるまで）

#### 方法2: コマンドラインから起動

```powershell
# 利用可能なエミュレータを確認
flutter emulators

# エミュレータを起動（例: Pixel_5）
flutter emulators --launch Pixel_5
```

### ステップ3: エミュレータが起動していることを確認

```powershell
flutter devices
```

出力例：
```
2 connected devices:

sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64  • Android 13 (API 33)
Chrome (web)                 • chrome        • web-javascript • Google Chrome 120.0.6099.109
```

**`emulator-5554`** のようなエミュレータが表示されていればOKです。

### ステップ4: アプリを実行

```powershell
flutter run
```

または、特定のエミュレータを指定：

```powershell
flutter run -d emulator-5554
```

## トラブルシューティング

### エミュレータが起動しない

1. **Android Studioを再起動**
2. **エミュレータの設定を確認**
   - Device Managerでエミュレータを右クリック > Edit
   - RAMやディスク容量を確認
3. **システム要件を確認**
   - 十分なRAMがあるか
   - ディスク容量が十分か

### エミュレータが表示されない

```powershell
# ADBを再起動
adb kill-server
adb start-server

# デバイスを再確認
flutter devices
```

### エミュレータが遅い

1. **エミュレータの設定でRAMを増やす**
2. **HAXM（Intel）またはHyper-V（AMD）が有効か確認**
3. **グラフィック設定を変更**（Device Manager > Edit > Advanced > Graphics）

## 確認チェックリスト

- [ ] Android Studioがインストールされている
- [ ] エミュレータが作成されている
- [ ] エミュレータが起動している
- [ ] `flutter devices`でエミュレータが表示される
- [ ] `flutter run`でアプリが起動する
