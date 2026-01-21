# HomTune アーキテクチャ設計書

## プロジェクト概要

HomTune（ホームチューン）は、家庭内の家電や機材を「資産」および「生活の構成要素」として最適に管理・調律するためのモバイルアプリケーションです。

## 技術スタック

- **フロントエンド**: HTML5, CSS3 (Tailwind CSS), JavaScript (ES6+)
- **モバイルフレームワーク**: Capacitor 5.x
- **プラットフォーム**: Android / iOS
- **ビルドツール**: Vite
- **デザイン原則**: 
  - 細い線（Thin Line）をベースにしたミニマルデザイン
  - 余白を贅沢に使用
  - 高級機材を扱うような精密で知的な質感
  - モバイル向けタッチ操作の最適化

## ディレクトリ構造

```
HomTune/
├── docs/                    # 設計ドキュメント
│   ├── architecture.md      # アーキテクチャ設計（本ファイル）
│   ├── data-structure.md    # データ構造定義
│   ├── mobile-app-setup.md  # モバイルアプリセットアップガイド
│   └── api-design.md        # API設計（将来拡張用）
├── src/                     # フロントエンドソースコード
│   ├── index.html           # メインHTML
│   ├── css/                 # スタイルシート
│   │   └── main.css         # メインスタイル（Tailwind + カスタム）
│   ├── js/                  # JavaScriptモジュール
│   │   ├── app.js           # アプリケーションエントリーポイント
│   │   ├── capacitor.js     # Capacitor統合（ネイティブ機能）
│   │   ├── deviceManager.js # デバイス管理ロジック
│   │   ├── ui.js            # UI制御
│   │   └── floorPlan.js     # 間取り図レンダリング
│   └── assets/              # 静的リソース
│       ├── images/          # 画像ファイル
│       └── icons/           # アイコン
├── data/                    # データファイル
│   ├── mock-data.json       # モックデータ
│   └── floor-plan.json      # 間取り図データ
├── android/                 # Androidプロジェクト（Capacitor生成）
├── ios/                     # iOSプロジェクト（Capacitor生成）
├── capacitor.config.ts      # Capacitor設定
├── package.json             # 依存関係管理
├── vite.config.js           # Vite設定
├── tailwind.config.js       # Tailwind設定
└── README.md                # プロジェクト説明
```

## コア機能モジュール

### 1. インテリジェント・デバイス管理
- **deviceManager.js**: デバイスの登録、更新、削除
- **capacitor.js**: ネイティブ機能へのアクセス（カメラ、ストレージ等）
- **ui.js**: UI制御とデバイスカードのレンダリング

### 2. スペーシャル・オーガナイザー
- **floorPlan.js**: 間取り図の表示とデバイス配置（SVGレンダリング）
- **capacitor.js**: ファイルシステムへのアクセス（保証書・レシート保存）

### 3. アセット・オプティマイザー
- **deviceManager.js**: 資産価値の計算と表示
- **ui.js**: メンテナンスアラートと保証期限の表示

### 4. ネイティブ機能統合
- **capacitor.js**: CapacitorServiceクラス
  - カメラ: 写真撮影、フォトライブラリからの選択
  - ファイルシステム: ファイルの保存・読み込み
  - ストレージ: Preferences API（キー・バリューストレージ）
  - ステータスバー・スプラッシュスクリーン制御

## データ構造

### デバイスオブジェクト
```javascript
{
  id: string,
  name: string,
  modelNumber: string,
  category: string,
  purchaseDate: string,
  yearsOwned: number,
  room: string,
  location: string,
  manualUrl: string,
  maintenanceStatus: {
    lastMaintenance: string,
    nextMaintenance: string,
    alerts: array
  },
  consumables: array,
  warranty: {
    manufacturer: string,
    store: string,
    expiryDate: string
  },
  photos: array,
  documents: array
}
```

### 間取り図データ
```javascript
{
  rooms: [
    {
      id: string,
      name: string,
      coordinates: { x: number, y: number },
      devices: array
    }
  ]
}
```

## UI/UX設計原則

1. **ミニマリズム**: 不要な装飾を排除し、情報の本質に集中
2. **視覚的階層**: 重要な情報（アラート、メンテナンス期限）を明確に
3. **レスポンシブデザイン**: モバイル・タブレット・デスクトップに対応
4. **アクセシビリティ**: キーボードナビゲーション、スクリーンリーダー対応

## モバイルアプリアーキテクチャ

### Capacitor統合

Capacitorを使用して、Webアプリをネイティブモバイルアプリとして動作させます。

- **WebView**: ネイティブWebViewでWebアプリを実行
- **ブリッジ**: JavaScriptとネイティブコード間の通信
- **プラグイン**: カメラ、ファイルシステム等のネイティブ機能へのアクセス

### プラットフォーム対応

- **Android**: Android Studioで開発、APK/AABとしてビルド
- **iOS**: Xcodeで開発、App Store経由で配布

### データ永続化

- **Preferences API**: 軽量データの保存（設定、デバイス情報等）
- **Filesystem API**: 大きなファイル（画像、PDF等）の保存
- **将来**: SQLiteプラグインでローカルデータベース対応

## 将来の拡張性

- **型番認識API**: 写真から型番を自動抽出（カメラ機能と連携）
- **中古価格API**: リアルタイム価格情報の取得
- **AI統合**: OpenAI/Claude APIとの連携
- **プッシュ通知**: メンテナンスアラートの通知
- **バックエンド**: Node.js/Express または Python/FastAPI
- **データベース**: PostgreSQL または MongoDB
- **クラウド同期**: 複数デバイス間でのデータ同期

## 開発フェーズ

### Phase 1: プロトタイプ（完了）
- 静的HTML/CSS/JS
- モックデータでの動作確認
- UI/UXの検証
- Capacitor統合

### Phase 2: 機能実装（進行中）
- Capacitorストレージ連携
- 基本的なCRUD操作
- メンテナンスアラート機能
- カメラ機能の実装

### Phase 3: 高度な機能
- AI統合
- 外部API連携
- プッシュ通知
- クラウド同期
