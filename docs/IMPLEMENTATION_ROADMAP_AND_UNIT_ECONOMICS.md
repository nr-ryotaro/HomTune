# 実装ロードマップ・黒字運用設計

最終更新: 2026-07-13  
関連: `AI_PRICING_AND_BILLING.md`, `FREE_PRO_COMPARISON_AND_ROADMAP.md`, `ASSET_VALUATION.md`, `REMOTE_CONTROL.md`

---

## 1. 現状サマリー

| 領域 | 状態 | 備考 |
|------|------|------|
| 端末内 AI クォータ | **実装済** | `AiUsageService`（SharedPreferences） |
| 原価推定・Hard Cap | **実装済** | 月次 $1.25 上限（Pro売上の40%目安） |
| 自動上限調整 | **実装済** | `BillingControlService`（開発者設定） |
| ユニットエコノミクス試算 | **実装済** | `UnitEconomicsService` |
| ストア課金 | **未実装** | 開発者設定で Pro 切替のみ |
| Gemini API プロキシ | **未実装** | クライアント直 `GEMINI_API_KEY` |
| サーバー側 AI クォータ | **未実装** | 改ざんリスクあり |
| リモコンバックエンド | **開発用のみ** | `backend/server.js`（インメモリ） |
| Pro 検証（リモコン） | **脆弱** | `X-HomTune-Pro` ヘッダー自己申告 |
| 追加クレジット課金 | **未実装** | ドキュメントのみ |
| Free 広告収益モデル | **未計上** | 表示のみ（`ad_policy.dart`） |
| BigQuery / 請求連携 | **未実装** | ドキュメント推奨のみ |

---

## 2. 今後実装が必要なもの（優先度順）

### P0（本番リリース前必須）

1. **ストア課金** — App Store / Google Play Billing、レシート検証
2. **Gemini API サーバープロキシ** — APIキーをサーバーに集約、ユーザーID+プランでゲート
3. **サーバー側 AI クォータ DB** — 端末ローカル制限を補完（改ざん対策）
4. **Pro プラン検証のサーバー化** — リモコン・AI 共通でレシート or サブスク状態を検証
5. **本番インフラ** — Cloud Run / Fly.io 等、`backend/` の永続化（Redis/Postgres）

### P1（黒字運用の安定化）

6. **実請求データ取り込み** — GCP Billing Export → 週次で `creditCostUsd` 再校正
7. **レート制限** — chat 20req/10min、roomImage 日次上限など
8. **追加クレジット IAP** — 50cr/350円、120cr/780円
9. **Free 広告 ARPU 計測** — AdMob 収益をユニットエコノミクスに統合
10. **L1 相場DB のサーバー化（任意）** — 現状はローカル JSON（原価 $0）

### P2（体験・運用改善）

11. **原価ダッシュボード** — 機能別コスト、DAU/Pro比率
12. **モデル自動切替** — 高負荷時 `flash-lite` へ
13. **リモコン OAuth** — トークン暗号化ストレージ
14. **部屋・家電数に応じた動的上限** — 大量登録ユーザーへのフェアユース

---

## 3. プラン・価格・利用用途（現行）

| 項目 | Free | Pro（490円/月・税込） |
|------|------|----------------------|
| 家電登録・メンテ | ○ | ○ |
| 資産価値 L0（端末内推定） | ○ 無制限 | ○ 無制限 |
| 相場DB L1 | — | 月10回（ローカルJSON・原価$0） |
| AI相場 L2（Gemini） | — | 2 credits/回 |
| 部屋画像 | 1回/部屋（生涯） | 2回/部屋/月 |
| AIクレジット合計 | 月40 | 月120 |
| スマートリモコン | — | 月300操作 |
| 登録部屋数 | 最大5 | 最大10 |
| 追加AIクレジット | —（Proへ） | 50cr/350円〜 |
| 広告 | あり | なし |

### 機能別クレジット・推定原価（1回）

| 機能 | Credits | 推定USD | 実装メモ |
|------|--------:|--------:|----------|
| チャット | 1〜4（通常2） | $0.01〜0.04 | Gemini テキスト |
| 部屋画像 | **2** | **~$0.024** | テキストJSON＋端末内PNG（Imagen未使用） |
| スキャン補正 | 3 | $0.06 | |
| メンテ文生成 | 2 | $0.03 | |
| AI相場 L2 | 2 | $0.02 | |

### 月次ガード（端末推定）

| 閾値 | 値 | 根拠 |
|------|-----|------|
| Soft warn | $0.95 | Pro売上 $3.16 の約30% |
| Hard cap | **$1.25** | Pro売上 $3.16 の **40%**（粗利60%目標） |

為替 155 JPY/USD、Pro 490円 ≈ **$3.16/人/月**

---

## 4. 収益分岐点試算（AI原価のみ）

`UnitEconomicsService` による **Pro 1人・上限利用想定**（policy デフォルト）:

| シナリオ | 部屋画像 | チャット等 | 合計原価 | 原価率 | 判定 |
|----------|--------:|----------:|--------:|-------:|------|
| 3部屋・家電10 | ~$0.14 | ~$0.85 | **~$1.05** | 33% | 黒字圏内 |
| 5部屋・家電20 | ~$0.24 | ~$0.85 | **~$1.15** | 36% | 黒字圏内 |
| チャット偏重（60回） | $0.24 | ~$1.20 | **~$1.44** | 46% | 要監視 |

**月間総AI原価 $12.5 の場合** → 黒字に必要な Pro 会員数: 約 **10人**（1人あたり $1.26 まで許容）

### 部屋数・家電数と API 量の関係

