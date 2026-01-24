# リリース前チェックリスト

リリースビルドを行う前に、以下を実施してください。

## 開発者設定機能の削除（機能確認用）

Smart Ingester の **API / ダミーデータ切り替え** および **開発者設定画面** は機能確認用です。リリース前に削除するか、本番用に固定してください。

### 1. 開発者設定画面を削除する場合

- **削除するファイル**
  - `lib/screens/dev_settings_screen.dart`
- **修正するファイル**
  - `lib/screens/home_screen.dart`
    - `import 'dev_settings_screen.dart'` を削除
    - `import 'package:flutter/foundation.dart'` は他で使っていなければ削除
    - AppBar の `actions` 内、`if (kDebugMode) { ... }` の IconButton（設定アイコン）を削除

### 2. ConfigService を削除する場合

本番では常に **実API** を使用する前提で、ConfigService 自体をやめる場合：

- **削除するファイル**
  - `lib/services/config_service.dart`
- **修正するファイル**
  - `lib/main.dart`
    - `ConfigService` の import / 生成 / `load()` / `MultiProvider` への登録を削除
    - `HomTuneApp` の `configService` 引数と `MultiProvider` をやめ、`DeviceService` のみの `ChangeNotifierProvider` に戻す
  - `lib/services/scanner_service.dart`
    - `ConfigService` の import とコンストラクタ引数を削除
    - `_configService.isUsingRealApi` の分岐を削除し、常に Gemini API を使用する実装のみ残す
  - `lib/services/manual_search_service.dart`
    - `ConfigService` の import とコンストラクタ引数を削除
    - `_configService.isUsingRealApi` の分岐を削除し、常に実検索ロジック（モック／実API）のみ残す
  - `lib/screens/scan_screen.dart`
    - `ConfigService` の import と `didChangeDependencies` 内での `Provider.of<ConfigService>` / `ScannerService`・`ManualSearchService` への渡しを削除
    - `ScannerService` と `ManualSearchService` の生成方法を、ConfigService に依存しない形に戻す（従来どおりコンストラクタ引数なしなど）

### 3. ConfigService を残すが本番で固定する場合

- `lib/services/config_service.dart` の `load()` で、`kReleaseMode` のときは常に `_useRealApi = true` を設定し、SharedPreferences を読まない
- 開発者設定画面は上記「1」に従い削除する（`kDebugMode` 時のみ表示していたとしても、リリースビルドでは表示しない）

### 4. テスト確認項目

リリース前には少なくとも以下を確認してください。

- [ ] スマート登録（バーコード・プレート撮影）が意図どおり動作する
- [ ] 家電追加・一覧・詳細表示が問題ない
- [ ] 説明書検索・PDF 表示（該当機能がある場合）が問題ない
- [ ] 開発者設定画面・設定アイコンがリリースビルドに含まれていない（削除した場合）
- [ ] `flutter run --release` または `flutter build apk --release` / `flutter build ios --release` でビルドが通る

## 参照

- 機能確認用設定の概要: [SMART_INGESTER.md](SMART_INGESTER.md)
