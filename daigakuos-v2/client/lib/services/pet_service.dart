import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database_helper.dart';

enum PetStage {
  egg,      // 0-10h
  baby,     // 10-50h
  child,    // 50-100h
  teen,     // 100-300h
  adult,    // 300-500h
  master,   // 500h+
}

class PetState {
  final PetStage stage;
  final int totalMinutes;
  final String name;
  final String emoji;

  PetState({
    required this.stage,
    required this.totalMinutes,
    required this.name,
    required this.emoji,
  });

  static PetState fromMinutes(int minutes) {
    final hours = minutes / 60;
    
    PetStage stage;
    String name;
    String emoji;
    
    if (hours < 10) {
      stage = PetStage.egg;
      name = "モコたまご";
      emoji = "🥚";
    } else if (hours < 50) {
      stage = PetStage.baby;
      name = "ベビーモコ";
      emoji = "🐣";
    } else if (hours < 100) {
      stage = PetStage.child;
      name = "コモコ";
      emoji = "🐥";
    } else if (hours < 300) {
      stage = PetStage.teen;
      name = "ティーンモコ";
      emoji = "🐤";
    } else if (hours < 500) {
      stage = PetStage.adult;
      name = "おとなモコ";
      emoji = "🐔";
    } else {
      stage = PetStage.master;
      name = "マスターモコ";
      emoji = "👑";
    }
    
    return PetState(
      stage: stage,
      totalMinutes: minutes,
      name: name,
      emoji: emoji,
    );
  }

  double get progressToNextStage {
    final hours = totalMinutes / 60;
    
    switch (stage) {
      case PetStage.egg:
        return hours / 10;
      case PetStage.baby:
        return (hours - 10) / 40;
      case PetStage.child:
        return (hours - 50) / 50;
      case PetStage.teen:
        return (hours - 100) / 200;
      case PetStage.adult:
        return (hours - 300) / 200;
      case PetStage.master:
        return 1.0; // Max level
    }
  }

  String get nextStageName {
    switch (stage) {
      case PetStage.egg:
        return "ベビーモコ";
      case PetStage.baby:
        return "コモコ";
      case PetStage.child:
        return "ティーンモコ";
      case PetStage.teen:
        return "おとなモコ";
      case PetStage.adult:
        return "マスターモコ";
      case PetStage.master:
        return "MAX";
    }
  }

  int get minutesUntilNextStage {
    final hours = totalMinutes / 60;
    
    switch (stage) {
      case PetStage.egg:
        return ((10 - hours) * 60).toInt();
      case PetStage.baby:
        return ((50 - hours) * 60).toInt();
      case PetStage.child:
        return ((100 - hours) * 60).toInt();
      case PetStage.teen:
        return ((300 - hours) * 60).toInt();
      case PetStage.adult:
        return ((500 - hours) * 60).toInt();
      case PetStage.master:
        return 0;
    }
  }
}

class PetService extends Notifier<PetState> {
  @override
  PetState build() {
    _loadPetState();
    return PetState.fromMinutes(0);
  }

  Future<void> _loadPetState() async {
    final db = DatabaseHelper();
    final stats = await db.getUserStats();
    final totalMinutes = stats['totalMinutes'] as int? ?? 0;
    
    state = PetState.fromMinutes(totalMinutes);
  }

  Future<void> updateFromMinutes(int totalMinutes) async {
    final oldStage = state.stage;
    final newState = PetState.fromMinutes(totalMinutes);
    state = newState;
    
    // Check if evolved
    if (newState.stage.index > oldStage.index) {
      return; // Signal evolution happened
    }
  }

  PetState getCurrentState() => state;
}

final petProvider = NotifierProvider<PetService, PetState>(PetService.new);
