import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/ui/ui.dart';

class TrendPoint {
  final DateTime date;
  final double value;
  const TrendPoint(this.date, this.value);
}

/// A quiet line chart: one line, a few labels, no decoration.
/// Shows a short note instead of a chart when there are fewer than two points.
class TrendChart extends StatelessWidget {
  final List<TrendPoint> points; // oldest first
  final String Function(double) format;
  final double height;
  final bool compact;

  const TrendChart({
    super.key,
    required this.points,
    required this.format,
    this.height = 180,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (points.length < 2) {
      return SizedBox(
        height: compact ? height : 80,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            points.isEmpty
                ? 'Nothing logged yet.'
                : 'One more entry and a trend line appears here.',
            style: context.text.bodySmall,
          ),
        ),
      );
    }

    final values = points.map((e) => e.value).toList();
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    if (hi - lo < 1) {
      lo -= 1;
      hi += 1;
    }
    final pad = (hi - lo) * 0.15;
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];
    final labelStyle = context.text.bodySmall!.copyWith(
      fontSize: 11,
      color: p.faint,
    );

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (points.length - 1).toDouble(),
            minY: math.max(0, lo - pad),
            maxY: hi + pad,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: !compact,
              drawVerticalLine: false,
              horizontalInterval: ((hi + pad) - (lo - pad)) / 3,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: p.line, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              show: !compact,
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: ((hi + pad) - (lo - pad)) / 3,
                  getTitlesWidget: (v, meta) {
                    if (v == meta.min || v == meta.max) {
                      return const SizedBox.shrink();
                    }
                    return Text(format(v), style: labelStyle);
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 1,
                  getTitlesWidget: (v, meta) {
                    final i = v.round();
                    if (v != i || i < 0 || i >= points.length) {
                      return const SizedBox.shrink();
                    }
                    final show =
                        i == 0 ||
                        i == points.length - 1 ||
                        (points.length > 4 && i == points.length ~/ 2);
                    if (!show) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat('d MMM').format(points[i].date),
                        style: labelStyle,
                      ),
                    );
                  },
                ),
              ),
            ),
            clipData: const FlClipData.none(),
            lineTouchData: LineTouchData(
              enabled: !compact,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => p.ink,
                getTooltipItems: (items) => [
                  for (final it in items)
                    LineTooltipItem(
                      '${format(it.y)}\n${DateFormat('d MMM').format(points[it.x.round()].date)}',
                      context.text.bodySmall!.copyWith(color: p.inkInverse),
                    ),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.2,
                preventCurveOverShooting: true,
                color: p.ink,
                barWidth: compact ? 1.6 : 2,
                dotData: FlDotData(
                  show: !compact && points.length <= 20,
                  getDotPainter: (s, _, _, _) => FlDotCirclePainter(
                    radius: 2.5,
                    color: p.ink,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
