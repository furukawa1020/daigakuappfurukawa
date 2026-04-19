import 'package:flutter_test/flutter_test.dart';

import 'package:daigaku_app_client/services/quotes.dart';
import 'package:daigaku_app_client/state/app_state.dart';

void main() {
  group('MOTIVATIONAL_QUOTES', () {
    test('list is not empty', () {
      expect(MOTIVATIONAL_QUOTES, isNotEmpty);
    });

    test('every quote is a non-empty string', () {
      for (final quote in MOTIVATIONAL_QUOTES) {
        expect(quote, isA<String>());
        expect(quote.trim(), isNotEmpty);
      }
    });
  });

  group('User.fromJson', () {
    test('parses full JSON correctly', () {
      final json = {
        'device_id': 'device-123',
        'level': 5,
        'xp': 200,
        'streak': 3,
        'coins': 50,
        'rest_days': 1,
        'username': 'TestUser',
        'moko_mood': 'happy',
        'role': 'dps',
        'can_use_skill': true,
        'skill_cooldown': 10,
        'current_sharpness': 80,
        'max_sharpness': 100,
        'sharpness_color': 'green',
        'hp': 90,
        'max_hp': 100,
        'stamina': 70,
        'max_stamina': 100,
        'materials': <String, dynamic>{'wood': 3},
        'inventory': <String, dynamic>{'potion': 2},
        'boss_archive': <String, dynamic>{},
        'passive_buffs': <String, dynamic>{},
        'meal_buffs': <String, dynamic>{},
        'status_effects': <String, dynamic>{},
        'chaos_level': 0.5,
        'order_level': 0.8,
        'metabolic_sync': 60,
      };

      final user = User.fromJson(json);

      expect(user.deviceId, 'device-123');
      expect(user.level, 5);
      expect(user.xp, 200);
      expect(user.streak, 3);
      expect(user.coins, 50);
      expect(user.username, 'TestUser');
      expect(user.canUseSkill, true);
      expect(user.chaosLevel, 0.5);
      expect(user.orderLevel, 0.8);
      expect(user.metabolicSync, 60);
    });

    test('applies default values for missing fields', () {
      final user = User.fromJson({});

      expect(user.deviceId, '');
      expect(user.level, 1);
      expect(user.xp, 0);
      expect(user.streak, 0);
      expect(user.coins, 0);
      expect(user.username, 'User');
      expect(user.mokoMood, 'happy');
      expect(user.role, 'dps');
      expect(user.canUseSkill, false);
      expect(user.hp, 100);
      expect(user.maxHp, 100);
      expect(user.stamina, 100);
      expect(user.maxStamina, 100);
      expect(user.chaosLevel, 0.0);
      expect(user.orderLevel, 0.0);
      expect(user.metabolicSync, 50);
    });
  });

  group('HuntingQuest.fromJson', () {
    test('parses full JSON correctly', () {
      final json = {
        'id': 42,
        'target_monster': 'Dragon',
        'difficulty': 3,
        'required_minutes': 90,
        'progress': 45,
        'status': 'in_progress',
      };

      final quest = HuntingQuest.fromJson(json);

      expect(quest.id, 42);
      expect(quest.targetMonster, 'Dragon');
      expect(quest.difficulty, 3);
      expect(quest.requiredMinutes, 90);
      expect(quest.progress, 45);
      expect(quest.status, 'in_progress');
    });

    test('applies default values for missing fields', () {
      final quest = HuntingQuest.fromJson({});

      expect(quest.id, 0);
      expect(quest.targetMonster, '');
      expect(quest.difficulty, 1);
      expect(quest.requiredMinutes, 60);
      expect(quest.progress, 0);
      expect(quest.status, 'available');
    });
  });
}
