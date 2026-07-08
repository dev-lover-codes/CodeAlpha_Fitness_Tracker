import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fitness_activity.dart';

class WeeklyActiveMinutesChart extends StatelessWidget {
  final List<FitnessActivity> weeklyActivities;

  const WeeklyActiveMinutesChart({super.key, required this.weeklyActivities});

  /// Computes the total active minutes for each of the last 7 days.
  List<MapEntry<DateTime, int>> _getDailyActiveMinutes() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<DateTime> last7Days = List.generate(7, (index) {
      return today.subtract(Duration(days: 6 - index));
    });

    return last7Days.map((day) {
      final dailySum = weeklyActivities
          .where(
            (act) =>
                act.timestamp.year == day.year &&
                act.timestamp.month == day.month &&
                act.timestamp.day == day.day,
          )
          .fold<int>(0, (sum, act) => sum + act.durationInMinutes);
      return MapEntry(day, dailySum);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dailyData = _getDailyActiveMinutes();

    final double maxDuration = dailyData
        .map((e) => e.value)
        .fold<double>(
          60.0,
          (maxVal, duration) =>
              duration > maxVal ? duration.toDouble() : maxVal,
        );

    final double maxYLimit = (maxDuration * 1.15).roundToDouble();

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color:
            theme.cardTheme.color ??
            (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.light
                ? Colors.black.withAlpha(8)
                : Colors.black.withAlpha(38),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Active Minutes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${weeklyActivities.fold<int>(0, (sum, act) => sum + act.durationInMinutes)} min total',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxYLimit,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFF0F172A),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dayData = dailyData[group.x.toInt()];
                      final formattedDate = DateFormat(
                        'EEEE',
                      ).format(dayData.key);
                      return BarTooltipItem(
                        '$formattedDate\n',
                        const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: '${rod.toY.toInt()} mins',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: maxYLimit / 3 > 0
                          ? (maxYLimit / 3).roundToDouble()
                          : 20,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text(
                            '${value.toInt()}m',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= dailyData.length) {
                          return const SizedBox();
                        }
                        final date = dailyData[index].key;
                        final isToday =
                            DateFormat('yyyy-MM-dd').format(date) ==
                            DateFormat('yyyy-MM-dd').format(DateTime.now());

                        return SideTitleWidget(
                          meta: meta,
                          space: 8,
                          child: Text(
                            isToday ? 'Today' : DateFormat('E').format(date),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 10,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isToday
                                  ? theme.colorScheme.primary
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxYLimit / 3 > 0
                      ? (maxYLimit / 3).roundToDouble()
                      : 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? Colors.white.withAlpha(13)
                        : Colors.black.withAlpha(10),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: dailyData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final minutes = entry.value.value.toDouble();
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: minutes,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxYLimit,
                          color: isDark
                              ? Colors.white.withAlpha(8)
                              : Colors.black.withAlpha(5),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}
