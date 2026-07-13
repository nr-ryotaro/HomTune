# L1 相場DB・API ホスティング設計

最終更新: 2026-07-14

## 結論（最善案）

| フェーズ | 方式 | 原価 | 法務リスク |
|----------|------|------|------------|
| **現在〜リリース** | アプリ同梱 JSON + 30日キャッシュ | **$0** | 低（自社キュレーション） |
| **リリース後** | Cloud Storage JSON + Cloud Run 読み取り API | **$5〜15/月** | 低 |
| **スケール時** | 四半期ごとの手動/ライセンスデータ更新 | データ調達費のみ | 中（契約次第） |

**スクレイピングは採用しない** — 利用規約・安定性・メンテ負荷の観点から非推奨。

---

## 現状アーキテクチャ

```
AssetValuationRefreshService
  L0: 端末内数式（全プラン・無制限）
  L1: assets/data/market-reference-prices.json（Pro・月10回）
  L2: MarketPriceGeminiService（Pro・2cr/回）
```

- L1 キャッシュヒット時はクォータ消費なし（`MarketPriceCacheService` TTL 30日）
- L1 未登録型番 → L2 へ誘導

---

## サーバー API（実装済み・MVP）

`backend/lib/market_reference.js` + `server.js`:

| エンドポイント | 認証 | 用途 |
|----------------|------|------|
| `GET /v1/market/reference?manufacturer=&modelNumber=` | Pro ヘッダー | 型番一致の参照価格 |
| `GET /v1/market/meta` | なし | エントリ数・減価率メタ |

データソースは **アプリと同一 JSON**（`assets/data/market-reference-prices.json`）をサーバーでも読み込み。

### クライアント移行方針

1. 現状: `ReferenceMarketCatalogService` がアセットから直接読み込み（オフライン可）
2. 将来: `ReferenceMarketCatalogService` にリモートフォールバックを追加
   - ネットワークあり → API 優先（最新 JSON 反映）
   - オフライン → 同梱 JSON

---

## ホスティング構成（推奨）

```
Cloud Run (min-instances=0)
  ├── /v1/market/*     ← 今回追加
  ├── /v1/remote/*     ← 既存 Remo/SwitchBot
  └── /v1/ai/*         ← 将来 Gemini プロキシ

Cloud Storage
  └── market-reference-prices.json（四半期更新）

Firestore or Postgres（将来）
  └── AI クォータ・課金レシート
```

### 月額コスト試算（MVP〜初期）

| サービス | 想定 | 月額 |
|----------|------|------|
| Cloud Run | 月 10万リクエスト、256MB | $0〜5 |
| Cloud Storage | JSON 1MB + 転送少量 | $1未満 |
| Secret Manager | API キー数個 | $1未満 |
| Gemini API | Pro ユーザー数に比例 | 変動（主原価） |
| **合計インフラ固定費** | | **$5〜15** |

Gemini 原価が支配的。インフラ固定費は Pro 会員 **3〜5人** で回収可能（AI原価除く）。

---

## データ更新運用（四半期）

1. 家電メーカー公式・大手中古サイトの **公開価格帯を手動サンプリング**
2. CSV → `market-reference-prices.json` 生成スクリプト
3. Cloud Storage にアップロード → アプリは次回起動 or API で取得
4. 型番カバレッジ KPI: 登録上位 100 型番の **80%以上** を目標

### 法務上の注意

- 第三者サイトの自動スクレイピングは ToS 違反リスク
- 公式 API / データライセンス契約がある場合のみ外部連携
- 表示は「参考相場」であり保証価格ではない旨を UI に明記（既存 Help）

---

## 関連ファイル

| パス | 役割 |
|------|------|
| `assets/data/market-reference-prices.json` | L1 データ |
| `lib/services/reference_market_catalog_service.dart` | クライアント読み込み |
| `backend/lib/market_reference.js` | サーバー lookup |
| `lib/config/remote_api_config.dart` | API ベース URL |