| 変数 | API増加要因 | 現行の抑え込み |
|------|-------------|----------------|
| 部屋数↑ | 部屋画像スロット（部屋数×2回/月） | 2cr/回の低原価設計、Hard Cap |
| 家電数↑ | チャット・L2相場の利用増 | ローカル応答優先、L1キャッシュ30日 |
| 両方↑ | リモコン操作・メンテ通知 | Proのみ、月300回上限 |

**家電数自体はクレジット上限に直結しない**が、チャット・相場更新の利用頻度と相関するため、将来は「登録家電数ティア」でのフェアユース検討余地あり。

### Free ユーザー

- 最大 40 credits ≈ **$0.40〜1.60/人/月**（売上 $0）
- 黒字化には **広告 ARPU** または **Pro 転換** が必須
- 試算例: Free 1000人 × $0.80 原価 = $800/月 → Pro 約 **635人** で AI 原価相殺（広告・インフラ除く）

---

## 5. バックエンド構成（現状と将来）

### 現状 `backend/`

```
server.js     — Remo/SwitchBot プロキシのみ
lib/store.js  — インメモリ、Pro月300回
```

環境変数・デプロイ: `docs/NETLIFY_DEPLOY.md`（Flutter Web）、APIは別ホスト想定

### 将来アーキテクチャ（推奨）

```
Flutter App
  → HomTune API Gateway
      → /v1/ai/*        Gemini proxy + quota
      → /v1/billing/*   Store receipt verify
      → /v1/remote/*    現行 remo/switchbot
      → /v1/market/*    L1相場DB（将来）
```

---

## 6. 意思決定済み（2026-07-14）

| # | 項目 | 決定 |
|---|------|------|
| 1 | ストア手数料30% | **検討継続** — 試算はグロス/ネット両方を `UnitEconomicsService` で確認 |
| 2 | Free 広告 | **王道: AdMob アダプティブバナーのみ** — 詳細 `FREE_ADS_STRATEGY.md` |
| 3 | 追加クレジット | **Pro のみ**（50cr/350円、120cr/780円）。Free は Pro へ誘導 |
| 4 | 部屋数上限 | **Free 5 / Pro 10** — 追加部屋は枠内で画像クォータ適用、13LDK 等は拒否 |
| 5 | Gemini モデル | **リリース: `gemini-2.5-flash-lite` デフォルト** — `ConfigService.geminiModelFor` |
| 6 | L1 相場 | **同梱 JSON + サーバー API** — スクレイピング非採用。詳細 `MARKET_L1_AND_INFRA.md` |
| 7 | ホスティング | **Cloud Run + Storage（MVP $5〜15/月）** — AI プロキシと統合 |
| 8 | P0 着手順 | **Gemini プロキシ先行 → 本番 IAP** — 鍵漏洩・改ざんクォータによる原価リスクを先に塞ぐ（`GEMINI_PROXY_SPEC.md`） |

---

## 7. 実装 TODO（優先度順）

### 着手済み（コード反映済み）

- [x] `RoomFairUseService` — 部屋数上限 Free5/Pro10
- [x] `CreditAddonPack` + `grantBonusCredits` — Pro 追加クレジット基盤
- [x] `showCreditExhaustionDialog` — Free→Pro / Pro→追加クレジット
- [x] `gemini-2.5-flash-lite` デフォルト + `geminiModelFor`
- [x] `GET /v1/market/reference` — L1 サーバー API（MVP）
- [x] 広告 ARPU 試算定数（`AdPolicy`）

### P0（本番前）

- [ ] **Store Billing** — Pro サブスク + 追加クレジット IAP + レシート検証（**プロキシ後推奨**）
- [x] **Gemini サーバープロキシ（Phase 0–1）** — `/v1/ai/generate` + 全 AI サービス移行 + `google_generative_ai` 削除（仕様: `GEMINI_PROXY_SPEC.md`）
- [ ] **サーバー側 AI クォータ DB** — 永続化・Hard Cap（現状はプロセス内メモリ）
- [ ] **Pro 検証サーバー化** — リモコン・AI 共通

### P1（黒字安定化）

- [ ] **追加クレジット IAP 本番化** — `CreditExhaustionDialog` と連携
- [ ] **部屋追加 UI** — 上限チェック + Pro 訴求
- [ ] **L1 クライアント** — オフライン同梱 + オンライン API フォールバック
- [ ] **AdMob 実 eCPM 取り込み** — `FREE_ADS_STRATEGY.md` の試算更新
- [ ] **ストア手数料30%控除後**の試算を `UnitEconomicsService` に追加
- [ ] GCP 請求データ週次校正

### P2

- [ ] 原価ダッシュボード
- [ ] 機能別モデル自動切替（高負荷時 lite 固定）
- [ ] 四半期 L1 JSON 更新パイプライン

---

## 8. コード参照

| ファイル | 役割 |
|----------|------|
| `lib/models/ai_usage_policy.dart` | 上限・単価定義 |
| `lib/services/ai_usage_service.dart` | クォータ実行 |
| `lib/services/unit_economics_service.dart` | 分岐点試算 |
| `lib/services/billing_control_service.dart` | 実請求ベース自動調整 |
| `lib/services/room_image_generation_service.dart` | 部屋画像（低原価実装） |
| `lib/services/room_fair_use_service.dart` | 部屋数フェアユース |
| `lib/widgets/ai/credit_exhaustion_dialog.dart` | 枯渇時導線 |
| `lib/services/ad_policy.dart` | 広告 ARPU 試算 |
| `backend/lib/market_reference.js` | L1 相場 API |

開発者設定で **ユニットエコノミクス試算** と **実請求ベース自動調整** を確認できます。
