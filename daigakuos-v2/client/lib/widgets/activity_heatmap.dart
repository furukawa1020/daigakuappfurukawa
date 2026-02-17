import 'package:flutter/material.dart';

class ActivityHeatmap extends StatelessWidget {
  final Map<String, int> dailyMinutes;

  const ActivityHeatmap({super.key, required this.dailyMinutes});

  @override
  Widget build(BuildContext context) {
    // Generate last 10 weeks (70 days) for display
    final now = DateTime.now();
    // Start from Sunday of 10 weeks ago to align grid
    final start = now.subtract(const Duration(days: 70));
    // Calculate days until last Sunday to align
    final offset = start.weekday == 7 ? 0 : start.weekday; 
    // Wait, typical heatmap is (Row=DayOfWeek, Col=Week).
    // Let's do simple grid: 7 rows (Mon-Sun), X cols.
    
    // Or simpler: Just a grid of last 28 days (4 weeks)
    final daysToShow = 28;
    final List<DateTime> dates = List.generate(daysToShow, (index) {
      return now.subtract(Duration(days: (daysToShow - 1) - index));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Activity (Last 4 Weeks)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, // 7 days per row
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.0,
          ),
          itemCount: daysToShow,
          itemBuilder: (context, index) {
            final date = dates[index];
            final dateStr = date.toIso8601String().substring(0, 10);
            final minutes = dailyMinutes[dateStr] ?? 0;
            
            Color color;
            if (minutes == 0) {
              color = Colors.grey[200]!;
            } else if (minutes < 30) {
              color = const Color(0xFFC8E6C9); // Light Green 100
            } else if (minutes < 60) {
              color = const Color(0xFFA5D6A7); // Green 200
            } else if (minutes < 120) {
              color = const Color(0xFF66BB6A); // Green 400
            } else {
               color = const Color(0xFF2E7D32); // Green 800
            }

            return Tooltip(
              message: "$dateStr: $minutes min",
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
