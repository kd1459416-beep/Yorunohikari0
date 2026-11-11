import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';

/// 0〜23時の24点を滑らかな曲線で描く。
class RecordLineChart extends StatelessWidget {
  const RecordLineChart({
    super.key,
    required this.values,
    required this.color,
    required this.unit,
  }) : assert(values.length == 24);

  final List<double> values;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final labelStyle = TextStyle(fontSize: 10, color: p.textSecondary);
    final maxY = max(values.reduce(max) * 1.25, 1.0);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 23,
        minY: 0,
        maxY: maxY,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: p.hairline, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 6,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${v.toInt()}時', style: labelStyle),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              maxIncluded: false,
              getTitlesWidget: (v, _) =>
                  Text('${v.round()}$unit', style: labelStyle),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => p.surface,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${s.x.toInt()}時  ${s.y.round()}$unit',
                  TextStyle(color: p.textPrimary, fontSize: 12),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (final (i, v) in values.indexed) FlSpot(i.toDouble(), v),
            ],
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true, // 0未満に膨らまない
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
