# Android Studioエミュレータの使い方

## エミュレータの作成（初回のみ）

### ステップ1: Android Studioを開く

1. Android Studioを起動

### ステップ2: Device Managerを開く

1. **Tools > Device Manager** をクリック
2. または、ツールバーのデバイスアイコンをクリック

### ステップ3: エミュレータを作成

1. **Create Device** ボタンをクリック
2. **Phone** カテゴリからデバイスを選択（例: Pixel 5）
3. **Next** をクリック
4. システムイメージを選択（例: **API 33 (Android 13)**）
   - 初回は「Download」をクリックしてダウンロード
5. **Next** をクリック
6. エミュレータ名を確認して **Finish** をクリック

## エミュレータの起動

### 方法1: Android Studioから

1. **Device Manager** を開く
2. 作成したエミュレータの横の **▶** ボタンをクリック
3. エミュレータが起動するまで待つ（数分かかる場合あり）

### 方法2: コマンドラインから

```powershell
# エミュレータのリストを確認
flutter emulators

# エミュレータを起動
flutter emulators --launch <emulator-id>
```

## Cursorターミナルからアプリを実行

### エミュレータが起動している場合

```powershell
# 利用可能なデバイスを確認
flutter devices

# アプリを実行
flutter run
```

### エミュレータが起動していない場合

1. **Android Studioからエミュレータを起動**
2. エミュレータが完全に起動するまで待つ
3. Cursorターミナルで `flutter run` を実行

## 実行の流れ

```
1. Android Studioでエミュレータを起動
   ↓
2. エミュレータが起動完了（ホーム画面が表示される）
   ↓
3. Cursorターミナルで `flutter run` を実行
   ↓
4. アプリがエミュレータにインストール・起動
```

## トラブルシューティング

### エミュレータが起動しない

- Android Studioを再起動
- エミュレータの設定を確認
- システム要件を確認（RAM、ディスク容量）

### エミュレータが遅い

- エミュレータの設定でRAMを増やす
- HAXM（Intel）またはHyper-V（AMD）が有効か確認

### アプリがエミュレータに表示されない

```powershell
flutter clean
flutter pub get
flutter run
```
