import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AchievementType {
  firstStep, // First session ever
  quickWin, // 5 min session
  morningGlory, // Morning session (5-9 AM)
  nightOwl, // Night session (10PM-2AM)
  threeDayStreak,
  homeGuardian, // Home Base session
}

class Achievement {
  final AchievementType id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const List<Achievement> ALL_ACHIEVEMENTS = [
  Achievement(
    id: AchievementType.firstStep,
    title: "はじめの一歩",
    description: "最初のセッションを完了しました！",
    icon: Icons.directions_walk,
    color: Color(0xFFB5EAD7), // Mint
  ),
  Achievement(
    id: AchievementType.quickWin,
    title: "クイック・ウィン",
    description: "5分間の集中に成功！素晴らしい！",
    icon: Icons.timer,
    color: Color(0xFFFFB7B2), // Salmon
  ),
  Achievement(
    id: AchievementType.morningGlory,
    title: "朝活の達人",
    description: "素晴らしい朝のスタートです！",
    icon: Icons.wb_sunny,
    color: Color(0xFFFFDAC1), // Peach
  ),
  Achievement(
    id: AchievementType.nightOwl,
    title: "夜更かしの集中",
    description: "静かな夜に集中しました。",
    icon: Icons.nights_stay,
    color: Color(0xFFC7CEEA), // Periwinkle
  ),
  Achievement(
    id: AchievementType.homeGuardian,
    title: "自宅警備員",
    description: "自宅での任務を遂行しました！",
    icon: Icons.home,
    color: Color(0xFFE2F0CB), // Tea Green
  ),
];

class AchievementService extends StateNotifier<List<Achievement>> {
  AchievementService() : super([]);

  // Check for new achievements after a session
  Future<List<Achievement>> checkAchievements(int durationMinutes, DateTime startAt, bool isHome) async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getStringList('unlocked_achievements') ?? [];
    List<Achievement> newUnlocks = [];

    // Helper to unlock
    void tryUnlock(AchievementType type) {
      if (!unlocked.contains(type.name)) {
        final ach = ALL_ACHIEVEMENTS.firstWhere((a) => a.id == type);
        newUnlocks.add(ach);
        unlocked.add(type.name);
      }
    }

    // 1. First Step
    tryUnlock(AchievementType.firstStep);

    // 2. Quick Win (>= 5 min)
    if (durationMinutes >= 5) {
      tryUnlock(AchievementType.quickWin);
    }

    // 3. Morning (5-9)
    if (startAt.hour >= 5 && startAt.hour < 9) {
      tryUnlock(AchievementType.morningGlory);
    }

    // 4. Night (22-2)
    if (startAt.hour >= 22 || startAt.hour < 3) {
      tryUnlock(AchievementType.nightOwl);
    }

    // 5. Home Guardian
    if (isHome) {
      tryUnlock(AchievementType.homeGuardian);
    }

    if (newUnlocks.isNotEmpty) {
      await prefs.setStringList('unlocked_achievements', unlocked);
    }
    
    return newUnlocks;
  }
}

final achievementProvider = Provider((ref) => AchievementService());
