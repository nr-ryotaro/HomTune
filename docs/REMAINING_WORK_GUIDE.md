# HomTune 残作業一覧と作業手順書

最終更新: 2026-07-14  
対象ブランチ目安: `main`（クライアント P0 反映済）  
**次アクションの実行順:** [`NEXT_ACTIONS_PHASE_A.md`](./NEXT_ACTIONS_PHASE_A.md)  
政策（済）: 部屋画像＝デフォルト or AI生成のみ／Free AI＝アカウント生涯1回／差し替えボタンは Free でも Pro 訴求

---

## 0. 全体マップ（やることの順番）

```
【Phase A｜帰宅後すぐ・バックエンド真実化】
  A1 Cloud Run + Secret + 本番 URL
  A2 AIクォータ永続化（B4）
  A3 Free roomImage lifetime サーバー強制（B1）
  A4 クレジット単一計上（B3）
  A5 Soft/Hard Cap + 監査ログ

【Phase B｜課金】
  B1 App Store / Play 商品登録
  B2 /v1/billing/verify + Pro tier 保存（B2）
  B3 Flutter in_app_purchase 接続
  B4 X-HomTune-Pro 自己申告廃止

【Phase C｜収益・提出】
  C1 AdMob 本番 ID
  C2 規約・Privacy URL
  C3 ストア素材・審査提出
  C4 Crashlytics / Billing アラート

【Phase D｜任意・品質】
  D1 追加テスト（C11/C13）
  D2 規約リンク枠（C15）
  D3 手動・自動品質ゲート
```

**推奨着手順:** A1 → A2 → A3 → A4 → A5 → B1〜B4 → C1〜C4 → D。

---

## 1. 完了済み（やらなくてよい）

| 領域 | 状態 |
|------|------|
| Gemini プロキシ Phase 0–1（クライアント移行） | 済 |
| Free AI部屋画像 lifetime=1（端末側） | 済 |
| 実写カスタム廃止・AI/デフォルト統一 | 済 |
| Free 差し替え → Pro ダイアログ | 済 |
| Free スキャン／メンテ local-first | 済 |
| RoomFairUse UI（オンボーディング） | 済 |
| release `preferAiProxy` 固定 | 済 |
| Pro 訴求 Analytics | 済 |
| プロキシ残量同期（二重計上の**緩和**） | 済（完全版は A4） |
| `StoreBillingService` stub | 済（本番接続は B3） |

---

## Phase A — バックエンド真実化（必須・帰宅後）

### A1. Cloud Run 本番デプロイ + Secret Manager

**目的:** 端末から到達可能な AI/リモコン API を本番に置き、`GEMINI_API_KEY` を Secret に閉じ込める。

**現状:** `backend/` はローカル `localhost:8787` 想定。Flutter は `RemoteApiConfig.baseUrl`（`--dart-define=HOMTUNE_API_BASE_URL=...`）。

**手順:**

1. GCP プロジェクト作成／課金有効化。
2. Artifact Registry にコンテナイメージを push（または Cloud Build）。
   ```bash
   cd backend
   # Dockerfile が無ければ Node の薄い Dockerfile を追加
   gcloud run deploy homtune-api \
     --source . \
     --region asia-northeast1 \
     --allow-unauthenticated   # 初期は要認証設計を後で強化可
   ```
3. Secret Manager に `GEMINI_API_KEY` を作成し、Cloud Run に `--set-secrets=GEMINI_API_KEY=GEMINI_API_KEY:latest`。
4. 環境変数:
   - `HOMTUNE_AI_MOCK=false`（本番）
   - 必要なら `NODE_ENV=production`
5. Flutter リリースビルド:
   ```bash
   flutter build apk --dart-define=HOMTUNE_API_BASE_URL=https://<cloud-run-url>
   ```
6. 疎通: 開発者設定または `POST /v1/ai/generate` の `connectionTest`（クレジット0）。

**完了条件:** 実機から本番 URL で AI 応答が返り、GCP ログにリクエストが残る。キーがリポ／APK に無い。

**注意:** 最初は `--allow-unauthenticated` でもよいが、最終的は API キー／Firebase Auth／App Check 等で保護する。

---

### A2. AI クォータ永続化（B4）

**目的:** `backend/lib/ai_quota.js` のインメモリ Map を DB 化し、再起動・水平スケールでも枠が消えないようにする。

**現状:** `monthlyCreditsUsed = new Map()`。プロセス再起動で 0 に戻る。

**手順:**

1. ストレージ選定（いずれか）:
   - **Firestore**（高速・実装簡単）: `homtune:ai:credits:{userId}:{YYYY-MM}` → used
   - **Postgres**（監査しやすい）: テーブル例
     ```sql
     CREATE TABLE ai_monthly_usage (
       user_id TEXT NOT NULL,
       month_key TEXT NOT NULL, -- '2026-07'
       used_credits INT NOT NULL DEFAULT 0,
       estimated_cost_usd NUMERIC(10,4) NOT NULL DEFAULT 0,
       PRIMARY KEY (user_id, month_key)
     );
     ```
