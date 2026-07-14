# ネクストアクション（main 反映後）

最終更新: 2026-07-14  
前提: クライアント政策・P0 実装は **main に反映済み**。  
詳細仕様・API契約: [`REMAINING_WORK_GUIDE.md`](./REMAINING_WORK_GUIDE.md) / [`GEMINI_PROXY_SPEC.md`](./GEMINI_PROXY_SPEC.md)

---

## いまやる順番（全体）

```
① 手元セットアップ＆回帰確認（本日・ネットあれば可）
② Phase A（帰宅後・バックエンド真実化）← 本ドキュメントの主対象
③ Phase B 課金（A のあと）
④ Phase C 提出・AdMob
```

**今夜〜手元:** ①のみ。  
**帰宅後:** ②を下の番号どおり。A1→A5 の順を崩さない。

---

## ① 手元で必要な作業（Phase A の前〜並行可）

順番どおり実施する。所要は「アカウント待ち」以外は短時間。

### ①-1. リポジトリ同期

```bash
git checkout main
git pull origin main
cd backend && npm install && npm test
# Flutter SDK がある環境で
flutter pub get
flutter test
flutter analyze
```

**完了条件:** `main` 最新、`npm test` / 主要 `flutter test` グリーン。

---

### ①-2. 政策・UX の手動回帰（デバッグビルド）

```bash
# ターミナル1
cd backend && HOMTUNE_AI_MOCK=true npm start

# ターミナル2（実機は LAN IP に変更）
flutter run --dart-define=HOMTUNE_API_BASE_URL=http://localhost:8787
```

チェックリスト:

| # | 操作 | 期待 |
|---|------|------|
| 1 | Free で部屋セットアップ → AI生成1回 | 成功 |
| 2 | 同じ or 別部屋で再生成 | Pro ダイアログ／拒否 |
| 3 | ホーム部屋カードの差し替え（★） | Pro 説明（実写なし） |
| 4 | Free でスキャン | ローカル抽出（クラウド課金しない） |
| 5 | Free でメンテ手順 | テンプレ／ダミー |
| 6 | オンボーディングで部屋を6つ選ぶ | 拒否＋Pro 訴求（Free最大5） |
| 7 | 開発者設定で Pro にして部屋再生成 | 可能 |

**完了条件:** 上記すべて確認。問題あれば Issue 化してから Phase A に入る。

---

### ①-3. アカウント・商品の「予約」（実装前でも可）

実装は帰宅後だが、**先にアカウントだけ**進めると Phase A/B が速い。

| 順 | 作業 | 成果物 |
|----|------|--------|
| 1 | GCP プロジェクト作成・課金有効 | プロジェクト ID |
| 2 | Gemini API キー発行（AI Studio / GCP） | キー（まだリポに載せない） |
| 3 | App Store Connect / Play Console アプリ枠 | バンドル ID 確定 |
| 4 | AdMob アプリ枠（ユニットは後でも可） | アプリ ID |
| 5 | 規約・Privacy のドラフト執筆 | Markdown / メモ |

**完了条件:** GCP と API キーが手元にある。ストア／AdMob は「作成開始」まででよい。

---

### ①-4. （任意）規約 URL 下書き・リンク枠

- 文書ドラフト → 帰宅後に Pages 等へホスト（Phase C2）。
- アプリ内リンク枠は任意（Plan 画面など）。

---

## ② Phase A — バックエンド真実化（帰宅後・この順で）

| 順 | ID | 題名 | 依存 |
|----|-----|------|------|
| 1 | **A1** | Cloud Run + Secret + 本番 URL | ①-3 の GCP/キー |
| 2 | **A2** | クォータ永続化（Redis or Postgres） | A1 |
| 3 | **A3** | Free `roomImage` lifetime=1 サーバー強制 | A2（永続先が必要） |
| 4 | **A4** | クレジット単一計上（サーバー正） | A2 |
| 5 | **A5** | Hard Cap・レート制限・監査ログ | A2〜A4 |

---

### A1. Cloud Run 本番デプロイ + Secret

**目的:** 実機が叩ける API。キーを Secret Manager に閉じる。

**手順ブレイク:**

1. `backend/` に本番用 Dockerfile が無ければ追加（Node 18+、`npm start`、PORT 尊重）。
2. Secret Manager に `GEMINI_API_KEY` 作成。
3. デプロイ:
   ```bash
   cd backend
   gcloud run deploy homtune-api \
     --source . \
     --region asia-northeast1 \
     --set-secrets=GEMINI_API_KEY=GEMINI_API_KEY:latest \
     --set-env-vars=HOMTUNE_AI_MOCK=false
   ```
4. 発行 URL を控える（例 `https://homtune-api-xxxx.a.run.app`）。
5. 疎通:
   ```bash
   curl -s -X POST "$URL/v1/ai/generate" \
     -H 'Content-Type: application/json' \
     -H 'X-HomTune-User-Id: smoke-1' \
     -d '{"feature":"connectionTest","contents":[{"role":"user","text":"ping"}]}'
   ```
