# 資産価値（帳簿・市場・表示）の算出方針

## 三つの値の定義

| 値 | 意味 | 更新頻度（現行） | API コスト |
|----|------|------------------|------------|
| **帳簿価値** | 減価償却ベースの保有価値（タイムライン式と法定耐用年数の平均） | **アプリ起動時 `loadData` ごと** | 0 円 |
| **市場価値** | 中古相場の推定（数式 / カタログ / Pro相場DB / AI） | 起動時 L0 + 手動更新 | L0: 0 円 |
| **表示価値** | `max(帳簿, 市場)` — UI のメイン数字 | 帳簿・市場と同時 | 同上 |

## 実装クラス

- [`AssetValuationService`](../lib/services/asset_valuation_service.dart) — 数式コア
- [`AssetValuationRefreshService`](../lib/services/asset_valuation_refresh_service.dart) — L0〜L2 オーケストレーション
- [`MarketPriceCacheService`](../lib/services/market_price_cache_service.dart) — 型番キャッシュ（TTL 30 日）
- [`ReferenceMarketCatalogService`](../lib/services/reference_market_catalog_service.dart) — L1 相場参照DB
- [`MarketValuationQuotaService`](../lib/services/market_valuation_quota_service.dart) — L1 月間クォータ
- [`MarketPriceGeminiService`](../lib/services/market_price_gemini_service.dart) — L2 Gemini 推定

## 段階と課金（実装済）

| 段階 | 内容 | プラン | 備考 |
|------|------|--------|------|
| **L0** | 端末内：帳簿再計算 + 数式市場 + デモカタログブレンド | **Free / Pro 無制限** | 更新ボタン・起動時 |
| **L1** | 同梱 `market-reference-prices.json` 参照（将来サーバーAPI差替） | **Pro のみ・月10回** | TTL内キャッシュはクォータ消費なし |
| **L2** | Gemini 中古相場 JSON 抽出 | **Pro のみ・2 AIクレジット/回** | 実APIオフ時はモック（クレジット消費なし） |

**原則**: クライアントからの相場スクレイピングは禁止。キャッシュキーは `manufacturer|modelNumber`。

## Free / Pro の切り分け

- **Free**: L0 のみ（ローカル再計算は無制限）。L1/L2 ボタンは説明のみ表示。
- **Pro**: L1 月10回（`AiUsagePolicy.proMonthlyMarketLookups`）、L2 は月次 AI クレジット枠内。
- **手動「更新」アイコン**: 全プラン L0（端末内・無料）。

## 関連 UI

- 資産詳細シート: 帳簿 / 市場 / 表示、更新時刻、市場ソースラベル
- Pro 向け: 「相場DBを調べる」「AI相場推定」ボタン

## 将来（L3）

- 日次バッチ + プッシュ「売り時」通知（Pro+）