2. `ai_quota.js` の `getUsed` / `tryConsume` / 返金パスを Redis/SQL の atomic increment に置換。
3. Cloud Run に接続先（`REDIS_URL` or `DATABASE_URL`）を Secret / 環境変数で渡す。
4. `backend/test/ai_proxy.test.js` に「消費→再読込後も残量維持」のテスト（インメモリモック or testcontainers）。

**完了条件:** API 再起動後も同一 `X-HomTune-User-Id` の残クレジットが維持される。

---

### A3. Free roomImage 生涯1回をサーバー強制（B1）

**目的:** クライアント prefs 改ざん・再インストールでも Free の部屋AIお試しを1回に制限する。

**現状:** Flutter `AiUsageService.canRunRoomImage` のみ。サーバーは月次クレジットのみ。

**手順:**

1. 永続ストアに lifetime テーブル／キーを追加:
   ```sql
   CREATE TABLE ai_room_image_lifetime (
     user_id TEXT PRIMARY KEY,
     generations INT NOT NULL DEFAULT 0,
     updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
   );
   ```
   Redis 例: `homtune:ai:roomImageLifetime:{userId}` → int
2. `POST /v1/ai/generate` で `feature === 'roomImage'` かつ非 Pro のとき:
   - `generations >= 1` → `403` or `402`（`quota_exceeded` / `room_image_lifetime`）
   - 成功時に atomic +1
3. Pro は従来どおり月次クレジット＋（必要なら部屋別上限は後続）。
4. Flutter: エラーコードを `showProUpgradeDialog(roomImage)` にマップ（既存文言あり）。
5. テスト: Free 2回目 `roomImage` が拒否されること。

**完了条件:** 同一 userId で Free が部屋AIを2回通せない（再インストール相当でもサーバー側で拒否）。

---

### A4. クレジット単一計上・完全版（B3）

**目的:** 「サーバー減算 + クライアント `recordUsage`」の食い違いをなくし、表示残量＝サーバー残量にする。

**現状:** クライアントはプロキシ `remainingCredits` があれば同期（緩和済）。残量未返却時はローカル加算も残る。サーバーが唯一の正ではない。

**手順:**

1. **サーバー:** 全成功レスポンスで必ず `usage.remainingCredits` / `creditLimit` を返す（既に概ねあり）。
2. **クライアント `AiUsageService`:**
   - プロキシ成功時は **必ず** サーバー値で `usedCredits` を上書き（加算しない）。
   - ローカル `canRunFeature` は「楽観チェック」か、プロキシ直前に `/v1/ai/usage`（任意追加）でスナップショット取得。
3. `preferAiProxy=false` のレガシー経路は release で塞いである前提。開発時のみローカル加算可。
4. `roomImage` の **lifetime カウント**はクライアント残してもよいが、**正は A3 のサーバー**。端末 lifetime は UX 用キャッシュ扱いと明記。
5. テスト: プロキシ1回後のローカル used == `creditLimit - remaining`。

**完了条件:** 二重減算で「実はまだサーバー枠があるのにローカル枯渇」／「ローカル余裕があるのにサーバー402」が再現テストで潰せる。

---

### A5. Soft/Hard Cap・レート制限・監査ログ

**目的:** Pro 平均 AI ≤ 約 $0.90〜$1.25 の天井をサーバーでも強制し、不正連打を防ぐ。

**手順:**

1. `ai_quota.js` に user 月次 `estimatedCostUsd` 累積（既に usage に近い値あり）を永続化し、Hard Cap（例 $1.25）超過で `402`。
2. Soft Cap（例 $0.95）はレスポンス warning フラグ or 別ヘッダー（クライアントは SnackBar）。
3. レート制限: userId + feature で「分間 N 回」（Cloud Armor / 自前トークンバケット）。
4. 構造化ログ（JSON）: `userId, feature, credits, costUsd, latencyMs, isPro, requestId`。
5. Cloud Logging → 必要なら BigQuery export。

**完了条件:** Cap 超過ユーザーが AI を追加消費できない。ログで機能別コストが追える。

---

## Phase B — 課金（必須・ストア収益化）

### B1. App Store / Google Play 商品登録

**目的:** Pro 月額 490円・追加クレジットの商品 ID を確定する。

**手順:**

1. **App Store Connect:** 自動更新サブスク `homtune_pro_monthly`（価格ティア 490円相当）、Consumable `addon_50` / `addon_120`。
2. **Play Console:** 同上 productId（`StoreBillingService` / `AiUsagePolicy.proAddonPacks` と一致させる）。
   - 現状 stub: `homtune_pro_monthly`, `addon_50`(50cr/350円), `addon_120`(120cr/780円)
