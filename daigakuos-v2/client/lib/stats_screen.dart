import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'state/app_state.dart';
import 'widgets/premium_background.dart';
import 'widgets/moko_card.dart';
import 'widgets/weekly_chart.dart';
import 'widgets/activity_heatmap.dart';
import 'database_helper.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  late Future<Map<String, int>> _heatmapFuture;

  @override
  void initState() {
    super.initState();
    _heatmapFuture = DatabaseHelper().getDailyMinutesMap();
  }

  @override
  Widget build(BuildContext context) {
    final userStatsAsync = ref.watch(userStatsProvider);
    final weeklyAsync = ref.watch(weeklyAggProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Statistics", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: PremiumBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Overview Cards
                userStatsAsync.when(
                  data: (stats) => Row(
                    children: [
                      Expanded(child: _StatCard(label: "Total Hours", value: (stats.totalMinutes / 60).toStringAsFixed(1), icon: Icons.timer, color: Colors.blueAccent)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(label: "Level", value: "${stats.level}", icon: Icons.star, color: Colors.amber)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(label: "Streak", value: "${stats.currentStreak} Days", icon: Icons.local_fire_department, color: Colors.orange)),
                    ],
                  ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text("Error: $e"),
                ),
                
                const SizedBox(height: 24),

                // 2. Weekly Chart
                const Text("Weekly Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                weeklyAsync.when(
                  data: (data) => MokoCard(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: WeeklyChart(weeklyData: data),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => const SizedBox(),
                ),

                const SizedBox(height: 24),

                // 3. Heatmap
                const Text("Consistency Heatmap", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                FutureBuilder<Map<String, int>>(
                  future: _heatmapFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return MokoCard(
                        child: ActivityHeatmap(dailyMinutes: snapshot.data!),
                      ).animate().fadeIn(delay: 400.ms);
                    }
                    return const CircularProgressIndicator();
                  },
                ),

                const SizedBox(height: 24),
                
                // 4. Milestone Medals
                const Text("Milestones", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                userStatsAsync.when(
                  data: (stats) {
                    final hours = stats.totalMinutes / 60.0;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _MilestoneMedal(name: "Bronze", icon: "🥉", unachievedIcon: "🏁", hoursRequired: 50, currentHours: hours, color: Colors.orange.shade300),
                          _MilestoneMedal(name: "Silver", icon: "🥈", unachievedIcon: "🏁", hoursRequired: 100, currentHours: hours, color: Colors.grey.shade300),
                          _MilestoneMedal(name: "Gold", icon: "🥇", unachievedIcon: "🏁", hoursRequired: 300, currentHours: hours, color: Colors.amber.shade400),
                          _MilestoneMedal(name: "Platinum", icon: "💎", unachievedIcon: "🏁", hoursRequired: 500, currentHours: hours, color: Colors.cyan.shade300),
                          _MilestoneMedal(name: "Legend", icon: "👑", unachievedIcon: "🏁", hoursRequired: 1000, currentHours: hours, color: Colors.purple.shade300),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms);
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_,__) => const SizedBox(),
                ),

                const SizedBox(height: 24),
                
                 // 5. Detailed Stats (Placeholder for now)
                 MokoCard(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text("Insights", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                       const Divider(),
                       _InsightRow(label: "Best Focus Time", value: "Morning (08:00 - 10:00)"),
                       _InsightRow(label: "Most Productive Day", value: "Tuesday"),
                       _InsightRow(label: "Average Session", value: "45 min"),
                     ],
                   ),
                 ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String label;
  final String value;
  const _InsightRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MilestoneMedal extends StatelessWidget {
  final String name;
  final String icon;
  final String unachievedIcon;
  final double hoursRequired;
  final double currentHours;
  final Color color;

  const _MilestoneMedal({
    required this.name,
    required this.icon,
    required this.unachievedIcon,
    required this.hoursRequired,
    required this.currentHours,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = currentHours >= hoursRequired;
    final progress = (currentHours / hoursRequired).clamp(0.0, 1.0);

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked ? color.withOpacity(0.15) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? color.withOpacity(0.5) : Colors.white10,
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked
            ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
      ),
      child: Column(
        children: [
          Text(
            isUnlocked ? icon : unachievedIcon,
            style: TextStyle(
              fontSize: 32,
              foreground: Paint()
                ..colorFilter = isUnlocked
                    ? null
                    : const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
            ),
          ).animate(target: isUnlocked ? 1 : 0).scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut),
          const SizedBox(height: 8),
          Text(name, style: TextStyle(color: isUnlocked ? color : Colors.white54, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          if (isUnlocked)
             const Text("Unlocked", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold))
          else
             Column(
               children: [
                 Text("${hoursRequired.toInt()}h", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                 const SizedBox(height: 4),
                 LinearProgressIndicator(
                   value: progress,
                   backgroundColor: Colors.white10,
                   valueColor: AlwaysStoppedAnimation(color.withOpacity(0.5)),
                   minHeight: 4,
                 ),
               ],
             )
        ],
      ),
    );
  }
}
