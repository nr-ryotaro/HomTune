# npm install エラー修正ガイド

## エラー: "No matching version found for @capacitor/storage@^5.0.6"

### 原因

Capacitor 5では、`@capacitor/storage` パッケージは `@capacitor/preferences` に名前が変更されました。

### 解決方法

#### ステップ1: package.jsonを修正（既に修正済み）

`@capacitor/storage` を `@capacitor/preferences` に変更しました。

#### ステップ2: 依存関係を再インストール

```powershell
npm install
```

これで正常にインストールできるはずです。

---

## エラー: "'vite' は、内部コマンドまたは外部コマンド..."

### 原因

`npm install` が失敗したため、`vite` がインストールされていません。

### 解決方法

上記のステップ2を実行して `npm install` が成功すれば、`vite` もインストールされ、`npm run dev` が動作するようになります。

---

## 確認手順

### 1. インストールが成功したか確認

```powershell
npm install
```

エラーが出ずに完了すれば成功です。

### 2. 開発サーバーを起動

```powershell
npm run dev
```

以下のような表示が出れば成功：

```
  VITE v5.x.x  ready in xxx ms

  ➜  Local:   http://localhost:5173/
```

---

## 参考情報

- Capacitor 5では `@capacitor/storage` → `@capacitor/preferences` に変更
- 詳細: https://capacitorjs.com/docs/v5/apis/preferences
