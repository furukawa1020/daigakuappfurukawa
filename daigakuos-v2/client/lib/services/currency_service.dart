import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database_helper.dart';

enum CurrencyType {
  mokoCoins,
  starCrystals,
  campusGems,
}

class CurrencyState {
  final int mokoCoins;
  final int starCrystals;
  final int campusGems;

  CurrencyState({
    required this.mokoCoins,
    required this.starCrystals,
    required this.campusGems,
  });

  CurrencyState copyWith({
    int? mokoCoins,
    int? starCrystals,
    int? campusGems,
  }) {
    return CurrencyState(
      mokoCoins: mokoCoins ?? this.mokoCoins,
      starCrystals: starCrystals ?? this.starCrystals,
      campusGems: campusGems ?? this.campusGems,
    );
  }
}

class CurrencyService extends Notifier<CurrencyState> {
  @override
  CurrencyState build() {
    _loadBalances();
    return CurrencyState(mokoCoins: 0, starCrystals: 0, campusGems: 0);
  }

  Future<void> _loadBalances() async {
    final db = DatabaseHelper();
    final database = await db.database;
    final res = await database.query('currencies', where: 'user_id = ?', whereArgs: ['default']);
    
    if (res.isNotEmpty) {
      state = CurrencyState(
        mokoCoins: res.first['moko_coins'] as int? ?? 0,
        starCrystals: res.first['star_crystals'] as int? ?? 0,
        campusGems: res.first['campus_gems'] as int? ?? 0,
      );
    }
  }

  Future<void> addMokoCoins(int amount) async {
    final db = DatabaseHelper();
    final database = await db.database;
    
    final newAmount = state.mokoCoins + amount;
    await database.update(
      'currencies',
      {'moko_coins': newAmount},
      where: 'user_id = ?',
      whereArgs: ['default'],
    );
    
    state = state.copyWith(mokoCoins: newAmount);
  }

  Future<void> addStarCrystals(int amount) async {
    final db = DatabaseHelper();
    final database = await db.database;
    
    final newAmount = state.starCrystals + amount;
    await database.update(
      'currencies',
      {'star_crystals': newAmount},
      where: 'user_id = ?',
      whereArgs: ['default'],
    );
    
    state = state.copyWith(starCrystals: newAmount);
  }

  Future<void> addCampusGems(int amount) async {
    final db = DatabaseHelper();
    final database = await db.database;
    
    final newAmount = state.campusGems + amount;
    await database.update(
      'currencies',
      {'campus_gems': newAmount},
      where: 'user_id = ?',
      whereArgs: ['default'],
    );
    
    state = state.copyWith(campusGems: newAmount);
  }

  Future<bool> spend(CurrencyType type, int amount) async {
    int currentBalance;
    
    switch (type) {
      case CurrencyType.mokoCoins:
        currentBalance = state.mokoCoins;
        break;
      case CurrencyType.starCrystals:
        currentBalance = state.starCrystals;
        break;
      case CurrencyType.campusGems:
        currentBalance = state.campusGems;
        break;
    }
    
    if (currentBalance < amount) {
      return false; // Not enough balance
    }
    
    final db = DatabaseHelper();
    final database = await db.database;
    
    switch (type) {
      case CurrencyType.mokoCoins:
        final newAmount = state.mokoCoins - amount;
        await database.update(
          'currencies',
          {'moko_coins': newAmount},
          where: 'user_id = ?',
          whereArgs: ['default'],
        );
        state = state.copyWith(mokoCoins: newAmount);
        break;
      case CurrencyType.starCrystals:
        final newAmount = state.starCrystals - amount;
        await database.update(
          'currencies',
          {'star_crystals': newAmount},
          where: 'user_id = ?',
          whereArgs: ['default'],
        );
        state = state.copyWith(starCrystals: newAmount);
        break;
      case CurrencyType.campusGems:
        final newAmount = state.campusGems - amount;
        await database.update(
          'currencies',
          {'campus_gems': newAmount},
          where: 'user_id = ?',
          whereArgs: ['default'],
        );
        state = state.copyWith(campusGems: newAmount);
        break;
    }
    
    return true;
  }

  CurrencyState getBalances() => state;
}

final currencyProvider = NotifierProvider<CurrencyService, CurrencyState>(CurrencyService.new);
