# Node.js セットアップガイド

## 問題

`npm` コマンドが認識されないエラーが発生しています。これは、Node.js（npmを含む）がインストールされていないか、PATH環境変数に追加されていないことが原因です。

## 解決方法

### 方法1: Node.jsをインストール（推奨）

#### ステップ1: Node.jsをダウンロード

1. ブラウザで以下のURLを開く：
   - **公式サイト**: https://nodejs.org/
   - **LTS版（推奨）**: https://nodejs.org/ja/download/

2. **LTS（Long Term Support）版**をダウンロード
   - 例: `node-v20.x.x-x64.msi`（Windows 64bit版）

#### ステップ2: Node.jsをインストール

1. ダウンロードした `.msi` ファイルをダブルクリック
2. インストールウィザードに従って進む
3. **重要**: 「Add to PATH」オプションがチェックされていることを確認
4. 「Next」をクリックしてインストールを完了

#### ステップ3: インストール確認

**新しいPowerShellまたはコマンドプロンプトを開いて**（重要：既存のターミナルは閉じて新しく開く）：

```powershell
# Node.jsのバージョンを確認
node --version

# npmのバージョンを確認
npm --version
```

両方のコマンドがバージョン番号を表示すれば成功です。

---

### 方法2: 既にインストールされている場合（PATH設定）

Node.jsがインストールされているのに `npm` が認識されない場合は、PATH環境変数の設定が必要です。

#### ステップ1: Node.jsのインストール場所を確認

通常、Node.jsは以下の場所にインストールされます：
- `C:\Program Files\nodejs\`
- `C:\Program Files (x86)\nodejs\`
- `%AppData%\npm\`

#### ステップ2: PATH環境変数を設定

1. **Windowsキー + R** を押す
2. `sysdm.cpl` と入力してEnter
3. 「詳細設定」タブを開く
4. 「環境変数」ボタンをクリック
5. 「システム環境変数」の「Path」を選択して「編集」をクリック
6. 「新規」をクリックして、Node.jsのパスを追加：
   - `C:\Program Files\nodejs\`
   - `%AppData%\npm`
7. 「OK」をクリックしてすべてのダイアログを閉じる
8. **PowerShellを再起動**（重要）

#### ステップ3: 確認

新しいPowerShellで：

```powershell
node --version
npm --version
```

---

## インストール後の次のステップ

Node.jsのインストールが完了したら、HomTuneプロジェクトに戻って：

### 1. 依存関係をインストール

```powershell
cd C:\Users\81806\Desktop\HomTune
npm install
```

### 2. 開発サーバーを起動

```powershell
npm run dev
```

ブラウザが自動的に開き、アプリが表示されます。

---

## トラブルシューティング

### エラー: "npm は内部コマンドまたは外部コマンド..." が続く場合

1. **PowerShellを完全に閉じて、新しいウィンドウを開く**
2. 環境変数の変更を反映させるため、PCを再起動する場合もある

### エラー: "権限が不足しています"

管理者権限でPowerShellを実行：
1. Windowsキーを押す
2. 「PowerShell」と入力
3. 「Windows PowerShell」を右クリック
4. 「管理者として実行」を選択

### 別のバージョンのNode.jsが必要な場合

**nvm-windows**（Node Version Manager）を使用：

1. https://github.com/coreybutler/nvm-windows/releases からダウンロード
2. インストール後、以下のコマンドでNode.jsをインストール：
   ```powershell
   nvm install 20
   nvm use 20
   ```

---

## 確認コマンド一覧

インストールが正しく完了したか確認：

```powershell
# Node.jsのバージョン
node --version
# 期待される出力例: v20.11.0

# npmのバージョン
npm --version
# 期待される出力例: 10.2.4

# Node.jsのインストール場所
where.exe node
# 期待される出力例: C:\Program Files\nodejs\node.exe

# npmのインストール場所
where.exe npm
# 期待される出力例: C:\Program Files\nodejs\npm.cmd
```

---

## 参考リンク

- [Node.js公式サイト](https://nodejs.org/)
- [Node.js日本語ドキュメント](https://nodejs.org/ja/)
- [npm公式サイト](https://www.npmjs.com/)
