# Living Icons & Safety Guard 機能ドキュメント

## 概要

HomTuneアプリに、実利的な「リコール・安全管理（Safety Guard）」機能を実装しました。また、「生きているアイコン（Living Icons）」は将来の実装アイデアとして設計されています。

## 1. Living Icons（生きているアイコン）【将来の実装アイデア】

> **注意**: このセクションは将来の実装アイデアとして記録されています。現在は実装されていません。

### デザインコンセプト

Nani.now風のミニマルで愛らしい「目」を、既存の機械要素（レンズ、ランプ、水平器）と融合させるアイデアです。Thin Lineデザインを維持しながら、精密機械の中に魂が宿っているような質感を実現することを目指します。

### 表情の定義

#### Happy（元気）
- **表現**: きらきらした2つのドット
- **アニメーション**: 微かな瞬き（3-8秒間隔）
- **状態**: `DeviceStatus.healthy`

#### Tired（お疲れ）
- **表現**: 少しとろんとした目、位置が少し下がった状態、半開き
- **アニメーション**: 頻繁な瞬き（2-5秒間隔）
- **状態**: `DeviceStatus.error`

#### NeedCare（注意）
- **表現**: 不安そうな「○ ○」の表情（大きめの円）
- **アニメーション**: 左右に揺れる不安な動き
- **状態**: `DeviceStatus.needsMaintenance`

#### Danger/Recall（危険/リコール）
- **表現**: 「× ×」の表情、点滅効果
- **アニメーション**: 点滅する「×」
- **状態**: `DeviceStatus.recall` または `DeviceStatus.error`（リコール時）

### アニメーション実装

#### 瞬きアニメーション
- **間隔**: 表情に応じてランダム（Happy: 3-8秒、Tired: 2-5秒、NeedCare: 2.5-6秒）
- **Easing**: Elastic easing（上下に潰れるような弾力のある動き）
- **実装案**: `AnimationController`とElastic easing関数を使用

#### 表情アニメーション
- **Happy**: 微かな上下動（breathing）
- **Tired**: ゆっくりとした下向きの動き
- **NeedCare**: 左右に揺れる不安な動き（`math.sin`を使用）
- **Danger/Recall**: 点滅する「×」

### 実装予定ファイル

- `lib/widgets/anthropomorphic_device_icon.dart`
  - `EyeExpression` enum: 表情の定義（新規追加予定）
  - `_drawEyes` メソッド: 目の描画ロジック（新規追加予定）
  - `_startRandomBlink` メソッド: ランダムな瞬きのスケジューリング（新規追加予定）
  - `_elasticEasing` 関数: Elastic easing計算（新規追加予定）

## 2. Safety Guard（リコール・安全管理）

### データモデル

#### SafetyInfo
`lib/models/safety_info.dart`

```dart
class SafetyInfo {
  final String recallStatus;        // 'none' | 'active' | 'resolved'
  final RecallDetails? recallDetails;
  final double safetyScore;         // 0-100
  final String lastSafetyCheck;     // ISO 8601形式
  final List<String> safetyAdvice;  // 安全アドバイス
}
```

#### RecallDetails
```dart
class RecallDetails {
  final String modelNumber;
  final String manufacturer;
  final String date;
  final String description;
  final String reason;
  final String? manufacturerContactUrl;
}
```

### 安全性スコア計算式

安全性スコアは以下の要素から算出されます（合計100点満点）：

1. **購入からの経過年数（30%）**
   - 計算式: `min(yearsOwned / 10.0 * 30, 30.0)`
   - 10年経過で最大30点減点

2. **最終メンテナンス日（30%）**
   - 1年（365日）以上経過している場合に減点
   - 計算式: `min((daysSinceMaintenance - 365) / 365.0 * 10.0, 30.0)`

3. **製品標準耐用年数（20%）**
   - 標準耐用年数を超えている場合に減点
   - 計算式: `min(yearsOverLifespan * 4.0, 20.0)`
   - 標準耐用年数は`data/safety-mock-data.json`で定義

4. **リコール有無（20%）**
   - リコール対象の場合は20点減点

### リコールチェック

#### モック実装
`lib/services/safety_service.dart`の`checkRecall`メソッドは、`data/safety-mock-data.json`からリコール情報を検索します。

#### 将来的な拡張
外部API連携が可能な構造になっています：
```dart
// 将来的に外部API呼び出しに置き換え可能
// return await _checkRecallAPI(modelNumber, manufacturer);
```

