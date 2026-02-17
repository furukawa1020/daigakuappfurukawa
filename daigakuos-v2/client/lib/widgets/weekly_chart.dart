import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeeklyChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;

  const WeeklyChart({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    // Process data: Ensure 7 days, fill missing with 0
    // weeklyData is [{day: 'YYYY-MM-DD', minutes: 123}, ...]
    
    // 1. Create Map for easy lookup
    final Map<String, int> dataMap = {
      for (var e in weeklyData) e['day'] as String: e['minutes'] as int
    };

    // 2. Generate last 7 days keys
    final now = DateTime.now();
    final List<String> days = List.generate(7, (index) {
      final d = now.subtract(Duration(days: 6 - index));
      return d.toIso8601String().substring(0, 10);
    });

    // 3. Find max Y for scaling
    int maxMinutes = 60; // Min scale
    for (var d in days) {
      final m = dataMap[d] ?? 0;
      if (m > maxMinutes) maxMinutes = m;
    }
    // Round up to nearest 60
    final double maxY = ((maxMinutes / 60).ceil() * 60).toDouble();

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} min',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= 7) return const SizedBox();
                  final dateStr = days[value.toInt()];
                  final date = DateTime.parse(dateStr);
                  // Show "M", "T", "W"...
                  const weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S']; // Monday=1...
                  // DateTime.weekday: Mon=1, Sun=7
                  final dayLabel = weekDays[date.weekday - 1];
                  
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(dayLabel, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  );
                },
                reservedSize: 20,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            final dateStr = days[index];
            final minutes = dataMap[dateStr] ?? 0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: minutes.toDouble(),
                  color: minutes >= 60 ? const Color(0xFFB5EAD7) : const Color(0xFFFFB7B2), // Mint if target hit, else Pink
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.grey[100],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
