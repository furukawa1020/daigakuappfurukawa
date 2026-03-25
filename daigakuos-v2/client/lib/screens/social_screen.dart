import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/social_provider.dart';
import '../services/api_service.dart';

class SocialScreen extends ConsumerWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingsAsync = ref.watch(globalRankingsProvider);
    final statsAsync = ref.watch(globalStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Social & Rankings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGlobalStats(statsAsync),
            const SizedBox(height: 32),
            const Text(
              '🏆 Global Leaderboard',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildRankingsTable(rankingsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalStats(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFF4B0082)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('Hours Focus', stats['total_focus_hours']?.toString() ?? '0'),
            _statItem('Active Users', stats['active_users']?.toString() ?? '0'),
            _statItem('Mokos Found', stats['total_mokos_collected']?.toString() ?? '0'),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading stats'),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildRankingsTable(AsyncValue<List<dynamic>> rankingsAsync) {
    return rankingsAsync.when(
      data: (rankings) {
        if (rankings.isEmpty) return const Text('No rankings yet.', style: TextStyle(color: Colors.white70));
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rankings.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white10),
          itemBuilder: (context, index) {
            final user = rankings[index];
            final isTop3 = index < 3;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isTop3 ? Colors.amber : Colors.blueGrey,
                child: Text('${index + 1}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              title: Text(user['username'] ?? 'MokoUser', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('Level ${user['level']} • XP ${user['xp']}', style: const TextStyle(color: Colors.white60)),
              trailing: user['streak'] > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: Text('🔥 ${user['streak']}', style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading rankings', style: TextStyle(color: Colors.red)),
    );
  }
}
