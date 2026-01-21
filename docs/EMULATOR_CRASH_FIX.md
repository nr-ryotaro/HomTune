# エミュレータクラッシュ修正

## 修正内容

### 1. グローバルエラーハンドリングの追加

`lib/main.dart`に以下を追加：
- `FlutterError.onError`: Flutterエラーのハンドリング
- `PlatformDispatcher.instance.onError`: プラットフォームエラーのハンドリング
- `WidgetsFlutterBinding.ensureInitialized()`: 初期化の確実な実行

### 2. データ読み込みの改善

`lib/services/device_service.dart`:
- アセットファイル読み込み時の詳細なエラーメッセージ
- JSON解析時のエラーハンドリング
- 初期化時の短い待機時間を追加

### 3. UI描画の安全性向上

`lib/widgets/floor_plan_widget.dart`:
- サイズ検証を追加（0以下の値をチェック）
- スケール計算の検証
- 各描画メソッドにtry-catchを追加
- 座標の検証（NaN、無限大をチェック）

### 4. モデルパースの安全性向上

`lib/models/device.dart`:
- 型変換の安全性向上
- nullチェックの強化
- エラー時の詳細なログ出力

### 5. 画面初期化の改善

`lib/screens/home_screen.dart`:
- mountedチェックの追加
- エラーハンドリングの改善

## テスト方法

1. エミュレータを起動（Pixel 5）
2. `flutter clean`を実行
3. `flutter pub get`を実行
4. `flutter run`でアプリを実行
5. ログを確認してエラーがないかチェック

## デバッグ方法

エラーが発生した場合、以下のコマンドでログを確認：

```powershell
flutter run --verbose
```

または、Android StudioのLogcatでエラーログを確認。
