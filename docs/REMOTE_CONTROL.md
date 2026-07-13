# スマートリモコン連携（Nature Remo / SwitchBot）

## 概要

登録済み家電（`Device`）を Nature Remo または SwitchBot API 経由で操作する。**Pro プラン限定**。

| 項目 | 内容 |
|------|------|
| 先行 | Nature Remo（IR: エアコン・テレビ・照明） |
| 2nd | SwitchBot（IR + Bot / Curtain / Plug） |
| 認証 | トークンは **HomTune API プロキシ** にのみ保管 |
| 操作枠 | Pro 月 300 回（Remo 30req/5min をサーバーで吸収） |

## アーキテクチャ

```
Flutter App → HomTune API Proxy → Nature Remo / SwitchBot
                ↑ Pro 検証・レート制限・監査ログ
```

クライアントは `RemoteControlService` 経由でプロキシのみ呼び出す。Remo Bearer / SwitchBot HMAC はアプリに埋め込まない。

## データモデル

- [`DeviceRemoteLink`](../lib/models/device_remote_link.dart) — `Device.remoteLink`
- [`RemoteAppliance`](../lib/models/remote_appliance.dart) — 外部家電一覧 DTO

## API プロキシ（ローカル開発）

[`backend/`](../backend/) の Express サーバー:

| Method | Path | 説明 |
|--------|------|------|
| GET | `/health` | 死活 |
| POST | `/v1/integrations/remo/link` | Remo トークン登録 |
| DELETE | `/v1/integrations/remo/link` | 連携解除 |
| GET | `/v1/integrations/remo/status` | 連携状態 |
| GET | `/v1/integrations/remo/appliances` | 家電一覧 |
| POST | `/v1/remote/command` | 操作送信 |
| POST | `/v1/integrations/switchbot/link` | SwitchBot token/secret |
| GET | `/v1/integrations/switchbot/appliances` | デバイス一覧 |

ヘッダー（開発用）:

- `X-HomTune-User-Id`: ユーザー ID（省略時 `dev-user`）
- `X-HomTune-Pro`: `true` で Pro 扱い

## レート制限

| 層 | 制限 |
|----|------|
| Nature Remo Cloud | 30 req / 5 min（公式） |
| HomTune Pro ユーザー | 300 操作 / 月 |
| クライアント debounce | 同一操作 3 秒以内は拒否 |

## 登録フロー連携（型番ベース）

家電登録時に型番・カテゴリ・アーキタイプからリモコン対応可否を判定し、対象家電のみ Pro 設定へ誘導する。

```
型番入力 / スキャン
    ↓
RemoteCompatibilityService（カタログ照合）
    ↓ 対応あり
登録フォームにヒント表示
    ↓ 登録完了
DeviceRegistrationRemotePromptScreen
    ├ Free → Pro 訴求
    └ Pro  → アカウント連携 → 紐付けウィザード
```

| 判定優先度 | ソース | 例 |
|------------|--------|-----|
| 1 | 型番パターン | `CS-ZX2811`, `XRJ-65A95K` |
| 2 | アーキタイプ | `living_ac`, `living_tv` |
| 3 | カテゴリ | エアコン、テレビ、照明 |
| — | 除外カテゴリ | 冷蔵庫、炊飯器、加湿器 等 |

カタログ: [`assets/data/remote-compatibility-catalog.json`](../assets/data/remote-compatibility-catalog.json)

## UI プレビュー（開発者向け）

デバッグビルドで **開発者設定 → リモコン UI プレビュー** から、API なしで画面設計を確認できます。

| 確認項目 | 内容 |
|----------|------|
| シナリオ切替 | Free / Pro未紐付け / エアコン / TV / 照明 / Bot / カーテン |
| 登録フロー | ヒント・リマインダー・登録後プロンプト |
| 実画面 | 紐付けウィザード・アカウント連携 |

ルート: `/remote-control-preview`（`kDebugMode` のみ）

コンポーネント: [`RemoteControlPanel`](../lib/widgets/remote_control/remote_control_panel.dart)

## UX 拡張（登録〜紐付け）

| 機能 | 説明 |
|------|------|
| スマート推薦 | `RemoteApplianceRanker` が型番・部屋・カテゴリで候補をスコアリング |
| テスト送信 | 紐付け前に電源 OFF 信号を安全送信 |
| 設定リマインダー | 未紐付けの対象家電をホーム・詳細に表示（7日スヌーズ） |
| 文脈 Pro 訴求 | 登録直後・リマインダーから家電名入り Pro ダイアログ |