3. サンドボックス／ライセンステスターを用意。
4. 税・課金表記文面を用意（日本語）。

**完了条件:** 両ストアで商品が Ready / Active、サンドボックスで購入可能。

---

### B2. `/v1/billing/verify` + サーバー Pro tier（監査 B2）

**目的:** Pro 判定を `X-HomTune-Pro: true` 自己申告から、検証済みレシートに置換する。

**手順:**

1. Backend にエンドポイント追加:
   ```http
   POST /v1/billing/verify
   { "platform": "ios"|"android", "productId": "...", "receiptOrPurchaseToken": "..." }
   ```
2. iOS: App Store Server API（または verifyReceipt 移行後の新しい検証）。
3. Android: Google Play Developer API `purchases.subscriptions:get`。
4. 検証成功で DB:
   ```sql
   CREATE TABLE user_entitlements (
     user_id TEXT PRIMARY KEY,
     is_pro BOOLEAN NOT NULL,
     pro_expires_at TIMESTAMPTZ,
     updated_at TIMESTAMPTZ
   );
   ```
5. `ai_generate` / リモコン API は **DB の is_pro** を参照。ヘッダーの `X-HomTune-Pro` は無視 or 開発専用。
6. 追加クレジット購入も同様に verify → `bonus_credits` 加算。

**完了条件:** ヘッダー偽 Pro では Pro 機能・Pro 枠が使えない。検証済みユーザーのみ Pro。

---

### B3. Flutter `in_app_purchase` 本番接続

**目的:** `StoreBillingService` stub を実課金に置き換える。

**手順:**

1. `pubspec.yaml` に `in_app_purchase` 追加。
2. `store_billing_service.dart`:
   - `purchaseProSubscription` / `purchaseAddon` / `restorePurchases` を実装。
   - 購入成功 → `POST /v1/billing/verify` → 成功時 `ConfigService.setSubscriptionTier(pro)`（サーバー正を prefer するなら「サーバーが Pro と答えた時だけ」）。
3. `plan_screen.dart` / `credit_exhaustion_dialog.dart` の「準備中」を購入ボタンに置換。
4. 開発者設定の Pro トグルは **kDebugMode のみ**維持（release では無効のまま）。
5. iOS/Android それぞれサンドボックスで購入→復元→失効を確認。

**完了条件:** サンドボックスで Free→Pro→機能解放→復元が通る。

---

### B4. クライアントから自己申告 Pro ヘッダーを削除

**目的:** `AiApiClient` / `remote_api_client.dart` の `X-HomTune-Pro` 依存を落とす。

**手順:**

1. サーバーが B2 完了後、クライアントは `X-HomTune-User-Id`（将来は Auth token）のみ送る。
2. ヘッダー組み立て箇所を削除／テスト更新（`ai_api_client_test.dart`）。
3. ドキュメント `backend/README.md`, `REMOTE_CONTROL.md`, `GEMINI_PROXY_SPEC.md` を更新。

**完了条件:** 偽ヘッダーでは Pro にならないことが E2E で確認できる。

---

## Phase C — 提出・副収益

### C1. AdMob 本番ユニット ID

**目的:** Free バナーを本番配信し、ARPU 試算（$0.12）を実測で置き換える。

**手順:**

1. AdMob でアプリ登録、バナーユニット作成（iOS/Android）。
2. ビルド:
   ```bash
   flutter build appbundle \
     --dart-define=ADMOB_ANDROID_BANNER_ID=ca-app-pub-xxx/yyy \
     --dart-define=ADMOB_IOS_BANNER_ID=ca-app-pub-xxx/zzz \
     --dart-define=HOMTUNE_API_BASE_URL=https://...
   ```
3. ネイティブ側 App ID（`AndroidManifest` / `Info.plist`）も本番に。※リポに android/ios が無い場合は `flutter create .` 後に設定。
4. **release + define無し = バナー非表示**（既に `admob_config.dart` で担保）。テスト ID を release に入れない。
5. 詳細: `docs/FREE_ADS_STRATEGY.md`。

**完了条件:** Free 実機で本番バナー表示、Pro で非表示。Mediation で eCPM が取れる。

---

### C2. プライバシーポリシー / 利用規約 / 課金表記 URL

**目的:** ストア審査必須の公開 URL。

**手順:**

1. 文書作成（収集データ: AdMob・Analytics prefs・購入・デバイス情報、AI 処理の説明）。
2. GitHub Pages / 自前サイト等にホスト。
3. アプリ内:
   - 設定 or Plan 画面にリンク（`url_launcher`）。
   - 初回同意が必要ならチェック UI。
4. App Store / Play のストア掲載欄に同じ URL。

