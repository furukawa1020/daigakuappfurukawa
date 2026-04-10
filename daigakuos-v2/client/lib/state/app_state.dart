import '../services/api_service.dart';
import '../services/ruby_engine_service.dart';

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
  final int currentSharpness; 
  final int maxSharpness; 
  final String sharpnessColor; 
  final int hp; 
  final int maxHp; 
  final int stamina; 
  final int maxStamina; 
  final Map<String, int> materials;
  final Map<String, int> inventory; 
  final Map<String, dynamic> bossArchive; 
  final Map<String, dynamic> passiveBuffs; 
  final Map<String, dynamic> mealBuffs;
  final Map<String, dynamic> statusEffects;
  final double chaosLevel; // Phase 48
  final double orderLevel; // Phase 48
  final int metabolicSync; // Phase 58 (Replaced neuralResonance)

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
    required this.hp,
    required this.maxHp,
    required this.stamina,
    required this.maxStamina,
    required this.materials,
    required this.inventory,
    required this.bossArchive,
    required this.passiveBuffs,
    required this.mealBuffs,
    required this.statusEffects,
    required this.chaosLevel,
    required this.orderLevel,
    required this.metabolicSync,
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
      hp: json['hp'] ?? 100,
      maxHp: json['max_hp'] ?? 100,
      stamina: json['stamina'] ?? 100,
      maxStamina: json['max_stamina'] ?? 100,
      materials: Map<String, int>.from(json['materials'] ?? {}),
      inventory: Map<String, int>.from(json['inventory'] ?? {}),
      bossArchive: Map<String, dynamic>.from(json['boss_archive'] ?? {}),
      passiveBuffs: Map<String, dynamic>.from(json['passive_buffs'] ?? {}),
      mealBuffs: Map<String, dynamic>.from(json['meal_buffs'] ?? {}),
      statusEffects: Map<String, dynamic>.from(json['status_effects'] ?? {}),
      chaosLevel: (json['chaos_level'] ?? 0.0).toDouble(),
      orderLevel: (json['order_level'] ?? 0.0).toDouble(),
      metabolicSync: json['metabolic_sync'] ?? json['neural_resonance'] ?? 50,
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

  final int currentPhase;
  final Map<String, dynamic>? physics;   // Phase 56: Procedural Physics
  final Map<String, dynamic>? bloodline; // Phase 58: Biological Traits

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
    this.physics,
    this.bloodline,
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
      physics: json['physics'],
      bloodline: json['bloodline'],
    );
  }
}

class WorldStatus {
  final String weather;
  final String? gimmickName;
  final Map<String, dynamic>? monsterState; 
  final double oxygenLevel; // Phase 52
  final double toxinLevel;  // Phase 52
  final double monsterHunger; // Phase 52

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
    this.oxygenLevel = 50.0,
    this.toxinLevel = 0.0,
    this.monsterHunger = 0.0,
  });

  factory WorldStatus.fromJson(Map<String, dynamic> json) {
    final env = json['environment'] ?? {};
    final raid = json['raid'] ?? {};
    return WorldStatus(
      weather: env['weather'] ?? 'sunny',
      eventName: json['event_name'] ?? 'Native Engine: DEEP SIMULATION 🐾',
      startedAt: DateTime.parse(json['started_at'] ?? DateTime.now().toIso8601String()),
      raidBuff: (json['raid_buff'] ?? 1.0).toDouble(),
      activeRaid: raid.isNotEmpty ? GlobalRaid.fromJson(raid) : null,
      currentPhase: json['current_phase'] ?? env['current_phase'] ?? 1,
      activeGimmick: env['active_gimmick'],
      gimmickName: env['gimmick_name'],
      monsterState: raid['monster_state'],
      oxygenLevel: (env['oxygen'] ?? 50.0).toDouble(),
      toxinLevel: (state['toxin_load'] ?? (env['toxins'] ?? 0.0) / 100.0).toDouble(),
      monsterHunger: (raid['hunger'] ?? 0.0).toDouble(),
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
  // Phase 51: Native Ruby Engine Bridge
  final engine = RubyEngineService();
  final response = await engine.sendCommand({'command': 'get_status'});
  return User.fromJson(response['user']);
});

final worldStatusProvider = FutureProvider<WorldStatus>((ref) async {
  // Phase 51: Native Ruby Engine Bridge
  final engine = RubyEngineService();
  final response = await engine.sendCommand({'command': 'get_status'});
  
  final env = response['environment'] ?? {};
  final raid = response['raid'] ?? {};

  return WorldStatus(
    weather: env['weather'] ?? "sunny",
    eventName: "Native Engine: DEEP SIMULATION 🐾",
    startedAt: DateTime.now(),
    activeRaid: GlobalRaid.fromJson(raid),
    oxygenLevel: (env['oxygen'] ?? 50.0).toDouble(),
    toxinLevel: (env['toxins'] ?? 0.0).toDouble(),
    monsterHunger: (raid['hunger'] ?? 0.0).toDouble(),
  );
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
