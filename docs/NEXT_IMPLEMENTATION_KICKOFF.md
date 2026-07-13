# 次実装キックオフ（main `96824f2` 起点）

最終更新: 2026-07-13  
起点コミット: `96824f23f25e3844269021a99a71d9eda5b89a2e`  
メッセージ: `feat: オンボーディング改善・黒字運用設計・部屋/AI利用ガードを反映`

本メモは **つづき実装を着手するための準備資料**。設計の正本は `IMPLEMENTATION_ROADMAP_AND_UNIT_ECONOMICS.md`。

---

## 1. main 最新の到達点（反映済み）

| 領域 | 状態 | 主な入口 |
|------|------|----------|
| 初回オンボーディング導線 | 済 | `first_launch_guide_service.dart`, `widgets/onboarding/*` |
| メーカーセット登録 | 済 | `manufacturer_bundle_*`, `assets/data/manufacturer-bundles.json` |
| 部屋数フェアユース（Free5/Pro10） | サービス済・UI未完全 | `room_fair_use_service.dart` |
| AI クレジット枯渇導線 | 基盤済・IAP未 | `credit_exhaustion_dialog.dart`, `CreditAddonPack` |
| `grantBonusCredits` | 開発用付与のみ | `ai_usage_service.dart` |
| Gemini `flash-lite` 既定 | 済 | `ConfigService.geminiModelFor` |
| L1 相場 同梱 JSON | 済 | `reference_market_catalog_service.dart` |
| L1 サーバー API MVP | 済 | `GET /v1/market/reference` |
| リモコン MVP | 開発用 | `backend/server.js` + `RemoteApiClient` |
| ユニットエコノミクス試算 | 済 | `unit_economics_service.dart` / 開発者設定 |

**未達（P0）**: ストア課金、Gemini サーバープロキシ、サーバー側 AI クォータ、Pro 検証のサーバー化。

---

## 2. 次に着手するスライス（推奨順）

本番前必須はすべて P0 だが、依存関係から次の順が最短。

### Slice A — Store Billing 骨格（クライアント）

**目的**: Pro サブスク + 追加クレジット IAP の購入〜付与までを、開発者トグル以外で動かせる。

| 項目 | 内容 |
|------|------|
| 新規依存 | `in_app_purchase`（将来 StoreKit2 / Play Billing） |
| 新規サービス案 | `lib/services/billing/store_billing_service.dart` |
| 商品 ID（仮） | Pro: `homtune_pro_monthly` / Addon: `addon_50`, `addon_120`（`CreditAddonPack.id` と一致） |
| フック点 | `ConfigService.setSubscriptionTier`、`AiUsageService.grantBonusCredits` |
| UI | `plan_screen.dart`、`credit_exhaustion_dialog.dart` の `_showAddonPurchasePlaceholder` を実購入に置換 |
| 暫定方針 | レシート検証前は **debug/sandbox のみ**有効。リリース前に Slice C と接続 |

受け入れ:

- Free→Pro 購入成功で `subscriptionTier == pro` が永続化
- Pro→addon 購入成功でボーナスクレジットが増える
- 購入キャンセル・失敗時にクラッシュせずメッセージ表示

### Slice B — Gemini サーバープロキシ（backend）

**目的**: クライアントから `GEMINI_API_KEY` を排除し、`/v1/ai/*` に集約。

| 項目 | 内容 |
|------|------|
| 既存参照 | `google_generative_ai` 直呼び（chat / scanner / roomImage / market L2） |
| 新エンドポイント案 | `POST /v1/ai/generate`（feature, prompt, modelHint） |
| 認証 | `X-HomTune-User-Id` + サーバー側 Pro/クォータ判定（Slice C） |
| 環境変数 | `GEMINI_API_KEY` を Cloud Run Secret へ |
| クライアント移行 | `ChatService` 等を `RemoteApiConfig.baseUrl` 経由に段階切替（Feature flag） |

受け入れ:

