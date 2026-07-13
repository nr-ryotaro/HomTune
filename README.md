# HomTune（ホームチューン）

家庭内の家電や機材を「資産」および「生活の構成要素」として最適に管理・調律するためのモバイルアプリケーションです。

## プロジェクト概要

HomTuneは、単なる家電管理を超えて、以下の機能を提供します：

- **スマートスキャン**: バーコード / 型番プレートの撮影から ML Kit OCR + Gemini AI で製品情報を自動抽出・登録
- **資産価値ダッシュボード**: 帳簿価値・市場価値の自動計算と fl_chart による推移グラフ表示
- **スペーシャル・オーガナイザー**: 部屋別デバイス管理、間取り図連携、AI ルームイメージ生成
- **取扱説明書アーカイバ**: 公式マニュアルの自動検索 / PDF 表示 / 手動登録
- **リコール & 安全アラート**: NITE 互換のリコール情報チェック、深刻度別アラート表示、安全性スコア算出
- **AI トラブルシューティング**: Gemini API 連携のデバイスコンテキスト認識チャット（リコール情報・メンテナンス・保証を考慮した回答）
- **売却タイミングアドバイザー**: Book Value × Market Value 交差点分析による最適売却タイミング提案

## 技術スタック

| レイヤー | 技術 |
|---|---|
| **フレームワーク** | Flutter 3.x (Dart ≥ 3.0) |
| **状態管理** | Provider |
| **データ永続化** | SharedPreferences / sqflite |
| **AIとOCR** | Google ML Kit Text Recognition, Gemini (google_generative_ai) |
| **バーコードスキャン** | mobile_scanner |
| **グラフ描画** | fl_chart |
| **PDF** | pdfx (表示) / pdf (生成) |
| **その他** | url_launcher, cached_network_image, intl, image_picker, file_picker |
| **プラットフォーム** | Android / iOS（Web は UI プレビューのみ） |
| **デザイン** | ミニマルデザイン（Japandi テイスト、細い線ベースの UI） |

## Web UI プレビュー / Netlify 公開

ブラウザで **UI・導線のみ** 確認するビルドです。スキャン / OCR / カメラは無効です。

```powershell
# ビルド（成果物: build/web, dist/homtune-web-deploy.zip）
.\scripts\build_web_preview.ps1

# Netlify CLI で本番デプロイ（要 netlify login）
.\scripts\deploy_netlify.ps1
```

| 手順 | ドキュメント |
|------|----------------|
| Netlify Drop / CLI / チェックリスト | [docs/NETLIFY_DEPLOY.md](docs/NETLIFY_DEPLOY.md) |
| Web プレビュー概要 | [docs/WEB_PREVIEW.md](docs/WEB_PREVIEW.md) |

## ディレクトリ構造

```
HomTune/
├── lib/
│   ├── main.dart
│   ├── app/                     # アプリシェル・ルーティング（go_router）
│   ├── data/                    # Repository / LocalSource
│   ├── models/                  # Device, Room, Safety, AI 課金ポリシー等
│   ├── screens/                 # 画面（ホーム・オンボーディング・スキャン・メンテ等）
│   ├── services/                # ビジネスロジック・外部連携
│   ├── utils/                   # platform_support, category_mapper
│   └── widgets/                 # 共有 UI・device_detail セクション
├── assets/data/                 # mock-data, floor-plan, templates 等
├── test/                        # サービス・画面・ウィジェットのユニットテスト
├── docs/                        # 設計・運用ドキュメント
└── pubspec.yaml
```

主要ファイル（抜粋）:

| 領域 | 代表ファイル |
|------|----------------|
| エントリ | `lib/main.dart`, `lib/app/router.dart` |
| 状態 | `device_service.dart`, `config_service.dart` |
| データ | `lib/data/repositories/device_repository.dart` |
| オンボーディング | `onboarding_screen.dart`, `onboarding_step*_screen.dart` |
| AI | `chat_service.dart`, `ai_routing_service.dart`, `ai_usage_service.dart` |
| メンテ | `maintenance_calendar_service.dart`, `maintenance_*_screen.dart` |
| 資産・売却 | `asset_valuation_service.dart`, `sell_advisor_service.dart` |
| 安全 | `safety_service.dart`, `safety_info.dart` |

