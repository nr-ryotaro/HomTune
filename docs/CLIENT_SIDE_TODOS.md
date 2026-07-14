# HomTune 作業洗い出し（バックエンド以外）

最終更新: 2026-07-14（C1–C6 / C8–C10 / C12 実装反映）  
前提: **バックエンドの設定・新規追加は帰宅後。本ドキュメントはクライアント側。**

政策（クライアント済）:
- 部屋画像 = デフォルト or AI生成のみ（実写なし）
- Free AI = アカウント生涯1回
- Freeでも部屋カード「差し替え」→ Pro 説明ダイアログ

関連: [`NEXT_TODOS.md`](./NEXT_TODOS.md), [`POLICY_IMPLEMENTATION_AUDIT.md`](./POLICY_IMPLEMENTATION_AUDIT.md)

---

## A. 完了済み（本スプリント含む）

| 項目 | 場所 |
|------|------|
| Free スキャン／メンテ local-first | `scanner_service` / `maintenance_calendar_service` |
| RoomFairUse UI 配線 | `onboarding_step2_screen.dart` |
| release `preferAiProxy` 固定 | `config_service.dart` |
| Pro 訴求 Analytics | `pro_upgrade_dialog.dart` |
| プロキシ残量同期（二重計上緩和） | `ai_usage_service.recordUsage` |
| StoreBilling stub | `store_billing_service.dart` |
| Plan 文言・レガシー削除・import掃除 | `plan_screen` / `ai_usage_policy` / `home_screen` |
| AdMob dart-define 手順 | `FREE_ADS_STRATEGY.md` |
| 部屋画像／差し替え／lifetime（既存） | 各種 |

---

## B. 残り（任意・バックエンド不要）

| ID | 作業 |
|----|------|
| C11 | release 監査の追加テスト |
| C13 | FairUse widget テスト |
| C14 | Unit economics Free シナリオ |
| C15 | 規約・プライバシー URL 枠 |

---

## C. 帰宅後（バックエンド）

B1–B4、Cloud Run、本番 IAP、AdMob アカウント登録。
