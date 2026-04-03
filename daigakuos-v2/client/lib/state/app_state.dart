import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // For StateProvider if needed? No, generic Riverpod is fine.
import '../database_helper.dart';
export '../services/achievement_service.dart';
export '../haptics_service.dart';
export '../services/currency_service.dart';
export '../services/pet_service.dart';

// -----------------------------------------------------------------------------
// Models
// -----------------------------------------------------------------------------

class Session {
  final int? id;
  final String? nodeId;
  final DateTime startAt;
  final int? durationMinutes;
  final int? targetMinutes;
  final String? moodPre;
  final String? moodPost;

  Session({this.id, this.nodeId, required this.startAt, this.durationMinutes, this.targetMinutes, this.moodPre, this.moodPost});
}

class DaigakuNode {
  final String id;
  final String title;
  final int estimateMinutes;
  final String type;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  DaigakuNode({
    required this.id,
    required this.title,
    required this.estimateMinutes,
    required this.type,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DaigakuNode.fromJson(Map<String, dynamic> json) {
    return DaigakuNode(
      id: json['id'] as String,
      title: json['title'] as String,
      estimateMinutes: json['estimate_minutes'] as int,
      type: json['type'] as String,
      isCompleted: (json['is_completed'] as int) == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class UserStats {
  final double totalPoints;
  final int totalMinutes;
  final int level;
  final double progress;
  final double pointsToNext;
  final double dailyPoints;
  final int dailyMinutes;
  final int currentStreak;
  final bool isRestDay; // Added

  UserStats({
    required this.totalPoints,
    required this.totalMinutes,
    required this.level,
    required this.progress,
    required this.pointsToNext,
    required this.dailyPoints,
    required this.dailyMinutes,
    required this.currentStreak,
    required this.isRestDay,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalPoints: (json['totalPoints'] as num).toDouble(),
      totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? ((json['totalPoints'] as num).toDouble() ~/ 30),
      level: json['level'] as int,
      progress: (json['progress'] as num).toDouble(),
      pointsToNext: (json['pointsToNext'] as num).toDouble(),
      dailyPoints: (json['dailyPoints'] as num).toDouble(),
      dailyMinutes: json['dailyMinutes'] as int,
      currentStreak: json['currentStreak'] as int,
      isRestDay: json['isRestDay'] as bool? ?? false,
    );
  }
}

class DailyAgg {
  final double totalPoints;
  final int totalMinutes;
  final int sessionCount;
  
  DailyAgg({required this.totalPoints, required this.totalMinutes, required this.sessionCount});
}

class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final int bonusXP;
  final bool isCompleted;
  final double progress; // 0.0 to 1.0

  DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.bonusXP,
    this.isCompleted = false,
    this.progress = 0.0,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      bonusXP: json['bonusXP'] as int,
      isCompleted: json['isCompleted'] as bool,
      progress: (json['progress'] as num).toDouble(),
    );
  }
}


// -----------------------------------------------------------------------------
// Providers
// -----------------------------------------------------------------------------

final sessionProvider = StateProvider<Session?>((ref) => null);

// Moved LocationBonus to avoid import issues or keep here?
// LocationBonus is distinct, maybe keep strict.
// But main.dart used it. Let's define enum here.
enum LocationBonus { none, campus, home }
final locationBonusProvider = StateProvider<LocationBonus>((ref) => LocationBonus.none);

final selectedNodeProvider = StateProvider<DaigakuNode?>((ref) => null);
final selectedTaskProvider = StateProvider<String?>((ref) => null);

final nodesProvider = FutureProvider<List<DaigakuNode>>((ref) async {
  final data = await DatabaseHelper().getPendingNodes();
  return data.map((e) => DaigakuNode.fromJson(e)).toList();
});

final userStatsProvider = FutureProvider<UserStats>((ref) async {
  try {
    final data = await DatabaseHelper().getUserStats();
    return UserStats.fromJson(data);
  } catch (e) {
    // print("Stats Error: $e");
    return UserStats(
      totalPoints: 0, 
      totalMinutes: 0,
      level: 1, 
      progress: 0, 
      pointsToNext: 100, 
      dailyPoints: 0, 
      dailyMinutes: 0, 
      currentStreak: 0,
      isRestDay: false,
    );
  }
});

final dailyAggProvider = FutureProvider<DailyAgg>((ref) async {
  try {
    final data = await DatabaseHelper().getDailyAgg();
    return DailyAgg(
      totalPoints: (data['totalPoints'] as num?)?.toDouble() ?? 0.0,
      totalMinutes: (data['totalMinutes'] as num?)?.toInt() ?? 0,
      sessionCount: 0
    );
  } catch (e) { return DailyAgg(totalPoints: 0, totalMinutes: 0, sessionCount: 0); }
});

final historyProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await DatabaseHelper().getSessions();
});

final weeklyAggProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await DatabaseHelper().getWeeklyAgg();
});

final dailyChallengeProvider = FutureProvider<DailyChallenge>((ref) async {
  final data = await DatabaseHelper().getDailyChallenge();
  return DailyChallenge.fromJson(data);
});

final globalRaidProvider = FutureProvider<GlobalRaid?>((ref) async {
  // We refresh this periodically or on sync
  final data = await ApiService.fetchRaidStatus();
  if (data == null || data['active'] == false) return null;
  return GlobalRaid.fromJson(data['raid']);
});

final worldStatusProvider = FutureProvider<WorldStatus>((ref) async {
  final data = await ApiService.fetchWorldStatus();
  return WorldStatus.fromJson(data);
});

