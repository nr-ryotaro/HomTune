# Zone mismatchとOverflowエラーの修正

## 修正したエラー

### 1. Zone mismatch エラー

**エラー内容:**
```
Zone mismatch.
The Flutter bindings were initialized in a different zone than is now being used.
```

**原因:**
`WidgetsFlutterBinding.ensureInitialized()`を`runZonedGuarded`の外で呼んでいたため、異なるゾーンで初期化されていた。

**修正:**
`WidgetsFlutterBinding.ensureInitialized()`を`runZonedGuarded`の中に移動し、同じゾーンで初期化と実行を行うように変更。

### 2. RenderFlex overflow エラー

**エラー内容:**
```
A RenderFlex overflowed by XX pixels on the right.
```

**原因:**
- `SummaryCard`のRowが画面幅を超えていた
- `DeviceCard`のRowが画面幅を超えていた

**修正:**

#### SummaryCard
- Columnを`Expanded`でラップ
- テキストに`overflow: TextOverflow.ellipsis`を追加
- アイコンとの間に`SizedBox`を追加

#### DeviceCard
- Rowを`Wrap`に変更して自動折り返し
- デバイス名を`Flexible`でラップ
- バッジに`overflow: TextOverflow.ellipsis`を追加

#### HomeScreen
- サマリーカードを`LayoutBuilder`で囲み、モバイル時は縦並びに変更

## 修正したファイル

- `lib/main.dart`: Zone mismatchエラーの修正
- `lib/widgets/summary_card.dart`: Overflowエラーの修正
- `lib/widgets/device_card.dart`: Overflowエラーの修正
- `lib/screens/home_screen.dart`: レスポンシブレイアウトの改善

## テスト方法

1. エミュレータを起動
2. `flutter run`でアプリを実行
3. アプリが正常に起動することを確認
4. レイアウトが正しく表示されることを確認
5. ログにエラーがないことを確認
