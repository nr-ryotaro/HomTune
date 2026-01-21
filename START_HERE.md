# 🚀 HomTune 起動方法

## ⚠️ 重要: 初回セットアップ

**Node.jsがインストールされていない場合**、まずNode.jsをインストールする必要があります。

### Node.jsのインストール確認

PowerShellで以下を実行：

```powershell
node --version
npm --version
```

**エラーが出る場合** → [Node.jsセットアップガイド](docs/NODEJS_SETUP.md) を参照してください。

---

## 最も簡単な方法：Webブラウザで起動

### ステップ1: 依存関係をインストール

```bash
npm install
```

### ステップ2: 開発サーバーを起動

```bash
npm run dev
```

**これだけです！** ブラウザが自動的に開き、アプリが表示されます。

---

## 確認できる機能

起動後、以下の機能を確認できます：

✅ **デバイス一覧**: 3つのサンプルデバイス（エアコン、MacBook Pro、真空管アンプ）が表示されます

✅ **メンテナンスステータス**: 警告バッジが表示されます
- エアコン: フィルター掃除が3年以上未実施（警告）
- MacBook Pro: 保証期限が間近（情報）

✅ **間取り図**: SVGで描画された間取り図にデバイスが配置されています

✅ **サマリーカード**: 警告数、メンテナンス予定、登録デバイス数が表示されます

---

## モバイルアプリとして起動する場合

詳細は [docs/LAUNCH_GUIDE.md](docs/LAUNCH_GUIDE.md) を参照してください。

### Android

```bash
npm install
npm run build
npx cap add android
npx cap sync
npx cap open android
```

### iOS (macOSのみ)

```bash
npm install
npm run build
npx cap add ios
cd ios/App && pod install && cd ../..
npx cap sync
npx cap open ios
```

---

## トラブルシューティング

### ❌ エラー: "npm" コマンドが認識されない

**これは最も一般的なエラーです。**

→ [Node.jsセットアップガイド](docs/NODEJS_SETUP.md) を参照してください。

**クイックフィックス:**
1. https://nodejs.org/ からNode.js（LTS版）をインストール
2. PowerShellを再起動
3. `node --version` で確認

### その他のエラー

詳細は [トラブルシューティングガイド](TROUBLESHOOTING.md) を参照してください。

#### よくある問題

1. **依存関係を再インストール**
   ```bash
   npm install
   ```

2. **データファイルを確認**
   ```bash
   # Windows (PowerShell)
   Test-Path public\mock-data.json
   ```

3. **ポートが使用中の場合**
   - 別のターミナルで `npm run dev` を実行している場合は停止してください
   - または `vite.config.js` の `server.port` を変更してください

---

## 次のステップ

- [起動ガイド](docs/LAUNCH_GUIDE.md) - 詳細な起動方法
- [アーキテクチャ設計](docs/architecture.md) - プロジェクトの全体像
- [モバイルアプリセットアップ](docs/mobile-app-setup.md) - モバイルアプリ開発の詳細
