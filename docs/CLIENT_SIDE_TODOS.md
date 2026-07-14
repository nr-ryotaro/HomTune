# HomTune 作業洗い出し（バックエンド以外）

最終更新: 2026-07-14  
前提: **バックエンドの設定・新規追加（Cloud Run / Secret / quota DB / billing verify / サーバー lifetime 等）は帰宅後実施。本ドキュメントはそれ以外で進められる作業のみ。**

政策（クライアント済）:
- 部屋画像 = デフォルト or AI生成のみ（実写なし）
- Free AI = アカウント生涯1回
- Freeでも部屋カード「差し替え」→ Pro 説明ダイアログ

関連: [`NEXT_TODOS.md`](./NEXT_TODOS.md), [`POLICY_IMPLEMENTATION_AUDIT.md`](./POLICY_IMPLEMENTATION_AUDIT.md)

---

## A. クライアント側で完了済み（再確認不要）

| 項目 | 場所 |
|------|------|
| Gemini プロキシ呼び出し移行 | `AiApiClient` + 各 AI サービス |
| Free 部屋AI lifetime=1（端末側） | `ai_usage_service.dart` |
| 実写廃止＋AI/デフォルト統一 | `room_photo_setup_screen.dart` |
| Free 差し替えボタン → Pro 訴求 | `home_screen._onCustomizeRoomImage` |
| チャット local-first | `ai_routing_service` / `chat_widget` |
| RoomFairUse ロジック＋単体テスト | `room_fair_use_service.dart`（**UI未配線**） |
| AdMob 骨格（未設定時は release で非表示） | `admob_config.dart` |
| 開発者設定入口の kDebug 限定 | `router.dart` / AppBar |

---

## B. 今すぐできる（バックエンド不要）— 優先順

### B-P0（原価・方針 Enforce・計測）

| ID | 作業 | 主なファイル | 完了条件 | スキップ時リスク |
|----|------|--------------|----------|------------------|
| **C1** | Free **スキャンをローカル優先**（確認ダイアログ or AI前ローカル） | `scanner_service.dart`, `scan_screen.dart` | Free が黙ってプロキシ課金しない | Free 原価の穴 |
| **C2** | Free **メンテ文をローカル／テンプレ優先** | `maintenance_calendar_service.dart`, 詳細画面 | Free は開くだけでクレジット消費しない | 同上 |
| **C3** | **RoomFairUse をオンボーディング／部屋選択に配線** | `onboarding_step2_screen.dart`, `onboarding_screen.dart` | Free5/Pro10 超過時メッセージ＋Pro訴求 | 上限が死コードのまま |
| **C4** | **release で `preferAiProxy` 固定**（prefs OFF 不可） | `config_service.dart`, `dev_settings_screen.dart` | release でレガシー直呼び経路を塞ぐ | 鍵・コスト経路残存 |
| **C5** | Pro 訴求 **Analytics** | `pro_upgrade_dialog.dart`, 部屋差し替え call site | `room_image_upsell_shown` / `pro_upgrade_tapped` が記録される | 転換率が見えない |

### B-P1（骨格・文言・掃除）

| ID | 作業 | 主なファイル | 完了条件 |
|----|------|--------------|----------|
| **C6** | プロキシ成功時の **クライアント二重 `recordUsage` 緩和**（表示ズレ軽減）※完全解消はサーバ側 | scanner / chat / maintenance / market / room_image | プロキシ返却残量で同期、または二重減算しない |
| **C7** | **AdMob 本番 ID の dart-define 配線手順**＋ドキュメント | `admob_config.dart`, `FREE_ADS_STRATEGY.md` | `--dart-define=ADMOB_*` で差し替え可能であることの明記（本番ID取得自体は帰宅後でも可） |
| **C8** | **`StoreBillingService` クライアント stub**（購入未接続・「準備中」統一） | **新規** `store_billing_service.dart`, `plan_screen`, `credit_exhaustion_dialog`, `pubspec` | docs 参照と実装の欠落を解消。verify API は呼ばない |
| **C9** | Plan／コメント文言を「**アカウント生涯1回**」に統一 | `plan_screen.dart`, `room_photo_service.dart` コメント | 「1部屋・1回」誤解なし |
| **C10** | `home_screen` **未使用 import 削除** | `home_screen.dart` | analyze 警告解消 |
| **C11** | release で Pro自己申告・実APIキー等が効かない監査 | `config_service`, checklist | RELEASE_CHECKLIST と一致 |

### B-P2（任意・低リスク）

| ID | 作業 | 主なファイル |
|----|------|--------------|
| **C12** | `freeRoomImageLifetimePerRoom` レガシー削除 | `ai_usage_policy.dart` |
| **C13** | RoomFairUse / Free scan の widget・サービス追加テスト | `test/` |
| **C14** | Unit economics に Free 利用率シナリオ | `unit_economics_service.dart` |
| **C15** | 規約・プライバシー URL プレースホルダ（リンク枠のみ） | 設定 / Plan |

---

## C. 確認・検証（バックエンド本番不要）

### 自動

- [ ] `flutter analyze`
- [ ] `flutter test`（最低: `ai_usage_service_test`, `room_fair_use_service_test`, `config_service_test`, `scanner_service_test` があれば）
- [ ] C1–C3 追加後は Free 経路でクラウド非呼び出し／確認キャンセルのテスト

### 手動（デバッグビルド）

- [ ] 初回コピーが一貫（生涯1回・実写なし）
- [ ] Free: AIお試し1回 → 以降「差し替え（Pro）」／カードボタンで Pro ダイアログ
- [ ] Free: スキャン・メンテがローカル or 確認（C1/C2 後）
- [ ] Pro（開発者設定）: 再生成・差し替えでセットアップへ
- [ ] Analytics prefs に upsell イベント（C5 後）
- [ ] AdMob: debug=テストID／release+未定義=バナー無し

---

## D. 帰宅後（バックエンド／本番環境）— 本リストから除外

| ID | 内容 |
|----|------|
| B1 | Free `roomImage` lifetime サーバー強制 |
| B2 | `/v1/billing/verify`・Pro tier をレシート由来に |
| B3 | クレジット単一計上（サーバー正）— 完全版 |
| B4 | quota 永続化（Redis/Postgres） |
| — | Cloud Run デプロイ・Secret Manager・`GEMINI_API_KEY` |
| — | サーバー Soft/Hard Cap・監査ログ・GCP Billing アラート |
| — | 本番 IAP 完走（Store + 検証）※stub は C8 で先に可 |
| — | AdMob **本番アカウント／アプリ登録**（define 差し込みは C7） |

---

## E. 推奨着手順（今夜〜バックエンド待ちまで）

1. **C1 → C2**（Free 原価の穴を塞ぐ）  
2. **C3**（FairUse UI）  
3. **C5**（計測）  
4. **C4**（release プロキシ固定）  
5. **C9 / C10 / C12**（文言・掃除）  
6. **C6 / C8**（二重計上緩和・課金 stub）  
7. **C7 / C11 / 検証チェックリスト**  

政策まわりの部屋画像UXは完了。バックエンド前に価値が出るのは **Freeクラウド抑制・FairUse・計測・release固定**。
