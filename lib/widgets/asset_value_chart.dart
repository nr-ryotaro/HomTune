import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/valuation_service.dart';

/// 資産推移グラフウィジェット
/// 時間の経過とともに価値がどう下がっていくかを折れ線グラフで可視化
class AssetValueChart extends StatelessWidget {
  final Device device;

  const AssetValueChart({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    final valuationService = ValuationService();
    final assetValue = device.assetValue;

    return FutureBuilder<AssetValue>(
      future: assetValue != null 
          ? Future.value(assetValue)
          : valuationService.calculateAssetValue(device).catchError((e) {
              print('Error calculating asset value for chart: $e');
              // エラー時はデフォルト値を返す
              return AssetValue(
                purchasePrice: device.purchasePrice,
                currentUsedPrice: device.purchasePrice,
                depreciationRate: 0.0,
                lastPriceCheck: DateTime.now().toIso8601String(),
                priceHistory: [],
              );
            }),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error in asset chart: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        try {
          final calculatedAssetValue = snapshot.data!;
          return _buildChart(device, calculatedAssetValue);
        } catch (e) {
          print('Error building chart widget: $e');
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildChart(Device device, AssetValue assetValue) {
    try {
      // 購入日のパース（エラーハンドリング）
      DateTime purchaseDate;
      try {
        purchaseDate = DateTime.parse(device.purchaseDate);
      } catch (e) {
        print('Error parsing purchase date: $e');
        // デフォルト値として現在日時を使用
        purchaseDate = DateTime.now();
      }

      final now = DateTime.now();
      final elapsedMonths = _calculateElapsedMonths(purchaseDate, now);
    
    // グラフの期間（購入日から現在まで、最大60ヶ月）
    final chartMonths = math.min(elapsedMonths, 60);
    const chartWidth = 300.0;
    const chartHeight = 150.0;
    const padding = 20.0;

    // 帳簿価値の推移を計算
    final bookValuePoints = <Offset>[];
    final marketValuePoints = <Offset>[];
    
    final usefulLife = assetValue.usefulLife ?? 10.0;
    final purchasePrice = device.purchasePrice;
    
    // chartMonthsが0以下の場合は処理をスキップ
    if (chartMonths <= 0) {
      return Container(
        height: chartHeight + 40,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE5E5E5),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text(
            'データ不足のためグラフを表示できません',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    for (int i = 0; i <= chartMonths; i += 3) {
      try {
        final months = i.toDouble();
        final years = months / 12.0;
        
        // 帳簿価値
        final depreciationPerYear = usefulLife > 0 ? purchasePrice / usefulLife : 0.0;
        final totalDepreciation = depreciationPerYear * years;
        final bookValue = math.max(0, purchasePrice - totalDepreciation);
        
        // 市場価値（priceHistoryから補間、または簡易計算）
        int marketValue;
        if (assetValue.priceHistory.isNotEmpty && i < elapsedMonths) {
          // priceHistoryから補間
          marketValue = _interpolateMarketValue(
            assetValue.priceHistory,
            purchaseDate,
            months,
          );
        } else {
          // 簡易計算（購入価格の50%から線形減少）
          final ratio = usefulLife > 0 ? (years / usefulLife) * 0.5 : 0.0;
          marketValue = (purchasePrice * (1.0 - ratio)).round();
        }
        
        final x = padding + (i / chartMonths) * (chartWidth - padding * 2);
        final maxValue = purchasePrice > 0 ? purchasePrice.toDouble() : 1.0;
        final yBook = chartHeight - padding - (bookValue / maxValue) * (chartHeight - padding * 2);
        final yMarket = chartHeight - padding - (marketValue / maxValue) * (chartHeight - padding * 2);
        
        // 有効な座標のみ追加
        if (x.isFinite && yBook.isFinite && yMarket.isFinite) {
          bookValuePoints.add(Offset(x, yBook));
          marketValuePoints.add(Offset(x, yMarket));
        }
      } catch (e) {
        print('Error calculating chart point at $i: $e');
        // エラーが発生したポイントはスキップ
        continue;
      }
    }

      // データポイントが不足している場合は簡易表示
      if (bookValuePoints.isEmpty || marketValuePoints.isEmpty) {
        return Container(
          height: chartHeight + 40,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFFE5E5E5),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text(
              'データ不足のためグラフを表示できません',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        );
      }

      return Container(
        height: chartHeight + 40,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE5E5E5),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '資産価値推移',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: chartWidth,
              height: chartHeight,
              child: CustomPaint(
                painter: _AssetChartPainter(
                  bookValuePoints: bookValuePoints,
                  marketValuePoints: marketValuePoints,
                  maxValue: purchasePrice.toDouble(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('帳簿価値', Colors.blue),
                const SizedBox(width: 16),
                _buildLegendItem('市場価値', Colors.green),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error building chart: $e');
      return Container(
        height: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE5E5E5),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text(
            'グラフの表示中にエラーが発生しました',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 2,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  int _calculateElapsedMonths(DateTime start, DateTime end) {
    try {
      final years = end.year - start.year;
      final months = end.month - start.month;
      final result = years * 12 + months;
      return math.max(0, result); // 負の値にならないように
    } catch (e) {
      print('Error calculating elapsed months: $e');
      return 0;
    }
  }

  int _interpolateMarketValue(
    List<PriceHistory> priceHistory,
    DateTime purchaseDate,
    double months,
  ) {
    if (priceHistory.isEmpty) {
      return 0;
    }

    try {
      // 価格履歴を時系列でソート
      final sortedHistory = List<PriceHistory>.from(priceHistory)
        ..sort((a, b) {
          try {
            return a.date.compareTo(b.date);
          } catch (e) {
            return 0;
          }
        });

      if (sortedHistory.isEmpty) {
        return 0;
      }

      // 指定月数に対応する日付
      final targetDate = purchaseDate.add(Duration(days: (months * 30.44).round()));

      // 最も近い価格履歴を見つける
      PriceHistory? before;
      PriceHistory? after;

      for (var history in sortedHistory) {
        try {
          final historyDate = DateTime.parse(history.date);
          if (historyDate.isBefore(targetDate) || historyDate.isAtSameMomentAs(targetDate)) {
            before = history;
          } else {
            after = history;
            break;
          }
        } catch (e) {
          print('Error parsing history date: $e');
          continue;
        }
      }

      if (before == null && after == null) {
        return sortedHistory.first.price;
      }
      if (before == null) {
        return after!.price;
      }
      if (after == null) {
        return before.price;
      }

      // 線形補間
      try {
        final beforeDate = DateTime.parse(before.date);
        final afterDate = DateTime.parse(after.date);
        final totalDays = afterDate.difference(beforeDate).inDays;
        final targetDays = targetDate.difference(beforeDate).inDays;
        
        if (totalDays == 0) {
          return before.price;
        }

        final ratio = targetDays / totalDays;
        final interpolatedPrice = before.price + ((after.price - before.price) * ratio).round();
        return math.max(0, interpolatedPrice);
      } catch (e) {
        print('Error in linear interpolation: $e');
        return before.price;
      }
    } catch (e) {
      print('Error in _interpolateMarketValue: $e');
      return 0;
    }
  }
}

/// 資産価値グラフの描画
class _AssetChartPainter extends CustomPainter {
  final List<Offset> bookValuePoints;
  final List<Offset> marketValuePoints;
  final double maxValue;

  _AssetChartPainter({
    required this.bookValuePoints,
    required this.marketValuePoints,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 帳簿価値の線（青）
    if (bookValuePoints.length > 1) {
      final bookPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      final bookPath = Path();
      bookPath.moveTo(bookValuePoints[0].dx, bookValuePoints[0].dy);
      for (int i = 1; i < bookValuePoints.length; i++) {
        bookPath.lineTo(bookValuePoints[i].dx, bookValuePoints[i].dy);
      }
      canvas.drawPath(bookPath, bookPaint);
    }

    // 市場価値の線（緑）
    if (marketValuePoints.length > 1) {
      final marketPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      final marketPath = Path();
      marketPath.moveTo(marketValuePoints[0].dx, marketValuePoints[0].dy);
      for (int i = 1; i < marketValuePoints.length; i++) {
        marketPath.lineTo(marketValuePoints[i].dx, marketValuePoints[i].dy);
      }
      canvas.drawPath(marketPath, marketPaint);
    }

    // グリッド線（薄いグレー）
    final gridPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // 横軸のグリッド（価値の目盛り）
    for (int i = 0; i <= 4; i++) {
      final y = 20.0 + (i / 4) * (size.height - 40);
      canvas.drawLine(
        Offset(20, y),
        Offset(size.width - 20, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_AssetChartPainter oldDelegate) {
    return oldDelegate.bookValuePoints != bookValuePoints ||
        oldDelegate.marketValuePoints != marketValuePoints ||
        oldDelegate.maxValue != maxValue;
  }
}
