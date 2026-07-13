# Gemini サーバープロキシ仕様（実装準備）

最終更新: 2026-07-13  
対象コミット起点: `main`（`96824f2`）  
関連: `AI_PRICING_AND_BILLING.md`, `IMPLEMENTATION_ROADMAP_AND_UNIT_ECONOMICS.md`

---

## 1. 推奨判断: **Gemini プロキシを本番 IAP より先に実装**

| 観点 | Gemini プロキシ先行 | 本番 IAP 先行 |
|------|---------------------|---------------|
| 原価リスク | **クライアント鍵漏洩・改ざんクォータで原価が無制限になり得る**を止められる | 課金は入るが、鍵が端末にある限りコスト穴は残る |
| リリース可否 | 本番ビルドは既にクライアント Gemini を原則禁止。プロキシ無しだとクラウド AI が事実上使えない | IAP 無しでも Pro トグルで UX 検証は可能（収益は立たない） |
| 外部依存 | `GEMINI_API_KEY` + 自前 API ホストだけで完結 | App Store / Play Console・商品 ID・サンドボックス審査が必須 |
| 後続作業 | サーバークォータ・レート制限・キルスイッチの土台になる | レシート検証サーバーが必要（プロキシ認証とも接続） |
| 並行余地 | IAP は `StoreBillingService` 骨格のまま並行準備可 | プロキシ後に `/v1/billing/verify` を同じ API に載せるのが自然 |

**結論:** 黒字運用の前提は「鍵を端末に置かないこと」。収益化より先に **コスト穴を塞ぐ**。IAP はプロキシ後に、サーバー Pro 判定へ直結させる。

---

## 2. API 契約（確定案）

### `POST /v1/ai/generate`

Headers:

| Header | 必須 | 説明 |
|--------|------|------|
| `Content-Type` | yes | `application/json` |
| `X-HomTune-User-Id` | yes（省略時 `dev-user`） | クォータ主体 |
| `X-HomTune-Pro` | no | MVP: 自己申告（レシート検証後に廃止） |

Request:

```json
{
  "feature": "chat | scanner | roomImage | maintenance | marketValuation | connectionTest",
  "model": "gemini-2.5-flash-lite",
  "systemInstruction": "optional",
  "contents": [
    { "role": "user", "text": "..." },
    { "role": "model", "text": "..." }
  ],
  "responseFormat": "text | json",
  "requestedCredits": 2,
  "clientRequestId": "optional-uuid"
}
```

Success (`200`):

```json
{
  "ok": true,
  "text": "...",
  "modelId": "gemini-2.5-flash-lite",
  "feature": "chat",
  "usage": {
    "creditsCharged": 2,
    "remainingCredits": 38,
    "creditLimit": 40,
    "estimatedCostUsd": 0.02
  }
}
```

Error:

| HTTP | `error.code` |
|------|--------------|
| 400 | `bad_request` |
| 402 / 429 | `quota_exceeded` |
| 403 | `forbidden_feature`（例: Free で marketValuation） |
| 503 | `upstream_unconfigured`（API キー未設定かつ mock 無効） |
| 502 | `upstream_error` |

```json
{
  "ok": false,
  "error": {
    "code": "quota_exceeded",
    "message": "...",
    "retryable": false
  },
  "usage": { "remainingCredits": 0, "creditLimit": 40 }
}
```

### 機能別クレジット（サーバー正）

| feature | credits | Pro 必須 |
|---------|--------:|----------|
| connectionTest | 0 | no |
| chat | `requestedCredits` clamp 1–4（default 2） | no |
| scanner | 3 | no |
| roomImage | 2 | no（部屋枠はクライアント側も併用） |
| maintenance | 2 | no |
| marketValuation | 2 | **yes** |

月次クレジット上限（MVP・インメモリ）: Free **40** / Pro **120**（`AiUsagePolicy` と一致）。

---

## 3. 実装フェーズ

### Phase 0（本 PR・準備完了目標）

- [x] 本仕様ドキュメント
- [x] `backend/lib/ai_quota.js` — インメモリ月次クレジット
- [x] `backend/lib/ai_generate.js` — 入力検証 + Gemini REST / mock
- [x] `POST /v1/ai/generate` 配線
- [x] Flutter `AiApiClient` + Config `preferAiProxy`
- [x] Node ユニットテスト（検証・クォータ・mock）

### Phase 1（次 PR・サービス移行）

1. `MarketPriceGeminiService` → プロキシ
2. `RoomImageGenerationService`（スタイル JSON のみ）
3. `ScannerService`
4. `MaintenanceCalendarService`（Gemini 経路）
5. `ChatService`（履歴を client `contents[]` 化）
6. `ConfigService.testCloudConnection` → `connectionTest`
7. リリース経路でクライアント `GEMINI_API_KEY` を不要化

### Phase 2（サーバー正の強化）

- Hard Cap USD・レート制限・キルスイッチ
- レシート検証と Pro ヘッダー廃止
- Redis/Postgres 永続化

---

## 4. 環境変数

| 変数 | 説明 |
|------|------|
| `GEMINI_API_KEY` | サーバーのみ保持 |
| `HOMTUNE_AI_MOCK` | `true` で upstream なしでも固定応答（CI/開発） |
| `HOMTUNE_DEFAULT_AI_MODEL` | 省略時 `gemini-2.5-flash-lite` |
| `PORT` | 既存（既定 8787） |

---

## 5. クライアント移行メモ

- 既存 `google_generative_ai` 直呼びは Phase 1 で削除予定
- Chat の `ChatSession` は廃止し、クライアントが `contents` を保持
- 初期はクライアント `AiUsageService` も併用し、二重減算を避けるため **プロキシ成功時はサーバー `usage` を正としてローカルへ同期**（Phase 1 詳細で実装）
