import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/device.dart';
import '../models/device_asset.dart';
import '../services/asset_valuation_service.dart';

/// 資産推移グラフ（帳簿・市場・更新実績を表示）
class AssetValueChart extends StatefulWidget {
  final Device device;

  const AssetValueChart({
    super.key,
    required this.device,
  });

  @override
  State<AssetValueChart> createState() => _AssetValueChartState();
}

class _AssetValueChartState extends State<AssetValueChart> {
  late Future<AssetGraphData> _graphFuture;

  @override
  void initState() {
    super.initState();
    _graphFuture = AssetValuationService().buildAlignedGraphData(widget.device);
  }

  @override
  void didUpdateWidget(covariant AssetValueChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device.id != widget.device.id ||
        oldWidget.device.assetValue?.lastPriceCheck !=
            widget.device.assetValue?.lastPriceCheck) {
      _graphFuture =
          AssetValuationService().buildAlignedGraphData(widget.device);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AssetGraphData>(
      future: _graphFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return _ChartBody(
          data: snapshot.data!,
          marketSource: widget.device.assetValue?.marketSourceParsed ??
              MarketValueSource.formula,
        );
      },
    );
  }
}

class _ChartBody extends StatelessWidget {
  final AssetGraphData data;
  final MarketValueSource marketSource;

  const _ChartBody({
    required this.data,
    required this.marketSource,
  });

  @override
  Widget build(BuildContext context) {
    final bookValueSpots = data.bookValueSpots;
    final marketValueSpots = data.marketValueSpots;
    final historySpots = data.historySpots;

    if (bookValueSpots.isEmpty && marketValueSpots.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('データがありません')),
      );
    }

    double maxY = 0;
    for (final spot in bookValueSpots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    for (final spot in marketValueSpots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    for (final spot in historySpots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    maxY = maxY * 1.12;

    final todayX = data.todayMonthIndex.clamp(0.0, data.maxX);

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            _buildLegendItem('帳簿価値', Colors.blue),
            _buildLegendItem('市場価値', Colors.green),
            if (historySpots.isNotEmpty)
              _buildLegendItem('更新実績', Colors.orange),
            _buildLegendItem('今日', const Color(0xFF9E9E9E), isLine: true),
          ],
        ),
        if (marketSource == MarketValueSource.formula) ...[
          const SizedBox(height: 6),
          const Text(
            '市場価値は推定（数式）です。Proで相場DB・AI推定が使えます',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Color(0xFF999999)),
          ),
        ],
        const SizedBox(height: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xffe7e8ec),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => const FlLine(
                    color: Color(0xffe7e8ec),
                    strokeWidth: 1,
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  verticalLines: [
                    VerticalLine(
                      x: todayX,
                      color: const Color(0xFF9E9E9E).withValues(alpha: 0.6),
                      strokeWidth: 1.5,
                      dashArray: [4, 4],
                      label: VerticalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 4, bottom: 4),
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w600,
                        ),
                        labelResolver: (_) => '今日',
                      ),
                    ),
                  ],
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
                      reservedSize: 32,
                      interval: _calcXInterval(data.maxX),
                      getTitlesWidget: (value, meta) {
                        final interval = _calcXInterval(data.maxX);
                        if (value % interval != 0) {
                          return const SizedBox.shrink();
                        }
                        if (value == meta.min || value == meta.max) {
                          return const SizedBox.shrink();
                        }
                        final months = value.toInt();
                        String label;
                        if (months == 0) {
                          label = '購入';
                        } else if (months % 12 == 0) {
                          label = '${months ~/ 12}年';
                        } else {
                          label = '${months}月';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
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
                maxX: data.maxX,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: bookValueSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withValues(alpha: 0.08),
                    ),
                  ),
                  LineChartBarData(
                    spots: marketValueSpots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withValues(alpha: 0.06),
                    ),
                  ),
                  if (historySpots.isNotEmpty)
                    LineChartBarData(
                      spots: historySpots,
                      isCurved: false,
                      color: Colors.orange,
                      barWidth: 0,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: Colors.orange,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(show: false),
                    ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.withValues(alpha: 0.9),
                    getTooltipItems: (touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final formatter = NumberFormat('#,###');
                        final labels = ['帳簿', '市場', '実績'];
                        final label = barSpot.barIndex < labels.length
                            ? labels[barSpot.barIndex]
                            : '価値';
                        return LineTooltipItem(
                          '$label: ¥${formatter.format(barSpot.y)}',
                          const TextStyle(color: Colors.white, fontSize: 11),
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

  Widget _buildLegendItem(String label, Color color, {bool isLine = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLine)
          Container(
            width: 14,
            height: 2,
            color: color,
          )
        else
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  double _calcXInterval(double maxX) {
    if (maxX <= 12) return 3;
    if (maxX <= 24) return 6;
    if (maxX <= 60) return 12;
    return 24;
  }
}
