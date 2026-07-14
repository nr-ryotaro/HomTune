# HomTune 今後の TODO（整理版）

最終更新: 2026-07-14  
政策: **部屋画像 = デフォルト or AI生成のみ（実写なし）／Free AI はアカウント生涯1回／カードの差し替えボタンは Free でも常時表示→Pro 訴求**

**運用メモ:** バックエンド設定・新規追加は帰宅後。  
**次にやること（順番つき）:** [`NEXT_ACTIONS_PHASE_A.md`](./NEXT_ACTIONS_PHASE_A.md)  
**残作業の詳細手順:** [`REMAINING_WORK_GUIDE.md`](./REMAINING_WORK_GUIDE.md)  
クライアント済の整理: [`CLIENT_SIDE_TODOS.md`](./CLIENT_SIDE_TODOS.md)

関連: [`POLICY_IMPLEMENTATION_AUDIT.md`](./POLICY_IMPLEMENTATION_AUDIT.md), [`RELEASE_PREP_AND_ECONOMICS.md`](./RELEASE_PREP_AND_ECONOMICS.md), [`GEMINI_PROXY_SPEC.md`](./GEMINI_PROXY_SPEC.md), [`CLIENT_SIDE_TODOS.md`](./CLIENT_SIDE_TODOS.md), [`REMAINING_WORK_GUIDE.md`](./REMAINING_WORK_GUIDE.md), [`NEXT_ACTIONS_PHASE_A.md`](./NEXT_ACTIONS_PHASE_A.md)

---

## いま完了していること

| 領域 | 状態 |
|------|------|
| Gemini プロキシ Phase 0–1（クライアント移行） | 済 |
| Free AI部屋画像（クライアント lifetime=1） | 済 |
| 実写カスタム廃止＋AI/デフォルト統一 | 済 |
| Freeでも部屋カード「画像差し替え」→ Pro 説明ダイアログ | 済 |
| クレジット定数 40/120 クライアント＝サーバー | 済（インメモリ） |
| RoomFairUseService（Free5/Pro10）ロジック | サービス＋**オンボーディングUI配線済** |

---

## 分割: バックエンド待ち vs 今すぐ

### 帰宅後（バックエンド／本番）

| ID | TODO |
|----|------|
| B1 | Free `roomImage` lifetime サーバー強制 |
| B2 | レシート検証 → Pro tier（`X-HomTune-Pro` 自己申告廃止） |
| B3 | クレジット単一計上（サーバー正）完全版 |
| B4 | AI クォータ永続化（Redis/Postgres） |
| — | Cloud Run・Secret・Hard Cap・監査ログ・GCPアラート |
| — | 本番 IAP 完走・AdMob アカウント登録 |

### 今すぐ（クライアントのみ）— 要約

詳細表・完了条件・検証は **[`CLIENT_SIDE_TODOS.md`](./CLIENT_SIDE_TODOS.md)**。

| 優先 | ID | 一言 |
|------|-----|------|
| P0 | C1 / C2 | Free スキャン・メンテをローカル優先 |
| P0 | C3 | RoomFairUse を UI 配線 |
| P0 | C4 | release で preferAiProxy 固定 |
| P0 | C5 | Pro 訴求 Analytics |
| P1 | C6–C11 | 二重計上緩和・AdMob define・IAP stub・文言・掃除・release監査 |
| P2 | C12–C15 | レガシー削除・追加テスト・試算・規約URL枠 |

---

## Next（初回リリース〜・多くは帰宅後込み）

- [ ] Cloud Run 本番 + Secret Manager
- [ ] リリースビルドで `preferAiProxy` 固定（**C4 は先にクライアント可**）
- [ ] 開発者設定の削除 or kDebug 限定（入口は済・Config 監査は C11）
- [ ] サーバー Soft/Hard Cap
- [ ] GCP Billing アラート
- [ ] プロキシ監査ログ
- [ ] プライバシー／利用規約／課金表記 URL（枠だけ C15）
- [ ] ストア素材
- [ ] Crashlytics
- [ ] Free→Pro ファネル週次（計測は C5）

---

## Later

- [ ] 原価ダッシュボード
- [ ] モデル自動切替
- [ ] 追加パック A/B
- [ ] `freeRoomImageLifetimePerRoom` 削除（**C12**）
- [ ] 法人／家族プラン

---

## 推奨スプリント割（更新）

1. **今夜（client）**: ~~C1→C2→C3→C5→C4→掃除~~ **実装済**（`CLIENT_SIDE_TODOS.md`）  
2. **帰宅後（server）**: B1 + B4 + B3 → B2 + IAP  
3. **提出前**: AdMob本番・鍵閉塞確認・規約・ストア素材  