- クライアントビルドに API キーを埋め込まず動作
- feature 別クレジット消費はサーバー応答の `creditsCharged` と整合

### Slice C — サーバー側 AI クォータ + Pro 検証

**目的**: 端末 SharedPreferences 改ざんを無効化。リモコンの `X-HomTune-Pro` 自己申告を廃止。

| 項目 | 内容 |
|------|------|
| 永続化 | 当面インメモリ→次に Redis/Postgres（`MARKET_L1_AND_INFRA.md`） |
| ストア | userId → `{ tier, creditBalance, monthlyCostUsd, periodStart }` |
| Pro 判定 | Slice A のレシート検証結果を `/v1/billing/verify` で書き込み |
| 影響範囲 | `backend/server.js` の `isPro()`、`RemoteApiClient._headers` |

受け入れ:

- ヘッダー改ざんだけでは Pro 機能・AI を使えない
- 月次 Hard Cap `$1.25` をサーバーでも強制

### Slice D（P1・並行可）— 体験補完

1. **部屋追加 UI** — `RoomFairUseService.canRegisterRoomCount` を部屋追加フローへ配線 + Pro 訴求
2. **L1 クライアント folback** — `ReferenceMarketCatalogService` に `/v1/market/reference` オンライン優先
3. **手数料30%控除試算** — `UnitEconomicsService` にネット粗利行を追加

---

## 3. 既存コードのギャップメモ（実装時に踏まないこと）

1. **追加クレジットは定義・開発付与のみ**  
   `CreditAddonPack` と `grantBonusCredits` はあるが、`_showAddonPurchasePlaceholder` が「準備中」。IAP 接続点はここ。

2. **部屋数上限はサービスのみ**  
   `RoomFairUseService` はテスト済みだが、`lib/screens` からの `canRegisterRoomCount` 呼び出しが無い。オンボーディング以外の「部屋追加」に未配線の可能性が高い。

3. **L1 API はサーバーのみ**  
   クライアントは同梱 JSON のみ。`GET /v1/market/reference` は未利用。

4. **Pro ヘッダーは自己申告**  
   `RemoteApiClient` が `ConfigService.subscriptionTier` をそのまま送る。課金検証なし。

5. **backend は依存ゼロの素 Node**  
   `backend/package.json` に DB/SDK なし。Gemini プロキシ追加時は `@google/generative-ai` 等の導入が必要。

6. **本クラウド環境に Flutter SDK が無い**  
   Dart の `flutter test` / `analyze` はローカル or Flutter 入った環境で実行すること。Node backend のスモークは可能。

---

## 4. ブランチ運用案

| ブランチ例 | 内容 |
|------------|------|
| `cursor/store-billing-41d3` | Slice A |
| `cursor/ai-proxy-41d3` | Slice B |
| `cursor/server-quota-41d3` | Slice C（B と同一 PR でも可） |
| `cursor/room-limit-ui-41d3` | Slice D-1 |

本資料ブランチ `cursor/next-impl-prep-41d3` はキックオフのみ。実機能は上記で切る。

---

## 5. 着手チェックリスト（実装開始前）

- [x] `origin/main` = `96824f2` を確認
- [x] ロードマップ P0/P1 を整理（本書 §2）
- [ ] App Store / Play Console の商品 ID を確定（仮 ID から差し替え）
- [ ] Cloud Run プロジェクト + Secret Manager（`GEMINI_API_KEY`）準備
- [ ] sandbox 課金アカウント（Apple / Google）用意
- [ ] 最初の PR は **Slice A か Slice B** のどちらか単体から（同時はレビュー負荷が高い）

---

## 6. 参照

- `docs/IMPLEMENTATION_ROADMAP_AND_UNIT_ECONOMICS.md`
- `docs/AI_PRICING_AND_BILLING.md`
- `docs/MARKET_L1_AND_INFRA.md`
- `docs/FREE_ADS_STRATEGY.md`
- `docs/REMOTE_CONTROL.md`
- `docs/RELEASE_CHECKLIST.md`
