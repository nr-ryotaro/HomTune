# 🔧 HomTune トラブルシューティングガイド

## ❌ エラー: "npm" コマンドが認識されない

### 症状

```
npm: 用語 'npm'は、コマンドレット、関数、スクリプトファイル、または操作可能なプログラムの名前として認識されません。
```

### 原因

Node.jsがインストールされていないか、PATH環境変数に追加されていません。

### 解決方法

**詳細は [docs/NODEJS_SETUP.md](docs/NODEJS_SETUP.md) を参照してください。**

#### クイックフィックス

1. **Node.jsをインストール**
   - https://nodejs.org/ からLTS版をダウンロード
   - インストール時に「Add to PATH」を確認

2. **PowerShellを再起動**
   - 既存のターミナルを閉じる
   - 新しいPowerShellを開く

3. **確認**
   ```powershell
   node --version
   npm --version
   ```

4. **プロジェクトに戻る**
   ```powershell
   cd C:\Users\81806\Desktop\HomTune
   npm install
   npm run dev
   ```

---

## ❌ エラー: "Connection Failed" / "ERR_CONNECTION_REFUSED"

### 症状

ブラウザで `http://localhost:5173` にアクセスできない

### 原因

開発サーバーが起動していません（通常、`npm` コマンドが実行できないため）

### 解決方法

1. 上記の「npmコマンドが認識されない」問題を解決
2. `npm run dev` を実行
3. ターミナルに「Local: http://localhost:5173」と表示されることを確認

---

## ❌ エラー: "Cannot find module '@capacitor/core'"

### 症状

モジュールが見つからないエラー

### 解決方法

```powershell
npm install
```

---

## ❌ エラー: "Failed to load mock-data.json"

### 症状

データファイルが読み込めない

### 解決方法

```powershell
# ファイルが存在するか確認
Test-Path public\mock-data.json

# 存在しない場合、コピー
Copy-Item data\mock-data.json public\mock-data.json
```

---

## ❌ エラー: ポート5173が使用中

### 症状

```
Error: listen EADDRINUSE: address already in use :::5173
```

### 解決方法

#### 方法1: 既存のプロセスを停止

```powershell
# ポート5173を使用しているプロセスを確認
netstat -ano | findstr :5173

# プロセスIDを確認して終了（例: PIDが12345の場合）
taskkill /PID 12345 /F
```

#### 方法2: 別のポートを使用

```powershell
npm run dev -- --port 3000
```

---

## ✅ 正常に動作している場合の確認項目

### 開発サーバーが起動している

ターミナルに以下のような表示が出ている：

```
  VITE v5.x.x  ready in xxx ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

### ブラウザで表示される内容

- ✅ デバイス一覧（3つのサンプルデバイス）
- ✅ 間取り図（SVGで描画）
- ✅ サマリーカード（警告数、メンテナンス予定、登録デバイス数）

---

## 📞 さらなるヘルプ

問題が解決しない場合：

1. **エラーメッセージ全体を確認**
   - ターミナルのエラーメッセージをコピー
   - ブラウザのコンソール（F12）のエラーも確認

2. **環境情報を確認**
   ```powershell
   node --version
   npm --version
   Get-Command node | Select-Object Source
   ```

3. **ドキュメントを確認**
   - [Node.jsセットアップガイド](docs/NODEJS_SETUP.md)
   - [起動ガイド](docs/LAUNCH_GUIDE.md)
   - [クイックスタート](docs/QUICK_START.md)
