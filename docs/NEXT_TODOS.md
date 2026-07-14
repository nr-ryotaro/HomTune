# HomTune 今後の TODO（整理版）

最終更新: 2026-07-14  
政策: **部屋画像 = デフォルト or AI生成のみ（実写なし）／Free AI はアカウント生涯1回／カードの差し替えボタンは Free でも常時表示→Pro 訴求**

関連: [`POLICY_IMPLEMENTATION_AUDIT.md`](./POLICY_IMPLEMENTATION_AUDIT.md), [`RELEASE_PREP_AND_ECONOMICS.md`](./RELEASE_PREP_AND_ECONOMICS.md), [`GEMINI_PROXY_SPEC.md`](./GEMINI_PROXY_SPEC.md)

---

## いま完了していること

| 領域 | 状態 |
|------|------|
| Gemini プロキシ Phase 0–1（クライアント移行） | 済 |
| Free AI部屋画像（クライアント lifetime=1） | 済 |
| 実写カスタム廃止＋AI/デフォルト統一 | 済 |
| Freeでも部屋カード「画像差し替え」→ Pro 説明ダイアログ | 済（本作業） |
| クレジット定数 40/120 クライアント＝サーバー | 済（インメモリ） |
| RoomFairUseService（Free5/Pro10）ロジック | サービス＋テストのみ（UI未配線） |

---

## Now（次に着手すべき順）

### 1. サーバー真実化（リリース blocker）

| ID | TODO | 現状 | 完了条件 |
|----|------|------|----------|
| B1 | Free `roomImage` **生涯1回をサーバー強制** | `ai_quota.js` は月次クレジットのみ | userId 単位 lifetime を永続保存し、再インストールでも再実行不可 |
| B2 | Pro tier を **レシート検証結果** にする | `X-HomTune-Pro` 自己申告 | `/v1/billing/verify` 後にサーバーが tier を保持 |
| B3 | **クレジット二重計上解消** | プロキシ減算 + クライアント `recordUsage` | サーバー usage を正、クライアントは同期のみ |
| B4 | AI クォータ **永続化**（Redis/Postgres） | インメモリ（再起動で消える） | 本番ストレージ＋月次リセット |

### 2. Free 原価・成長ガード（KPI直撃）

| ID | TODO | 現状 | 完了条件 |
|----|------|------|----------|
| H3 | Free **スキャン／メンテをローカル優先** | プロキシONだとクラウド課金しやすい | Freeは確認 or 月次キャップ、チャット相当の local-first |
| H4 | **RoomFairUse を部屋追加UIに配線** | サービス未接続 | 超過時メッセージ＋Pro訴求、上限 Enforce |
| M1 | Free 差し替え導線の効果計測 | ダイアログ表示のみ | `room_image_upsell_shown` / `pro_upgrade_tapped` イベント |

### 3. 収益クローズ

| ID | TODO | 現状 | 完了条件 |
|----|------|------|----------|
| IAP | **本番 IAP**（Pro 490円 + 追加クレジット） | 課金骨格・開発者 Pro 切替のみ | StoreKit/Play Billing 購入〜復元 |
| ADS | **AdMob 本番ユニット ID** | テストID想定 | 本番ID＋eCPM計測で ARPU 仮定を置換 |

---

## Next（初回リリース〜安定化）

- [ ] Cloud Run（または同等）本番デプロイ + Secret Manager
- [ ] リリースビルドで `preferAiProxy` 固定・クライアント鍵経路閉塞
- [ ] 開発者設定の削除 or `kDebugMode` 限定
- [ ] サーバー Soft/Hard Cap（Pro 平均 AI ≤ $0.90 監視）
- [ ] GCP Billing アラート（50/75/90/100%）
- [ ] プロキシ監査ログ（userId / feature / credits / latency）
- [ ] プライバシーポリシー／利用規約／課金表記 URL
- [ ] ストア素材（スクショ・説明・データセーフティ）
- [ ] Crashlytics 等のクラッシュ監視
- [ ] Free→Pro ファネル週次レビュー（転換≥5%目標）

---

## Later（スケール）

- [ ] 原価ダッシュボード（機能別日次）
- [ ] モデル自動切替（負荷時 lite 固定）
- [ ] 追加パック価格 A/B
- [ ] `freeRoomImageLifetimePerRoom` レガシー削除
- [ ] 法人／家族プラン

---

## 推奨スプリント割（技術単位）

1. **Sprint A — サーバー quota 真実化**: B1 + B4 + B3  
2. **Sprint B — 課金**: IAP + B2（verify → tier）  
3. **Sprint C — Free 抑制**: H3 + H4 + AdMob 本番  
4. **Sprint D — 提出**: 鍵閉塞・規約・ストア素材・実機ゲート  

政策・部屋画像 UX のクライアント側は概ね完了。残り主戦場は **サーバー強制・課金・Freeクラウド抑制**。
