import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HeatmapCalendar extends StatelessWidget {
  final Map<String, int> dailyMinutes; // Map of "YYYY-MM-DD" -> minutes
  final DateTime startDate;
  final DateTime endDate;

  const HeatmapCalendar({
    super.key,
    required this.dailyMinutes,
    required this.startDate,
    required this.endDate,
  });

  Color _getColorForMinutes(int minutes) {
    if (minutes == 0) return Colors.grey[200]!;
    if (minutes < 15) return const Color(0xFFB5EAD7).withOpacity(0.3);
    if (minutes < 30) return const Color(0xFFB5EAD7).withOpacity(0.5);
    if (minutes < 60) return const Color(0xFFB5EAD7).withOpacity(0.7);
    return const Color(0xFFB5EAD7); // 60+ minutes = full color
  }

  @override
  Widget build(BuildContext context) {
    // Calculate weeks to display (approx 52 weeks for 1 year)
    final int daysDiff = endDate.difference(startDate).inDays;
    final int weeks = (daysDiff / 7).ceil();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "過去1年間の活動",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day labels (Mon, Wed, Fri)
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const SizedBox(height: 2),
                    _dayLabel('月'),
                    const SizedBox(height: 2),
                    _dayLabel('水'),
                    const SizedBox(height: 2),
                    _dayLabel('金'),
                    const SizedBox(height: 2),
                  ],
                ),
                const SizedBox(width: 8),
                // Heatmap grid
                SizedBox(
                  height: 7 * 14.0, // 7 days * cell height
                  child: Row(
                    children: List.generate(weeks, (weekIndex) {
                      return Column(
                        children: List.generate(7, (dayIndex) {
                          final date = startDate.add(Duration(days: weekIndex * 7 + dayIndex));
                          if (date.isAfter(endDate)) {
                            return const SizedBox(width: 12, height: 12);
                          }
                          final dateStr = DateFormat('yyyy-MM-dd').format(date);
                          final minutes = dailyMinutes[dateStr] ?? 0;
                          final color = _getColorForMinutes(minutes);

                          return Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Legend
            Row(
              children: [
                const Text("少ない", style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(width: 8),
                Container(width: 12, height: 12, color: Colors.grey[200]),
                const SizedBox(width: 4),
                Container(width: 12, height: 12, color: const Color(0xFFB5EAD7).withOpacity(0.3)),
                const SizedBox(width: 4),
                Container(width: 12, height: 12, color: const Color(0xFFB5EAD7).withOpacity(0.5)),
                const SizedBox(width: 4),
                Container(width: 12, height: 12, color: const Color(0xFFB5EAD7).withOpacity(0.7)),
                const SizedBox(width: 4),
                Container(width: 12, height: 12, color: const Color(0xFFB5EAD7)),
                const SizedBox(width: 8),
                const Text("多い", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayLabel(String label) {
    return SizedBox(
      height: 12,
      child: Text(
        label,
        style: const TextStyle(fontSize: 9, color: Colors.grey),
      ),
    );
  }
}
