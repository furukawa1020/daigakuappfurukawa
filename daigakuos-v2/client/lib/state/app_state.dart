import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// --- Models ---

class User {
  final String deviceId;
  final int level;
  final int xp;
  final int streak;
  final int coins;
  final int rest_days;
  final String username;
  final String? whisper;
  final String mokoMood;
  final String role; 
  final bool canUseSkill;
  final int skillCooldown;
  final int currentSharpness; // Phase 44
  final int maxSharpness; // Phase 44
  final String sharpnessColor; // Phase 44
  final Map<String, int> materials;
  final Map<String, int> inventory; 
  final Map<String, dynamic> bossArchive; 
  final Map<String, dynamic> passiveBuffs; 

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
    required this.currentSharpness,
    required this.maxSharpness,
    required this.sharpnessColor,
    required this.materials,
    required this.inventory,
    required this.bossArchive,
    required this.passiveBuffs,
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
      currentSharpness: json['current_sharpness'] ?? 100,
      maxSharpness: json['max_sharpness'] ?? 100,
      sharpnessColor: json['sharpness_color'] ?? 'white',
      materials: Map<String, int>.from(json['materials'] ?? {}),
      inventory: Map<String, int>.from(json['inventory'] ?? {}),
      bossArchive: Map<String, dynamic>.from(json['boss_archive'] ?? {}),
      passiveBuffs: Map<String, dynamic>.from(json['passive_buffs'] ?? {}),
    );
  }
}

class HuntingQuest {
  final int id;
  final String targetMonster;
  final int difficulty;
  final int requiredMinutes;
  final int progress;
  final String status;

  HuntingQuest({
    required this.id,
    required this.targetMonster,
    required this.difficulty,
    required this.requiredMinutes,
    required this.progress,
    required this.status,
  });

  factory HuntingQuest.fromJson(Map<String, dynamic> json) {
    return HuntingQuest(
      id: json['id'] ?? 0,
      targetMonster: json['target_monster'] ?? '',
      difficulty: json['difficulty'] ?? 1,
      requiredMinutes: json['required_minutes'] ?? 60,
      progress: json['progress'] ?? 0,
      status: json['status'] ?? 'available',
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
  final int currentPhase;

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
  final String? activeGimmick;
  final String? gimmickName;
  final Map<String, dynamic>? monsterState; // Phase 44

  WorldStatus({
    required this.weather,
    required this.eventName,
    required this.startedAt,
    this.raidBuff = 1.0,
    this.activeRaid,
    this.currentPhase = 1,
    this.activeGimmick,
    this.gimmickName,
    this.monsterState,
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
      monsterState: json['monster_state'],
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
      username: json['username'] ?? 'Moko',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] ?? '00:00',
    );
  }
}

// --- Providers ---

final deviceIdProvider = StateProvider<String>((ref) => "EMULATOR_DEVICE_ID");

final userProvider = FutureProvider<User>((ref) async {
  final deviceId = ref.watch(deviceIdProvider);
  return ApiService().fetchUser(deviceId);
});

final worldStatusProvider = FutureProvider<WorldStatus>((ref) async {
  final data = await ApiService().fetchWorldStatus();
  return WorldStatus.fromJson(data);
});

final globalRaidProvider = FutureProvider<GlobalRaid?>((ref) async {
  final world = await ref.watch(worldStatusProvider.future);
  return world.activeRaid;
});

final chatProvider = StateProvider<List<ChatMessage>>((ref) => []);

final partyProvider = FutureProvider<Party?>((ref) async {
  final deviceId = ref.watch(deviceIdProvider);
  return ApiService().fetchParty(deviceId);
});

class Party {
  final String name;
  final List<PartyMember> members;
  Party({required this.name, required this.members});
  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      name: json['name'],
      members: (json['members'] as List).map((m) => PartyMember.fromJson(m)).toList(),
    );
  }
}

class PartyMember {
  final String username;
  final String mokoMood;
  final String role;
  PartyMember({required this.username, required this.mokoMood, required this.role});
  factory PartyMember.fromJson(Map<String, dynamic> json) {
    return PartyMember(
      username: json['username'],
      mokoMood: json['moko_mood'],
      role: json['role'] ?? 'dps',
    );
  }
}
