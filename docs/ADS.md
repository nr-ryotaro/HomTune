# Free プラン広告（AdMob バナー）

## 方針

| プラン | 広告 |
|--------|------|
| Free | ホーム・家電一覧・部屋一覧の**下部バナーのみ** |
| Pro | **広告なし** |

## 非表示ゾーン

- オンボーディング
- 家電詳細（資産・メンテ・取説）
- 登録フロー・スキャン・開発者設定
- Web プレビュー

## 実装

- `google_mobile_ads` アダプティブバナー
- `FreePlanAdBody` + `ProUpsellStrip` + `HomTuneBannerAd`
- `AdPolicy` / `AdService`

## 本番ビルド

AdMob の本番 ID を dart-define で指定:

```bash
flutter build apk \
  --dart-define=ADMOB_ANDROID_BANNER_ID=ca-app-pub-xxxxxxxx/yyyyyyyyyy
```

`AndroidManifest.xml` の `APPLICATION_ID` も本番アプリ ID に差し替えること。

未設定の release ビルドではバナーは**表示されません**（テスト ID の誤配信防止）。

## 分析イベント

- `ad_sdk_initialized`
- `ad_banner_loaded` / `ad_banner_failed`
- `pro_upsell_tap`

## 表示確認（デバッグのみ）

開発者設定（ホーム右上の歯車）→ **プラン切替（表示確認・テスト用）** で Free / Pro を切り替え。リリース前に当該 UI は削除予定。

## 今後

- UMP（EEA 同意）
- ストア課金連携後、`ProUpgradeDialog` の CTA を本番決済へ