### 安全アドバイス

`SafetyService.getSafetyAdvice`メソッドが、以下の条件に基づいてアドバイスを生成します：

1. **リコールチェック**: リコール対象の場合
   - 「この子が危ないかもしれないので、一度メーカーの窓口に相談してあげましょう」

2. **バッテリー関連**: PC、スマートフォン、ノートPCで3年以上経過
   - 「古いバッテリーは発火の恐れがあります。定期的な交換を検討しましょう」

3. **メンテナンス履歴**: 2年以上メンテナンス未実施
   - 「最終メンテナンスからX年経過しています。点検を検討しましょう」

4. **耐用年数超過**: 標準耐用年数を超えている場合
   - 「標準耐用年数（X年）を超えています。買い替えや専門家による点検を検討しましょう」

### 実装ファイル

- `lib/services/safety_service.dart`: リコールチェック、安全性スコア算出、安全アドバイス
- `lib/models/safety_info.dart`: 安全性情報のデータモデル
- `data/safety-mock-data.json`: リコール情報と標準耐用年数のモックデータ
- `lib/services/device_status_service.dart`: リコール状態の判定（`DeviceStatus.recall`追加）

## 3. UI統合

### デバイス詳細画面

`lib/widgets/device_detail_card.dart`に「安全診断ステータス」セクションを追加：

1. **リコール情報**
   - 赤い警告バナー
   - メッセージ: 「この子が危ないかもしれないので、一度メーカーの窓口に相談してあげましょう」
   - リコール詳細の表示
   - メーカー連絡先へのリンク（将来的に実装）

2. **安全性スコア**
   - 円形プログレスバー（0-100）
   - スコアに応じた色分け（80以上: 青、60-80: オレンジ、60未満: 赤）
   - ラベル表示（良好/注意/要確認）

3. **パーツ交換アラート**
   - カード形式で具体的なアドバイスを表示
   - アンバー色の背景で注意喚起

### アイコンの統合（将来の実装）

将来的に`AnthropomorphicDeviceIcon`に目の実装を追加する場合、自動的にリコール状態を検出し、表情を「× ×」に変更する設計です。

## 4. 標準耐用年数

`data/safety-mock-data.json`で定義：

- エアコン: 10年
- 冷蔵庫: 12年
- 洗濯機: 10年
- テレビ: 8年
- PC: 5年
- スマートフォン: 3年
- 掃除機: 8年
- 電子レンジ: 8年

## 5. 将来の拡張

### 外部API連携
- 消費者庁のリコール情報API
- NITE（製品評価技術基盤機構）のデータ

### マニュアル機能との統合
- リコール時に、スキャンしたマニュアルからメーカー連絡先を自動抽出・表示

### プッシュ通知
- リコール情報の更新時に通知
- 安全性スコアの低下時に通知

## 6. 技術的詳細（Living Icons実装時の参考）

### Elastic Easing関数（実装案）

```dart
double _elasticEasing(double t) {
  if (t == 0.0) return 0.0;
  if (t == 1.0) return 1.0;
  
  // Elastic out easing
  const c4 = (2 * math.pi) / 3;
  return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1;
}
```

### 目の描画ロジック（実装案）

目の位置とサイズは、アイコンのサイズに応じて動的に計算する設計：
- 目の間隔: `size * 0.15`
- 目のY位置: `center.dy - size * 0.15`
- 瞬きによるY位置調整: `baseEyeY + (1.0 - blinkValue) * 0.5`

## 7. デザイン原則（Living Icons実装時の参考）

- **Thin Line**: 極細の線（0.5px）で描画
- **ミニマル**: 2つのドットまたは小さな円をベース
- **アニメーション**: Elastic easingで自然な動き
- **感情表現**: 家電を「救う」トーンのメッセージ

## 8. ファイル一覧

### 新規作成
- `lib/models/safety_info.dart`
- `lib/services/safety_service.dart`
- `data/safety-mock-data.json`
- `docs/living-icons-safety.md`

### 修正
- `lib/models/device.dart` - `SafetyInfo`フィールド追加
- `lib/services/device_status_service.dart` - リコール状態の判定追加
- `lib/widgets/device_detail_card.dart` - 安全診断セクション追加
- `pubspec.yaml` - アセット追加

### 将来の実装予定（Living Icons）
- `lib/widgets/anthropomorphic_device_icon.dart` - 目の描画とアニメーション追加（未実装）
