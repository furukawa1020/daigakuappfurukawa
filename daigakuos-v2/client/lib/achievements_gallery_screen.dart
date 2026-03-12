import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'state/app_state.dart';
import 'widgets/moko_card.dart';
import 'widgets/premium_background.dart';

class AchievementsGalleryScreen extends ConsumerWidget {
  const AchievementsGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementService = ref.read(achievementProvider.notifier);
    final allAchievements = achievementService.getAllAchievements();

    return Scaffold(
      body: PremiumBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text("称号 ＆ 勲章", style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
            ),
            
            Expanded(
              child: FutureBuilder<Set<String>>(
                future: achievementService.getUnlockedIds(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final unlockedIds = snapshot.data!;
                  
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: allAchievements.length,
                    itemBuilder: (context, index) {
                      final ach = allAchievements[index];
                      final isUnlocked = unlockedIds.contains(ach.type.name);
                      
                      return _AchievementGridItem(
                        achievement: ach,
                        isUnlocked: isUnlocked,
                      ).animate().fadeIn(delay: (index * 50).ms).scale(begin: const Offset(0.8, 0.8));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementGridItem extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;

  const _AchievementGridItem({
    required this.achievement,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: MokoCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Background Glow for unlocked
                if (isUnlocked)
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: achievement.color.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),
                
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUnlocked ? achievement.color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    achievement.icon,
                    size: 30,
                    color: isUnlocked ? achievement.color : Colors.white24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                color: isUnlocked ? Colors.white : Colors.white38,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isUnlocked ? achievement.color.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                achievement.icon,
                size: 60,
                color: isUnlocked ? achievement.color : Colors.white10,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            if (!isUnlocked)
              const Text(
                "Locked",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              )
            else
              const Text(
                "Unlocked!",
                style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("閉じる"),
          )
        ],
      ),
    );
  }
}
