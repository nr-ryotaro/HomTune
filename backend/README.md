# HomTune API Proxy（リモコン連携）

開発用の Nature Remo / SwitchBot プロキシです。本番では暗号化ストレージ・OAuth・**ストア課金検証**に差し替えてください。

**今後の実装一覧・黒字試算:** `docs/IMPLEMENTATION_ROADMAP_AND_UNIT_ECONOMICS.md`

## 起動

```bash
cd backend
node server.js
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

データソース: `assets/data/market-reference-prices.json`（アプリ同梱と同一）

詳細: `docs/MARKET_L1_AND_INFRA.md`
