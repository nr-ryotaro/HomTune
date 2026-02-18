import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/device.dart';
import '../services/asset_valuation_service.dart';

/// 資産推移グラフウィジェット (fl_chart使用)
class AssetValueChart extends StatelessWidget {
  final Device device;

  const AssetValueChart({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    final assetValuationService = AssetValuationService();
    // グラフデータ生成
    final graphData = assetValuationService.generateGraphData(device);
    final bookValueSpots = graphData['bookValue'] ?? [];
    final marketValueSpots = graphData['marketValue'] ?? [];

    if (bookValueSpots.isEmpty && marketValueSpots.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('データがありません')),
      );
    }

    // Y軸の最大値を計算（少し余裕を持たせる）
    double maxY = 0;
    for (final spot in bookValueSpots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    for (final spot in marketValueSpots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    maxY = maxY * 1.1;

    return Column(
      children: [
        // 凡例
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('帳簿価値', Colors.blue),
            const SizedBox(width: 16),
            _buildLegendItem('市場価値', Colors.green),
          ],
        ),
        const SizedBox(height: 16),
        // グラフ
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 8),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0xffe7e8ec),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return const FlLine(
                      color: Color(0xffe7e8ec),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 3, // 3ヶ月ごと
                      getTitlesWidget: (value, meta) {
                        // valueは月数
                        if (value % 3 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${value.toInt()}ヶ月',
                            style: const TextStyle(
                              color: Color(0xff68737d),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        // 金額表示（万単位など）
                        if (value == 0) return const Text('0');
                        final kValue = value / 10000;
                        return Text(
                          '${kValue.toStringAsFixed(0)}万',
                          style: const TextStyle(
                            color: Color(0xff67727d),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xff37434d), width: 1),
                ),
                minX: 0,
                maxX: bookValueSpots.isNotEmpty ? bookValueSpots.last.x : 12,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  // 帳簿価値（青）
                  LineChartBarData(
                    spots: bookValueSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                  // 市場価値（緑）
                  LineChartBarData(
                    spots: marketValueSpots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final flSpot = barSpot;
                        final formatter = NumberFormat('#,###');
                        return LineTooltipItem(
                          '${barSpot.barIndex == 0 ? "帳簿" : "市場"}: ¥${formatter.format(flSpot.y)}',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
