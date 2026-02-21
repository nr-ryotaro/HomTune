import 'dart:math' as math;
import '../models/device.dart';
import 'asset_valuation_service.dart';

/// 売却アドバイザーモデル — 1台分のデバイスの売却分析結果
class SellAdvice {
  /// 売却推奨度スコア（0〜100）
  final int score;

  /// 推奨度ラベル（🔥 今が売り時 / ⏰ そろそろ売り時 / 📉 様子見）
  final String label;

  /// 判定の理由（具体的な説明）
  final String reason;

  /// 推定売却価格
  final int estimatedSellPrice;

  /// 帳簿価値との差額（正なら得、負なら損）
  final int profitOrLoss;

  /// Book Value と Market Value の交差予定月（null = 既に交差済み or 交差しない）
  final int? monthsUntilCrossover;

  /// 推奨アクション
  final String action;

  /// 判定タイプ（sell_now / sell_soon / hold / keep）
  final String type;

  SellAdvice({
    required this.score,
    required this.label,
    required this.reason,
    required this.estimatedSellPrice,
    required this.profitOrLoss,
    this.monthsUntilCrossover,
    required this.action,
    required this.type,
  });
}

/// 売却タイミング最適化アドバイザーサービス
///
/// Book Value と Market Value の推移を分析し、最適な売却タイミングを提案する。
/// 主な判定ロジック:
/// 1. Market > Book × 1.15 → 🔥 今が売り時
/// 2. Market > Book → ⏰ そろそろ売り時
/// 3. 交差点が 3ヶ月以内 → ⏰ 売却検討推奨
/// 4. それ以外 → 📉 様子見
class SellAdvisorService {
  static final SellAdvisorService _instance = SellAdvisorService._internal();
  factory SellAdvisorService() => _instance;
  SellAdvisorService._internal();

  final AssetValuationService _valuationService = AssetValuationService();

  /// デバイスの売却アドバイスを生成
  SellAdvice analyze(Device device) {
    final bookValue = _valuationService.calculateBookValue(device);
    final marketValue = _valuationService.simulateMarketValue(device);
    final diff = marketValue - bookValue;
    final ratio = bookValue > 0 ? marketValue / bookValue : 0.0;
    final elapsed = device.yearsOwned;

    // 交差点算出（Book Value > Market Value になるまでの月数）
    final crossoverMonths = _estimateCrossoverMonths(device);

    // 判定ロジック
    if (ratio > 1.15) {
      // Market が Book を 15% 以上上回っている → 🔥 今が売り時
      return SellAdvice(
        score: math.min(100, (ratio * 60).round()),
        label: '🔥 今が売り時',
        reason: '市場価値が帳簿価値を ${((ratio - 1) * 100).toStringAsFixed(0)}% 上回っています。'
            '相場が良い今のうちに売却すると、${_formatCurrency(diff.abs())} のプラスになります。',
        estimatedSellPrice: marketValue,
        profitOrLoss: diff,
        monthsUntilCrossover: crossoverMonths,
        action: 'メルカリやヤフオクで出品を検討しましょう',
        type: 'sell_now',
      );
    } else if (ratio > 1.0) {
      // Market > Book だが僅差 → ⏰ そろそろ売り時
      return SellAdvice(
        score: (60 + (ratio - 1.0) * 200).round().clamp(60, 80),
        label: '⏰ そろそろ売り時',
        reason: '市場価値が帳簿価値を ${_formatCurrency(diff)} 上回っています。'
            '${crossoverMonths != null ? "あと約${crossoverMonths}ヶ月で交差する見込みです。" : ""}',
        estimatedSellPrice: marketValue,
        profitOrLoss: diff,
        monthsUntilCrossover: crossoverMonths,
        action: '1〜3ヶ月以内の売却がおすすめです',
        type: 'sell_soon',
      );
    } else if (crossoverMonths != null &&
        crossoverMonths <= 3 &&
        crossoverMonths > 0) {
      // 交差点が 3ヶ月以内 → ⏰ 売却検討推奨
      return SellAdvice(
        score: 55,
        label: '⏰ 売却検討推奨',
        reason: '約${crossoverMonths}ヶ月後に市場価値が帳簿価値を上回る見込みです。'
            '売却準備を始めるのに良いタイミングです。',
        estimatedSellPrice: marketValue,
        profitOrLoss: diff,
        monthsUntilCrossover: crossoverMonths,
        action: '出品準備を始めましょう',
        type: 'sell_soon',
      );
    } else if (elapsed > 5 && marketValue < device.purchasePrice * 0.3) {
      // 価値が大幅に下落 → 買い替え検討
      return SellAdvice(
        score: 30,
        label: '🔄 買い替え検討',
        reason: '購入から${elapsed.toStringAsFixed(0)}年が経過し、資産価値が大幅に下落しています。'
            '最新モデルへの買い替えも選択肢です。',
        estimatedSellPrice: marketValue,
        profitOrLoss: diff,
        monthsUntilCrossover: null,
        action: '新モデルとの比較検討を',
        type: 'hold',
      );
    } else {
      // それ以外 → 📉 様子見
      return SellAdvice(
        score: 20,
        label: '📉 様子見',
        reason: '現時点では売却よりも継続使用がおすすめです。'
            '${crossoverMonths != null ? "約${crossoverMonths}ヶ月後に売り時が来る見込みです。" : "市場動向を定期的にチェックしましょう。"}',
        estimatedSellPrice: marketValue,
        profitOrLoss: diff,
        monthsUntilCrossover: crossoverMonths,
        action: '定期的に市場価値をチェック',
        type: 'keep',
      );
    }
  }

  /// 全デバイスの売却チャンス数を集計
  int countSellOpportunities(List<Device> devices) {
    return devices.where((d) {
      final advice = analyze(d);
      return advice.type == 'sell_now' || advice.type == 'sell_soon';
    }).length;
  }

  /// 今が売り時のデバイスリストを取得
  List<Device> getSellNowDevices(List<Device> devices) {
    return devices.where((d) {
      final advice = analyze(d);
      return advice.type == 'sell_now';
    }).toList();
  }

  /// Book Value と Market Value の交差予定月を推定
  ///
  /// 今後 24ヶ月間をシミュレーションし、Market > Book になるタイミングを検出
  int? _estimateCrossoverMonths(Device device) {
    final now = DateTime.now();
    final currentBook = _valuationService.calculateBookValue(device);
    final currentMarket = _valuationService.simulateMarketValue(device);

    // すでに Market > Book なら交差済み
    if (currentMarket > currentBook) return null;

    // 24ヶ月先までシミュレーション
    for (int m = 1; m <= 24; m++) {
      final futureDate = DateTime(now.year, now.month + m, now.day);
      final futureBook =
          _valuationService.calculateBookValue(device, targetDate: futureDate);
      final futureMarket =
          _valuationService.simulateMarketValue(device, targetDate: futureDate);

      if (futureMarket > futureBook) {
        return m;
      }
    }

    return null; // 24ヶ月以内には交差しない
  }

  /// 通貨フォーマット
  String _formatCurrency(int amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(1)}万円';
    }
    return '¥${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }
}
