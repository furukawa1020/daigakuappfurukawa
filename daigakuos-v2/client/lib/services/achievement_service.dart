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

    // Logic for unlocking
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

    return newlyUnlocked;
  }
}

final achievementProvider = NotifierProvider<AchievementService, List<Achievement>>(AchievementService.new);