6. Flutter を本番 URL で実行:
   ```bash
   flutter run --dart-define=HOMTUNE_API_BASE_URL=https://...
   ```

**完了条件:** mock 無しで connectionTest / 簡易 chat が成功。キーが Git・APK に無い。

**次へ進む前に:** Cloud Run のログで 200 が見えること。

---

### A2. AI クォータ永続化

**目的:** `backend/lib/ai_quota.js` のインメモリ Map をやめる（再起動で枠が消える穴を塞ぐ）。

**手順ブレイク:**

1. 選定: **Redis**（簡単）または **Cloud SQL Postgres**（監査向き）。
2. スキーマ例（Postgres）は `REMAINING_WORK_GUIDE.md` §A2。
3. `getUsed` / `tryConsume` / 返金を atomic に書き換え。
4. Cloud Run に `DATABASE_URL` または `REDIS_URL` を Secret で付与。
5. テスト:
   - 同一 user でクレジット消費 → プロセス再起動（または別インスタンス）→ 残量が維持。
6. `npm test` 更新。

**完了条件:** API 再デプロイ後も `X-HomTune-User-Id` 単位の残クレジットが消えない。

**次へ進む前に:** A3（lifetime）も同じストアに載せる前提で接続情報を固定する。

---

### A3. Free roomImage 生涯1回（サーバー強制）

**目的:** 再インストール／prefs 改ざんでも Free お試しを1回に制限。

**手順ブレイク:**

1. 永続キー/テーブル: `user_id → roomImage generations`（`REMAINING_WORK_GUIDE.md` §A3）。
2. `POST /v1/ai/generate` で `feature=roomImage` かつ非 Pro:
   - `generations >= 1` → `402`（`quota_exceeded` 等）
   - 成功時 atomic +1
3. Pro は月次クレジットのみ（部屋別月2はクライアント＋将来サーバー強化）。
4. Flutter: 該当エラーで `showProUpgradeDialog(roomImage)`。
5. テスト: Free 2回目 roomImage 拒否。

**完了条件:** 同じ userId で Free の部屋AIが2回通らない。

---

### A4. クレジット単一計上（サーバー正）

**目的:** 二重減算・表示ズレを解消。

**手順ブレイク:**

1. サーバー成功レスポンスに必ず `usage.remainingCredits` / `creditLimit`。
2. Flutter `AiUsageService.recordUsage`: プロキシ成功時は **加算せずサーバー値で上書き**（途中まで緩和済 → 全経路で徹底）。
3. （任意）`GET /v1/ai/usage` で起動時同期。
4. テスト: 1回消費後、ローカル used == `limit - remaining`。

**完了条件:** 「ローカル枯渇なのにサーバーまだある／その逆」が再現テストで潰せる。

---

### A5. Hard Cap・レート制限・監査ログ

**目的:** 原価天井と不正連打対策、あとから集計できるログ。

**手順ブレイク:**

1. user 月次 `estimatedCostUsd` を永続。Hard Cap 例 **$1.25** 超過 → 402。
2. Soft Cap 例 **$0.95** → 警告フラグ（クライアント SnackBar）。
3. userId+feature の分間レート制限。
4. 構造化ログ: `userId, feature, credits, costUsd, latencyMs, isPro`。
5. Cloud Logging 確認。GCP Billing 予算アラートは Phase C でも可だが、**予算アラートだけは A1 直後に先に付けてよい**。

**完了条件:** Cap 超過で追加 AI 不可。ログで機能別コストが追える。

---

## Phase A 完了後のゲート

全部 yes なら Phase B（課金）へ:

- [ ] 本番 URL で AI が動く（A1）
- [ ] 再起動しても月次クレジットが残る（A2）
- [ ] Free 部屋AIがサーバー lifetime 1（A3）
- [ ] クライアント残量＝サーバー残量（A4）
- [ ] Hard Cap / ログが効く（A5）
- [ ] ①-2 の回帰を**本番 URL**でも再実施

---

## Phase B 以降（ここには概要のみ）

| Phase | 内容 | 開始条件 |
|-------|------|----------|
| **B** | ストア商品 → `/v1/billing/verify` → IAP → `X-HomTune-Pro` 廃止 | Phase A ゲート通過 |
| **C** | AdMob 本番・規約 URL・ストア提出・Crashlytics | B で購入〜 Pro が通る |
| **D** | 追加テスト・ファネル週次など任意 | 並行可 |

手順の細部は [`REMAINING_WORK_GUIDE.md`](./REMAINING_WORK_GUIDE.md)。

---

## 困ったときの参照

| 症状 | 見る場所 |
|------|----------|
| ローカルで API に繋がらない | `RemoteApiConfig` / `HOMTUNE_API_BASE_URL` |
| mock ばかり返る | `HOMTUNE_AI_MOCK` / Secret のキー |
| Free が何回も部屋AIできる | A3 未実装（クライアントのみ制限） |
| 残量表示がおかしい | A4 |
| 偽ヘッダーで Pro | Phase B2/B4（A ではまだ自己申告のまま） |