アーキテクチャの詳細は [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) を参照。

## セットアップ

### 必要な環境

- Flutter SDK 3.x 以上 (`dart sdk >=3.0.0 <4.0.0`)
- Android Studio（Android エミュレータ / 実機デバッグ用）
- Xcode（iOS 開発時、macOS のみ）

### インストール & 実行

```bash
# 依存関係の取得
flutter pub get

# 静的解析（lib は error 0 を維持）
flutter analyze lib

# ユニット / ウィジェットテスト（CI 相当）
flutter test

# デバッグ実行（エミュレータまたは接続デバイス）
flutter run

# Gemini API を有効化して実行する場合
flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
```

### 開発者設定

- デバッグビルドのホーム AppBar から開発者設定へ遷移（`kDebugMode` のみ）
- 本番での扱いは [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) を参照

### エミュレータでのテスト

- Android: Android Studio → AVD Manager でエミュレータを起動後、`flutter run`
- iOS: Xcode → Simulator を起動後、`flutter run`

詳細は [docs/FLUTTER_SETUP.md](docs/FLUTTER_SETUP.md) を参照。

## 主要機能

### 🏠 ホーム画面

- 部屋カード（ルームイメージ + 資産合計 + アラート数）の横スクロール表示
- カードタップで部屋別デバイス一覧へ遷移
- AI ルーム再生成ボタン（プレミアム機能モック）

### 📱 スマートスキャン

- **バーコードモード**: リアルタイムバーコード検出 → JAN コードから製品情報を自動取得
- **型番スキャンモード**: カメラ撮影 → ML Kit OCR → Gemini AI で構造化データ抽出
- 検出結果を確認し、ワンタップでデバイスを登録

### 📊 資産価値ダッシュボード

- 帳簿価値（定率法）と市場価値（中古相場シミュレーション）の自動計算
- fl_chart による 12 ヶ月推移グラフ（Book Value: 青 / Market Value: 緑）
- 資産インサイト表示

### 📖 取扱説明書管理

- 公式マニュアルの自動検索・PDF リンク保存
- PDF ビューア内蔵（pdfx）
- 手動での URL / ファイル登録

### 🗺️ 間取り図

- 部屋別デバイス数のバッジ表示
- 部屋タップでフィルタリング
- 選択部屋のハイライト表示

### 🛡️ リコール & 安全アラート

- 型番・メーカーによるリコール自動チェック（モックデータ / 将来的に NITE API 対応）
- 深刻度 3 段階（`critical` / `warning` / `info`）に応じた色分きアラートバナー
- 安全性スコア（0〜100）の自動算出（経過年数・メンテナンス履歴・耐用年数・リコール状態を加味）
- メーカー問い合わせ URL へのワンタップ連絡
- 部屋カード・デバイスカードへのリコール対象バッジ表示

### 🤖 AI トラブルシューティング

- **Gemini API 連携**: `ChatService` がデバイスコンテキスト（型番・カテゴリ・リコール情報・メンテナンス履歴・保証状態）をシステムプロンプトに自動注入
- **デュアルモード**: `ConfigService.isUsingRealApi` で Gemini API ↔ ローカル応答を即座に切り替え
- **会話履歴保持**: `ChatSession` によるマルチターン会話
- **開発者設定ダッシュボード**: API キー状態・AI モード・スキャン OCR モードを一覧表示
- **フォールバック**: API エラー時は自動的にローカル応答へ切り替え

### 🔄 売却タイミングアドバイザー

- **交差点分析**: Book Value × Market Value の 24 ヶ月シミュレーションで最適売却タイミングを算出
- **4 段階判定**: 🔥 今が売り時（score 70-100）→ ⏰ そろそろ売り時（60-80）→ 🔄 買い替え検討（30）→ 📉 様子見（20）
- **デバイス詳細画面**: 色分けアドバイザーカード（推定売却価格・帳簿差額・交差点タイムライン・推奨アクション表示）
- **ホーム画面バナー**: 売却チャンス対象デバイス数 + トップ推奨デバイスを表示

