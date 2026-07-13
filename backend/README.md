# HomTune API Proxy（リモコン・相場・AI）

開発用の Nature Remo / SwitchBot / L1 相場 / **Gemini AI プロキシ**です。  
本番では暗号化ストレージ・OAuth・**ストア課金検証**・DB 永続化に差し替えてください。

**今後の実装一覧・黒字試算:** `docs/IMPLEMENTATION_ROADMAP_AND_UNIT_ECONOMICS.md`  
**AI プロキシ仕様:** `docs/GEMINI_PROXY_SPEC.md`

## 起動

```bash
cd backend
# 開発（キー無しでも mock 応答）
HOMTUNE_AI_MOCK=true npm start

# 実 Gemini
GEMINI_API_KEY=your_key npm start
```

デフォルト: `http://localhost:8787`

## 開発時の Flutter 接続

- Android エミュレータ: 自動で `http://10.0.2.2:8787`
- 実機 / iOS シミュレータ: `--dart-define=HOMTUNE_API_BASE_URL=http://<LAN-IP>:8787`

## ヘッダー（開発）

| ヘッダー | 値 |
|----------|-----|
| `X-HomTune-User-Id` | 任意（省略時 `dev-user`） |
| `X-HomTune-Pro` | `true` で Pro 扱い |

## エンドポイント

### リモコン

`docs/REMOTE_CONTROL.md` を参照。

### L1 相場参照（MVP）

| メソッド | パス | 認証 |
|----------|------|------|
| GET | `/v1/market/reference?manufacturer=&modelNumber=` | Pro ヘッダー必須 |
| GET | `/v1/market/meta` | なし |

### AI（Gemini プロキシ・Phase 0）

| メソッド | パス | 認証 |
|----------|------|------|
| POST | `/v1/ai/generate` | ユーザーID +（機能により）Pro |

環境変数: `GEMINI_API_KEY`, `HOMTUNE_AI_MOCK`, `HOMTUNE_DEFAULT_AI_MODEL`  
詳細契約: `docs/GEMINI_PROXY_SPEC.md`

```bash
curl -s http://localhost:8787/v1/ai/generate \
  -H 'Content-Type: application/json' \
  -H 'X-HomTune-User-Id: dev' \
  -d '{"feature":"connectionTest","contents":[{"role":"user","text":"ok"}]}'
```

## テスト

```bash
cd backend && npm test
```
