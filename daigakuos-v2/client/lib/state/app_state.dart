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

  final String role; // Phase 40: tank, healer, dps
  final bool canUseSkill; // Phase 41
  final int skillCooldown; // Phase 41
  final Map<String, int> materials;

  User({
    required this.deviceId,
    required this.level,
    required this.xp,
    required this.streak,
    required this.coins,
    required this.rest_days,
    required this.username,
    this.whisper,
    required this.mokoMood,
    required this.role,
    required this.canUseSkill,
    required this.skillCooldown,
    required this.materials,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      deviceId: json['device_id'] ?? '',
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      streak: json['streak'] ?? 0,
      coins: json['coins'] ?? 0,
      rest_days: json['rest_days'] ?? 0,
      username: json['username'] ?? 'User',
      whisper: json['whisper'],
      mokoMood: json['moko_mood'] ?? 'happy',
      role: json['role'] ?? 'dps',
      canUseSkill: json['can_use_skill'] ?? false,
      skillCooldown: json['skill_cooldown'] ?? 0,
      materials: Map<String, int>.from(json['materials'] ?? {}),
    );
  }
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

class GlobalRaid {
  final String title;
  final String image;
  final int maxHp;
  final int currentHp;
  final double healthPercentage;
  final List<dynamic> leaderboard;
  final String? activeSkill;
  final DateTime? skillEndsAt;
  final int currentPhase; // Phase 40: 1 or 2

  GlobalRaid({
    required this.title,
    required this.image,
    required this.maxHp,
    required this.currentHp,
    required this.healthPercentage,
    required this.leaderboard,
    this.activeSkill,
    this.skillEndsAt,
    required this.currentPhase,
  });

  factory GlobalRaid.fromJson(Map<String, dynamic> json) {
    return GlobalRaid(
      title: json['title'] ?? 'Global Boss',
      image: json['image'] ?? '',
      maxHp: json['max_hp'] ?? 1,
      currentHp: json['current_hp'] ?? 0,
      healthPercentage: (json['health_percentage'] ?? 0).toDouble(),
      leaderboard: json['leaderboard'] ?? [],
      activeSkill: json['active_skill'],
      skillEndsAt: json['skill_ends_at'] != null ? DateTime.parse(json['skill_ends_at']) : null,
      currentPhase: json['current_phase'] ?? 1,
    );
  }
}

class WorldStatus {
  final String weather;
  final String eventName;
  final DateTime startedAt;
  final double raidBuff;
  final GlobalRaid? activeRaid;
  final int currentPhase;
  final String? activeGimmick; // Phase 41
  final String? gimmickName; // Phase 41

  WorldStatus({
    required this.weather,
    required this.eventName,
    required this.startedAt,
    this.raidBuff = 1.0,
    this.activeRaid,
    this.currentPhase = 1,
    this.activeGimmick,
    this.gimmickName,
  });

  factory WorldStatus.fromJson(Map<String, dynamic> json) {
    return WorldStatus(
      weather: json['weather'] ?? 'sunny',
      eventName: json['event_name'] ?? 'Moko Day',
      startedAt: DateTime.parse(json['started_at'] ?? DateTime.now().toIso8601String()),
      raidBuff: (json['raid_buff'] ?? 1.0).toDouble(),
      activeRaid: json['active_raid'] != null ? GlobalRaid.fromJson(json['active_raid']) : null,
      currentPhase: json['current_phase'] ?? 1,
      activeGimmick: json['active_gimmick'],
      gimmickName: json['gimmick_name'],
    );
  }
}

class Party {
  final int id;
  final String name;
  final int leaderId;
  final List<PartyMember> members;

  Party({required this.id, required this.name, required this.leaderId, required this.members});

  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      id: json['id'],
      name: json['name'],
      leaderId: json['leader_id'],
      members: (json['members'] as List).map((m) => PartyMember.fromJson(m)).toList(),
    );
  }
}

class PartyMember {
  final String username;
  final String mokoMood;
  final int level;

  PartyMember({required this.username, required this.mokoMood, required this.level});

  factory PartyMember.fromJson(Map<String, dynamic> json) {
    return PartyMember(
      username: json['username'],
      mokoMood: json['moko_mood'],
      level: json['level'],
    );
  }
}

class ChatMessage {
  final String username;
  final String content;
  final String timestamp;

  ChatMessage({required this.username, required this.content, required this.timestamp});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      username: json['username'],
      content: json['content'],
      timestamp: json['timestamp'],
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

final weeklyAggProvider = FutureProvider<Map<String, double>>((ref) async {
  return await DatabaseHelper().getWeeklyAggregation();
});

final partyProvider = FutureProvider<Party?>((ref) async {
  final deviceId = ref.watch(deviceIdProvider);
  return await ApiService().fetchParty(deviceId);
});

final chatProvider = StateProvider<List<ChatMessage>>((ref) => []);

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