### 🌐 ランディングページ (LP)

- プロダクトの世界観と機能を伝える静的 HTML ページ (`lp/index.html`)
- "Japandi" スタイルのミニマルデザインと、スクロール連動フェードインアニメーション
- レスポンシブ対応およびローカル確認用ワークフロー (`/lp-test`) 完備

### 🚀 オンボーディング

- 初回起動時のみ表示される 3 ステップのゲストファーストなセットアップ UI
- 住居タイプ選択からの自動部屋生成、直感的な部屋の追加・削除
- 最初の 1 台のスムーズな登録（スマートスキャン連携）

### 🔧 選べるメンテナンスモード

- **ずぼらモード（デフォルト）**: デバイス全体のお手入れを 1 ボタンで一括完了記録。手間を最小限に抑制
- **詳細モード**: 開発者設定から切り替え可能。パーツごと（フィルター、タンク等）のタスクに対して固有の周期や通知設定を管理

## 実装ステータス

### Phase 1〜3 実装検証結果

| Phase | 機能 | ステータス | 検証内容 |
|---|---|---|---|
| **Phase 1** | 🛡️ リコール & 安全アラート | ✅ 完了 | `RecallSeverity` が 4 ファイル 21 箇所で正常に参照。バッジ・バナー・スコア算出すべて動作 |
| **Phase 2** | 🤖 AI トラブルシューティング | ✅ 完了 | `ChatService` → `chat_widget.dart` 統合確認。デュアルモード切替・API ダッシュボード動作 |
| **Phase 3** | 🔄 売却アドバイザー | ✅ 完了 | `sell_advisor_service.dart` が `device_detail_content.dart` + `home_screen.dart` で正常に参照 |
| **Phase 4** | ⚡ 電気代シミュレーター | 📋 未着手 | — |
| **Phase 5** | 👨‍👩‍👧‍👦 ファミリー共有 | 📋 未着手 | — |

### flutter analyze 結果

| カテゴリ | 件数 | 詳細 |
|---|---|---|
| **error** | 1 | `test/widget_test.dart` — `MyApp` 未定義（テストファイル / Phase 1 以前から既存） |
| **warning** | 7 | 未使用 import・未使用変数 — すべて Phase 1 以前から既存 |
| **info** | 10 | `withOpacity` 非推奨 + 文字列補間スタイル — すべて既存 or 意図的 |
| **新コード由来のエラー** | **0** | Phase 1〜3 の全実装コードでエラーゼロ |

### 各機能のクロスリファレンス検証

```
── Phase 1 (リコール) ──────────────────────────────
  safety_info.dart          RecallSeverity enum 定義 + パーサー        ✅
  safety_service.dart       バッチチェック・深刻度スコアリング           ✅
  device_card.dart          RECALL バッジ表示                          ✅
  device_detail_content.dart  リコールアラートバナー                    ✅

── Phase 2 (AI チャット) ────────────────────────────
  chat_service.dart         Gemini API + ローカル応答デュアルモード     ✅
  chat_widget.dart          ChatService 統合・ライフサイクル管理         ✅
  config_service.dart       isUsingRealApi フラグ + 永続化             ✅
  dev_settings_screen.dart  API ダッシュボード + ワンタップ切替          ✅

── Phase 3 (売却アドバイザー) ──────────────────────
  sell_advisor_service.dart   BV×MV 交差点算出 + 4段階スコアリング      ✅
  device_detail_content.dart  売却アドバイザーカード UI                  ✅
  home_screen.dart            売却チャンスバナー                        ✅
```

### 未対応タスク（Phase 2-3 内）

| タスク | 理由 |
|---|---|
| マニュアル PDF テキスト抽出 → AI コンテキスト埋め込み | PDF パーサーライブラリ選定が必要 |
| 「今が売り時」プッシュ通知 | `flutter_local_notifications` 導入が必要 |

