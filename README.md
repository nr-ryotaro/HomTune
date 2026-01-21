# HomTune（ホームチューン）

家庭内の家電や機材を「資産」および「生活の構成要素」として最適に管理・調律するためのモバイルアプリケーションです。

## プロジェクト概要

HomTuneは、単なる家電管理を超えて、以下の機能を提供します：

- **インテリジェント・デバイス管理**: 型番から説明書への自動アクセス、AIトラブルシューティング、消耗品ナビ
- **スペーシャル・オーガナイザー**: 間取り図連携、収納管理、配線図メモ、Digital Vault（保証書・レシート保管）
- **アセット・オプティマイザー**: 中古価値の可視化、Eco-Tuning（ROIシミュレーション）、保証期限アラート

## 技術スタック

- **フロントエンド**: HTML5, CSS3 (Tailwind CSS), JavaScript (ES6+)
- **モバイルフレームワーク**: Capacitor 5.x
- **プラットフォーム**: Android / iOS
- **デザイン**: ミニマルデザイン（細い線をベースにした清潔感のあるUI）

### なぜCapacitorを選択？

- ✅ **エミュレータ対応**: Android Studio/Xcodeのエミュレータで完全にテスト可能
- ✅ **真のアプリ**: App Store/Google Playに公開可能な本物のアプリ
- ✅ **開発効率**: Web技術を活用し、高速な開発が可能
- ✅ **クロスプラットフォーム**: 1つのコードベースでAndroid/iOS対応

詳細は [技術スタック比較](docs/TECH_STACK_COMPARISON.md) を参照してください。

## ディレクトリ構造

```
HomTune/
├── docs/                    # 設計ドキュメント
│   ├── architecture.md      # アーキテクチャ設計
│   ├── data-structure.md    # データ構造定義
│   └── mobile-app-setup.md  # モバイルアプリセットアップガイド
├── src/                     # フロントエンドソースコード
│   ├── index.html           # メインHTML
│   ├── css/                 # スタイルシート
│   ├── js/                  # JavaScriptモジュール
│   │   ├── app.js           # アプリケーションエントリーポイント
│   │   ├── capacitor.js     # Capacitor統合
│   │   ├── deviceManager.js # デバイス管理
│   │   ├── ui.js            # UI制御
│   │   └── floorPlan.js    # 間取り図レンダリング
│   └── assets/              # 静的リソース
├── data/                    # データファイル
│   ├── mock-data.json       # モックデータ
│   └── floor-plan.json      # 間取り図データ
├── android/                 # Androidプロジェクト（生成される）
├── ios/                     # iOSプロジェクト（生成される）
├── capacitor.config.ts      # Capacitor設定
├── package.json             # 依存関係管理
└── vite.config.js           # Vite設定
```

## セットアップ

### 必要な環境

#### 共通
- Node.js 18以上
- npm または yarn

#### Android開発
- Java JDK 11以上
- Android Studio
- Android SDK

#### iOS開発（macOSのみ）
- Xcode 14以上
- CocoaPods

### インストール

```bash
npm install
```

### Web開発サーバーの起動

```bash
npm run dev
```

ブラウザで `http://localhost:5173` を開いてください。

### モバイルアプリのセットアップ

#### 1. Webアプリをビルド

```bash
npm run build
```

#### 2. Capacitorプラットフォームを追加（初回のみ）

```bash
# Android
npm run cap:add android

# iOS（macOSのみ）
npm run cap:add ios
```

#### 3. ネイティブコードを同期

```bash
npm run cap:sync
```

#### 4. 開発環境で開く

```bash
# Android Studioで開く
npm run cap:open:android

# Xcodeで開く（macOSのみ）
npm run cap:open:ios
```

### 一括コマンド

```bash
# Android: ビルド + 同期 + Android Studio起動
npm run cap:build:android

# iOS: ビルド + 同期 + Xcode起動
npm run cap:build:ios
```

詳細なセットアップ手順は [docs/mobile-app-setup.md](docs/mobile-app-setup.md) を参照してください。

### エミュレータでのテスト

エミュレータでのテスト方法は [エミュレータテストガイド](docs/EMULATOR_TESTING.md) を参照してください。

## 主要機能

### 間取り図機能

- **部屋別デバイス数表示**: 各部屋に配置されているデバイス数をバッジで表示
- **部屋タップ機能**: 部屋をタップすると、その部屋のデバイスのみを表示
- **フィルタリング**: 選択した部屋のデバイスをフィルタリング表示
- **視覚的フィードバック**: 選択された部屋がハイライト表示

詳細は [間取り図機能](docs/FLOOR_PLAN_FEATURE.md) を参照してください。

## モックデータ

プロジェクトには以下の3つのサンプルデバイスが含まれています：

1. **エアコン（リビング）**: フィルター掃除が3年以上未実施の警告状態
2. **MacBook Pro（書斎）**: 保証期限が間近（残り30日）の状態
3. **真空管アンプ（寝室）**: 定期的な端子清掃が必要な状態

## ネイティブ機能

Capacitorを使用して以下のネイティブ機能にアクセスできます：

- **カメラ**: デバイスの写真撮影
- **フォトライブラリ**: 画像の選択
- **ファイルシステム**: ファイルの保存・読み込み
- **ストレージ**: キー・バリューストレージ
- **ステータスバー**: ステータスバーの制御
- **スプラッシュスクリーン**: 起動画面の制御

## デザイン原則

- **ミニマリズム**: 不要な装飾を排除し、情報の本質に集中
- **細い線**: 0.5pxの細いボーダーで清潔感を演出
- **余白**: 贅沢な余白で視認性と高級感を確保
- **フォトジェニック**: 家電写真が映える洗練されたUI
- **モバイル最適化**: タッチ操作、レスポンシブデザイン、セーフエリア対応

## 開発ワークフロー

1. Webアプリを開発・テスト（`npm run dev`）
2. ビルド（`npm run build`）
3. Capacitorで同期（`npm run cap:sync`）
4. ネイティブIDEで開いて実行（`npm run cap:open:android` / `npm run cap:open:ios`）

## ライセンス

MIT
