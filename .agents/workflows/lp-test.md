---
description: LPのローカル確認・テストフロー
---

# LP ローカル確認フロー

## 方法1: ブラウザで直接開く（最も簡単）

// turbo
1. エクスプローラーで `lp/index.html` をダブルクリック、またはターミナルで以下を実行:
```
start c:\Users\81806\Desktop\HomTune\lp\index.html
```

## 方法2: ローカルサーバーで確認（CORS等の問題回避）

// turbo
2. Python の簡易サーバーを起動:
```
cd c:\Users\81806\Desktop\HomTune\lp && python -m http.server 8080
```

3. ブラウザで `http://localhost:8080` を開く

4. 確認が終わったら `Ctrl+C` でサーバーを停止

## 方法3: Live Server（VS Code拡張）

5. VS Codeで `lp/index.html` を開く
6. 右クリック → 「Open with Live Server」
7. ファイルを編集すると自動リロードされる

## 確認チェックリスト

- [ ] Hero: 「家電を、調律する。」が表示される
- [ ] Hero: アプリモックアップ（Living Room / 90% / ¥607,000）が見える
- [ ] 「やることは、これだけ。」3カード表示
- [ ] Feature 01: 健康度バーのアニメーション（スクロールで発火）
- [ ] Feature 02: 資産価値デモ（エアコン / MacBook / 冷蔵庫）
- [ ] Feature 03: AIチャットデモ
- [ ] 健康度の説明: -15% / -5% / -5% ルールカード
- [ ] 健康度バッジ色: 緑95% / 黄65% / 赤30%
- [ ] Pricing: Free / Premium ¥300/月
- [ ] レスポンシブ: ブラウザ幅を狭めて768px以下・480px以下で崩れないか
- [ ] スクロールアニメーション: 各セクションがフェードインする
- [ ] ナビ: スクロール時に影がつく

## ファイル構成

```
lp/
├── index.html   ← LP本体
├── style.css    ← スタイル（レスポンシブ含む）
└── script.js    ← スクロールアニメーション
```

## LP編集時のヒント
- 画像は後日差し替え予定（Hero内のモックアップはCSS擬似要素で構成）
- 色の変更は `style.css` 冒頭部のカラー値を修正
- セクションの追加は `index.html` の HTML 構造を参照