## 次の実装ロードマップ

```
✅ E → ✅ G → ✅ A → ⏭️ C → D
                       ↑ 次はここ
```

| 順番 | 機能 | 見積もり | 既存基盤 |
|---|---|---|---|
| ~~①~~ | ~~🛡️ E: リコールアラート~~ | ~~2〜3日~~ | ✅ 完了 |
| ~~②~~ | ~~🤖 G: AI トラブルシュート~~ | ~~3〜4日~~ | ✅ 完了 |
| ~~③~~ | ~~🔄 A: 売却アドバイザー~~ | ~~4〜5日~~ | ✅ 完了 |
| **④** | **⚡ C: 電気代シミュレーター** | **3〜4日** | Gemini スペック抽出基盤あり |
| ⑤ | 👨‍👩‍👧‍👦 D: ファミリー共有 | 7〜10日 | バックエンド構築必要 |

## データモデル

`Device` モデルの主要フィールド：

| フィールド | 型 | 説明 |
|---|---|---|
| `name`, `modelNumber`, `manufacturer` | String | 基本情報 |
| `category`, `room`, `location` | String | 分類・設置場所 |
| `purchasePrice`, `purchaseDate`, `yearsOwned` | int / String / double | 購入情報 |
| `condition` | ItemCondition | 新品 / 中古 |
| `assetValue` | AssetValue? | 資産評価（帳簿価値・市場価値・減価償却率） |
| `maintenance` | Maintenance? | メンテナンス情報（アラート・履歴） |
| `manual` | Manual? | 取扱説明書情報 |
| `manualState` | ManualFetchState | マニュアル取得状態 |
| `warranty` | Warranty? | 保証情報 |
| `safetyInfo` | SafetyInfo? | 安全情報 |
| `consumables` | List\<Consumable\> | 消耗品リスト |
| `janCode` | String? | JAN コード（バーコードスキャンで取得） |

## デザイン原則

- **ミニマリズム**: 不要な装飾を排除し、情報の本質に集中
- **細い線**: 0.5px のボーダーと抑えたカラーパレットで清潔感を演出
- **余白**: 贅沢な余白で視認性と高級感を確保
- **Material 3**: `useMaterial3: true` によるモダンなコンポーネント
- **モバイル最適化**: タッチ操作、レスポンシブレイアウト

## ドキュメント

`docs/` ディレクトリに詳細な設計・運用ドキュメントがあります：

- [AI_PRICING_AND_BILLING.md](docs/AI_PRICING_AND_BILLING.md) — AI課金、請求確認、Free/Pro制限、黒字運用ガイド
- [FREE_PRO_COMPARISON_AND_ROADMAP.md](docs/FREE_PRO_COMPARISON_AND_ROADMAP.md) — Free/Pro差異と追加機能ロードマップ
- [FLUTTER_SETUP.md](docs/FLUTTER_SETUP.md) — Flutter 環境セットアップ
- [FLUTTER_EXECUTION.md](docs/FLUTTER_EXECUTION.md) — 実行手順
- [SMART_INGESTER.md](docs/SMART_INGESTER.md) — スマートスキャン機能設計
- [data-structure.md](docs/data-structure.md) — データ構造定義
- [living-icons-safety.md](docs/living-icons-safety.md) — Living Icons & 安全機能
- [feature-manual-archiver.md](docs/feature-manual-archiver.md) — 説明書アーカイバ機能
- [feature-add-appliance.md](docs/feature-add-appliance.md) — 家電追加機能

## AI課金方針（運用案）

黒字運用前提の初期案:

- **Free**: 0円 / 月間 40 credits（部屋画像は初回1回/部屋、生涯）
- **Pro**: 490円 / 月間 120 credits（部屋画像は2回/部屋/月）
- **超過時**: ローカル回答へフォールバック（または追加クレジット購入）

詳細な料金設計・請求確認・インフラ制御は [AI_PRICING_AND_BILLING.md](docs/AI_PRICING_AND_BILLING.md) を参照してください。

## ライセンス

MIT
