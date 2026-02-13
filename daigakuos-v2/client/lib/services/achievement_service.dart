import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../database_helper.dart';

enum AchievementType {
  firstSession,
  nightOwl, // Finished after 11 PM
  earlyBird, // Started before 8 AM
  homeGuardian, // Focused at home
  focusedDeep, // 60+ mins
  marathon, // 120+ mins
  // Milestones (Phase 13)
  bronze50h,
  silver100h,
  gold300h,
  platinum500h,
  legend1000h,
}

class Achievement {
  final AchievementType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  Achievement({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class AchievementService extends Notifier<List<Achievement>> {
  @override
  List<Achievement> build() {
    return [];
  }

  final Map<AchievementType, Achievement> _achievementData = {
    AchievementType.firstSession: Achievement(
      type: AchievementType.firstSession,
      title: "第一歩",
      description: "最初のセッションを完了した",
      icon: Icons.directions_walk,
      color: Colors.blue,
    ),
    AchievementType.nightOwl: Achievement(
      type: AchievementType.nightOwl,
      title: "夜更かしの達人",
      description: "23時以降に集中を終えた",
      icon: Icons.nightlight_round,
      color: Colors.indigo,
    ),
    AchievementType.earlyBird: Achievement(
      type: AchievementType.earlyBird,
      title: "朝活の達人",
      description: "朝8時前に集中を開始した",
      icon: Icons.wb_sunny,
      color: Colors.orange,
    ),
    AchievementType.homeGuardian: Achievement(
      type: AchievementType.homeGuardian,
      title: "自宅警備員",
      description: "自宅で集中を完了した",
      icon: Icons.home,
      color: Colors.green,
    ),
    AchievementType.focusedDeep: Achievement(
      type: AchievementType.focusedDeep,
      title: "ディープ・フォーカス",
      description: "60分以上のセッションを完了した",
      icon: Icons.timer,
      color: Colors.purple,
    ),
    AchievementType.marathon: Achievement(
      type: AchievementType.marathon,
      title: "マラソン・ランナー",
      description: "120分以上のセッションを完了した",
      icon: Icons.directions_run,
      color: Colors.redAccent,
    ),
    // Milestones
    AchievementType.bronze50h: Achievement(
      type: AchievementType.bronze50h,
      title: "🥉 ブロンズ",
      description: "累計50時間達成",
      icon: Icons.workspace_premium,
      color: Color(0xFFCD7F32),
    ),
    AchievementType.silver100h: Achievement(
      type: AchievementType.silver100h,
      title: "🥈 シルバー",
      description: "累計100時間達成",
      icon: Icons.workspace_premium,
      color: Color(0xFFC0C0C0),
    ),
    AchievementType.gold300h: Achievement(
      type: AchievementType.gold300h,
      title: "🥇 ゴールド",
      description: "累計300時間達成",
      icon: Icons.workspace_premium,
      color: Color(0xFFFFD700),
    ),
    AchievementType.platinum500h: Achievement(
      type: AchievementType.platinum500h,
      title: "💎 プラチナ",
      description: "累計500時間達成",
      icon: Icons.workspace_premium,
      color: Color(0xFFE5E4E2),
    ),
    AchievementType.legend1000h: Achievement(
      type: AchievementType.legend1000h,
      title: "👑 レジェンド",
      description: "累計1000時間達成",
      icon: Icons.workspace_premium,
      color: Color(0xFF9C27B0),
    ),
  };

  Future<List<Achievement>> checkAchievements(int minutes, DateTime startTime, bool isHome) async {
    final db = DatabaseHelper();
    final List<Achievement> newlyUnlocked = [];

    // 1. Get already unlocked IDs
    final List<Map<String, dynamic>> maps = await (await db.database).query('user_achievements');
    final Set<String> unlockedIds = maps.map((m) => m['id'] as String).toSet();

    Future<void> unlock(AchievementType type) async {
      final id = type.name;
      if (!unlockedIds.contains(id)) {
        await (await db.database).insert('user_achievements', {
          'id': id,
          'unlocked_at': DateTime.now().toIso8601String(),
        });
        newlyUnlocked.add(_achievementData[type]!);
      }
    }

    // Logic for unlocking session-based achievements
    await unlock(AchievementType.firstSession); // Guaranteed since we finished a session

    if (startTime.hour < 8) {
      await unlock(AchievementType.earlyBird);
    }
    
    if (DateTime.now().hour >= 23) {
      await unlock(AchievementType.nightOwl);
    }

    if (isHome) {
      await unlock(AchievementType.homeGuardian);
    }

    if (minutes >= 60) {
      await unlock(AchievementType.focusedDeep);
    }

    if (minutes >= 120) {
      await unlock(AchievementType.marathon);
    }
    
    // Check Milestones (Phase 13 Feature 2)
    final stats = await db.getUserStats();
    final totalMinutes = stats['totalMinutes'] as int? ?? 0;
    final hours = totalMinutes / 60;
    
    if (hours >= 50) {
      await unlock(AchievementType.bronze50h);
    }
    if (hours >= 100) {
      await unlock(AchievementType.silver100h);
    }
    if (hours >= 300) {
      await unlock(AchievementType.gold300h);
    }
    if (hours >= 500) {
      await unlock(AchievementType.platinum500h);
    }
    if (hours >= 1000) {
      await unlock(AchievementType.legend1000h);
    }

    return newlyUnlocked;
  }
  
  // Get all unlocked achievements for display
  Future<List<Achievement>> getUnlockedAchievements() async {
    final db = DatabaseHelper();
    final List<Map<String, dynamic>> maps = await (await db.database).query('user_achievements');
    final Set<String> unlockedIds = maps.map((m) => m['id'] as String).toSet();
    
    return _achievementData.entries
        .where((entry) => unlockedIds.contains(entry.key.name))
        .map((entry) => entry.value)
        .toList();
  }
}

final achievementProvider = NotifierProvider<AchievementService, List<Achievement>>(AchievementService.new);