**完了条件:** URL が外部から開け、ストアフォームに貼れる。

---

### C3. ストア一覧素材・審査提出

**手順:**

1. スクショ（5.5"/6.7" iPhone、Phone/タブレット Android）: ホーム、部屋AI、スキャン、資産、Pro比較。
2. 説明文（部屋画像政策・Free1回・Ads・IAPを正確に）。
3. 年齢レーティング、データセーフティ／App Privacy。
4. `docs/RELEASE_CHECKLIST.md` を上から消化。
5. 提出前ゲート:
   ```bash
   flutter analyze
   flutter test
   ```
   実機: スキャン（Freeはローカル）、部屋AIお試し1回、差し替えPro、チャット、資産L1、リモコン（Pro）。

**完了条件:** 審査提出完了（または TestFlight / 内部テスト配信）。

---

### C4. Crashlytics・GCP Billing アラート

**手順:**

1. Firebase プロジェクト連携、`firebase_crashlytics` 導入、release で有効。
2. GCP Billing 予算アラート 50/75/90/100%。
3. （任意）週次で Gemini 請求 vs サーバー `estimatedCostUsd` 合計を突き合わせ。

**完了条件:** 強制クラッシュがコンソールに出る。予算超過で通知が来る。

---

## Phase D — 任意（品質・運用）

| ID | 作業 | 手順概要 |
|----|------|----------|
| D1 | release 監査テスト | `config_service_test` に「kReleaseMode 相当で setPreferAiProxy(false) しても true」をモック／条件分岐で検証 |
| D2 | FairUse widget テスト | `onboarding_step2` で6部屋目トグル不可＋SnackBar の widget test |
| D3 | 規約リンク枠 | Plan／設定に「準備中」でもよいリンク行を追加（C2 の URL 差し替え前提） |
| D4 | Free→Pro ファネル週次 | Analytics prefs or 本番 Analytics で `room_image_upsell_shown` / `pro_upgrade_tapped` / 購入完了を集計。目標転換 ≥5% |
| D5 | L1 JSON 四半期更新 | `backend` 相場 JSON の更新手順をカレンダー化 |
| D6 | 原価ダッシュボード | 後回し可。ログ→BQ→Looker |

---

## 2. 作業時の共通チェックリスト

### バックエンド変更時

```bash
cd backend && npm test
# ローカル起動
HOMTUNE_AI_MOCK=true npm start
# 実キー
GEMINI_API_KEY=... npm start
```

### Flutter 変更時

```bash
flutter analyze
flutter test
# プロキシ接続（例）
flutter run --dart-define=HOMTUNE_API_BASE_URL=http://<LAN-IP>:8787
```

### 政策を壊していないか（回帰）

- [ ] Free: 部屋AIはアカウント生涯1回（サーバー強制後は再インストールでも）
- [ ] Free: カメラ／ギャラリーで部屋画像は変えられない
- [ ] Free: カード差し替え → Pro 説明
- [ ] Free: スキャン／メンテでクラウド課金しない
- [ ] Free: 部屋数 ≤5
- [ ] release: プロキシ OFF 不可、開発者設定に入れない

---

## 3. 依存関係（これが揃うまで提出しない）

| ブロック解除条件 | 依存 |
|------------------|------|
| 本番でクラウドAIが使える | A1 |
| Free お試しの改ざん耐性 | A2 + A3 |
| 残量表示が信頼できる | A4 |
| 収益が発生する | B1 + B2 + B3 |
| 偽 Pro が通用しない | B2 + B4 |
| Free 広告回収 | C1 |
| ストア提出 | C2 + C3 +（B・A の必須） |

---

## 4. ドキュメント参照

| 用途 | ファイル |
|------|----------|
| 本手順の要約 TODO | `NEXT_TODOS.md` |
| クライアント済／任意残り | `CLIENT_SIDE_TODOS.md` |
| 単価・提出チェック短リスト | `RELEASE_PREP_AND_ECONOMICS.md` |
| AI プロキシ契約 | `GEMINI_PROXY_SPEC.md` |
| 広告 | `FREE_ADS_STRATEGY.md` |
| 提出細目 | `RELEASE_CHECKLIST.md` |
| 政策ギャップ（参考） | `POLICY_IMPLEMENTATION_AUDIT.md` |

---

## 5. 「今日から手元でやれること」（バックエンド無し）

既にクライアント P0 は実装済。残り手元作業は主に:

1. **手動回帰**（デバッグビルド）— 上記「政策を壊していないか」
2. **D1–D3**（任意テスト・リンク枠）
3. **ストア／AdMob／GCP のアカウント準備**（実装は帰宅後でも、アカウント作成は先行可）
4. **規約ドラフト執筆**（C2）

本番キー・Cloud Run・IAP 検証・DB は帰宅後の Phase A/B で実施する。