## 操作 UI

- 家電登録時 → **リモコン対応ヒント** + 登録後プロンプト
- 家電詳細 → **リモコン** セクション（資産・メンテとは独立）
- 設定 → **スマートリモコン連携**（アカウント・紐付けウィザード）
- Free: ロック表示 + Pro 訴求

### 物理リモコン風スキン（メーカー別）

型番・メーカーからテンプレートを解決し、**実機リモコンに近いレイアウト**で描画する。

| カテゴリ | スキン | 対応メーカー（例） |
|----------|--------|-------------------|
| エアコン | `physicalAircon` | Panasonic / DAIKIN / 三菱 / 日立 / 東芝 / 標準 |
| テレビ | `physicalTv` | SONY BRAVIA / VIERA / AQUOS / REGZA / 標準 |
| 照明 | `physicalLight` | 丸型 ON/OFF トグル |
| Bot・カーテン | `physicalSimple` | 大型アクションボタン |

各スキンの特徴:

- **エアコン**: ブランド帯 + 擬似 LCD + 丸型電源 + 運転モード行 + 温度ダイヤル
- **テレビ**: ブランド帯 + D-pad（CH/VOL）+ HDMI 行 + Netflix 等の色分けボタン
- **照明**: ランプ型の丸ボタン ON/OFF
- **テーマ**: `RemoteSkinTheme` がメーカー配色（Sony はダークボディ等）を担当

実装: `lib/widgets/remote_control/skins/`

## メーカー別リモコン UI テンプレート

型番・メーカーから UI レイアウトを自動選択し、家電詳細のリモコン欄に反映する。

| 項目 | 内容 |
|------|------|
| カタログ | [`assets/data/remote-ui-templates.json`](../assets/data/remote-ui-templates.json) |
| 解決 | `RemoteUiTemplateService`（型番パターン > メーカー名 > プロファイル default） |
| モデル | [`RemoteUiTemplate`](../lib/models/remote_ui_template.dart) |
| UI | [`RemoteControlTemplatePanel`](../lib/widgets/remote_control/remote_control_template_panel.dart) |

### テンプレート例

| プロファイル | テンプレート ID | 特徴 |
|--------------|-----------------|------|
| aircon | `aircon_panasonic` | ナノイー、風向などメーカー固有ボタン |
| aircon | `aircon_daikin` | ストリーマ、換気など |
| aircon | `aircon_mitsubishi` | ムーブアイ、清浄など |
| tv | `tv_sony_bravia` | 入力切替・Netflix/YouTube 等 |
| tv | `tv_panasonic_viera` | VIERA 向けサブスク・HDMI |
| tv | `tv_sharp_aquos` | AQUOS 向けレイアウト |

### ユーザー カスタマイズ

- ボタンの **表示/非表示**（`hiddenButtonIds`）
- **よく使う** 行へのピン留め（`pinnedButtonIds`）
- デバイス ID 単位で `SharedPreferences` に保存（`RemoteUiPreferencesService`）
- 家電詳細 → リモコン → **カスタマイズ** から編集

学習信号が必要なボタン（タイマー、HDMI、サブスク等）は `signalKey` で `DeviceRemoteLink.signalIds` を参照。未登録時は操作前にエラーを表示。

## カテゴリ別コントロール

| カテゴリ | 操作 |
|----------|------|
| エアコン | 冷房/暖房/除湿/送風/自動、温度 ±、エコ、タイマー、風向 |
| テレビ | 電源、音量 ±、消音、チャンネル ±、入力、サブスクアプリ |
| 照明 | 電源 ON/OFF |
| 汎用 IR | 学習済み信号（`sendSignal`） |
| Bot / Curtain（SwitchBot） | press / 開閉 |

## チャット連携

「リビングのエアコンつけて」等 → `RemoteCommandIntentParser` → Pro かつ `remoteLink` ありなら API 送信（AI クレジット消費なし）。

## 本番チェックリスト

1. OAuth（Remo）/ 暗号化トークン保管
2. StoreKit / Play Billing サーバー検証と `X-HomTune-Pro` 連携
3. プライバシーポリシーに操作ログ条項
4. Web プレビューでは連携 UI 非表示

## 関連

- [FREE_PRO_COMPARISON_AND_ROADMAP.md](FREE_PRO_COMPARISON_AND_ROADMAP.md)
- [AI_PRICING_AND_BILLING.md](AI_PRICING_AND_BILLING.md)
