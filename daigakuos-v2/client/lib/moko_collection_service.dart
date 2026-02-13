import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MokoRarity {
  common,
  rare,
  legendary,
}

class MokoItem {
  final String id;
  final String name;
  final String description;
  final MokoRarity rarity;
  final IconData icon;
  final Color color;

  const MokoItem({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.icon,
    required this.color,
  });
}

const List<MokoItem> ALL_MOKO_ITEMS = [
  // Common (60%)
  MokoItem(id: "moko_marshmallow", name: "マシュマロ", description: "ふわふわで甘い。", rarity: MokoRarity.common, icon: Icons.crop_square_rounded, color: Color(0xFFFFE4E1)), // Misty Rose
  MokoItem(id: "moko_cloud", name: "白い雲", description: "空に浮かぶのんびり屋さん。", rarity: MokoRarity.common, icon: Icons.cloud, color: Color(0xFFE0F7FA)), // Cyan 50
  MokoItem(id: "moko_coffee", name: "ホットコーヒー", description: "温かい湯気でリラックス。", rarity: MokoRarity.common, icon: Icons.coffee, color: Color(0xFFD7CCC8)), // Brown 100
  MokoItem(id: "moko_succulent", name: "多肉植物", description: "デスクの小さな癒し。", rarity: MokoRarity.common, icon: Icons.local_florist, color: Color(0xFFC8E6C9)), // Green 100
  MokoItem(id: "moko_pillow", name: "ふかふか枕", description: "最高の昼寝を約束します。", rarity: MokoRarity.common, icon: Icons.bed, color: Color(0xFFE1BEE7)), // Purple 100

  // Rare (30%)
  MokoItem(id: "moko_cat", name: "眠る猫", description: "起こさないようにね。", rarity: MokoRarity.rare, icon: Icons.pets, color: Color(0xFFFFCCBC)), // Deep Orange 100
  MokoItem(id: "moko_pancakes", name: "パンケーキタワー", description: "幸せの積み重ね。", rarity: MokoRarity.rare, icon: Icons.layers, color: Color(0xFFFFF9C4)), // Yellow 100
  MokoItem(id: "moko_teddy", name: "くまのぬいぐるみ", description: "昔からの友達。", rarity: MokoRarity.rare, icon: Icons.child_care, color: Color(0xFFA1887F)), // Brown 300

  // Legendary (10%)
  MokoItem(id: "moko_moon_bunny", name: "月のうさぎ", description: "静寂の守り神。", rarity: MokoRarity.legendary, icon: Icons.nightlight_round, color: Color(0xFFFFF176)), // Yellow 300
  MokoItem(id: "moko_golden_star", name: "一番星", description: "あなたを導く光。", rarity: MokoRarity.legendary, icon: Icons.star, color: Color(0xFFFFD54F)), // Amber 300
];

class MokoCollectionService extends Notifier<List<String>> {
  int _redeemedDraws = 0;

  @override
  List<String> build() {
    _loadData();
    return [];
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList('unlocked_moko_items') ?? [];
    _redeemedDraws = prefs.getInt('redeemed_gacha_draws') ?? 0;
  }

  int getAvailableDraws(int totalMinutes) {
    // 1 Draw every 60 minutes
    final totalEarned = (totalMinutes / 60).floor();
    return max(0, totalEarned - _redeemedDraws);
  }

  Future<MokoItem?> itemDraw(int totalMinutes) async {
    final available = getAvailableDraws(totalMinutes);
    if (available <= 0) return null; // No draws

    final rand = Random();
    final roll = rand.nextDouble(); // 0.0 - 1.0

    MokoRarity targetRarity;
    if (roll < 0.6) {
      targetRarity = MokoRarity.common;
    } else if (roll < 0.9) {
      targetRarity = MokoRarity.rare;
    } else {
      targetRarity = MokoRarity.legendary;
    }

    // Filter items by rarity
    final candidates = ALL_MOKO_ITEMS.where((i) => i.rarity == targetRarity).toList();
    MokoItem selected;
    
    if (candidates.isEmpty) {
       // Fallback
       selected = ALL_MOKO_ITEMS[0];
    } else {
       selected = candidates[rand.nextInt(candidates.length)];
    }
    
    // Save Result
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Mark as redeemed
    _redeemedDraws++;
    await prefs.setInt('redeemed_gacha_draws', _redeemedDraws);
    
    // 2. Unlock Item
    if (!state.contains(selected.id)) {
      final newState = [...state, selected.id];
      state = newState;
      await prefs.setStringList('unlocked_moko_items', newState);
    }
    
    return selected;
  }
  
  bool isUnlocked(String id) => state.contains(id);
  
  List<MokoItem> getUnlockedItemsList() {
    return ALL_MOKO_ITEMS.where((i) => state.contains(i.id)).toList();
  }
  
  // Collection Stats for Phase 13
  Map<String, dynamic> getCollectionStats() {
    final total = ALL_MOKO_ITEMS.length;
    final unlocked = state.length;
    
    final commonTotal = ALL_MOKO_ITEMS.where((i) => i.rarity == MokoRarity.common).length;
    final rareTotal = ALL_MOKO_ITEMS.where((i) => i.rarity == MokoRarity.rare).length;
    final legendaryTotal = ALL_MOKO_ITEMS.where((i) => i.rarity == MokoRarity.legendary).length;
    
    final commonUnlocked = ALL_MOKO_ITEMS.where((i) => i.rarity == MokoRarity.common && state.contains(i.id)).length;
    final rareUnlocked = ALL_MOKO_ITEMS.where((i) => i.rarity == MokoRarity.rare && state.contains(i.id)).length;
    final legendaryUnlocked = ALL_MOKO_ITEMS.where((i) => i.rarity == MokoRarity.legendary && state.contains(i.id)).length;
    
    return {
      'total': total,
      'unlocked': unlocked,
      'percentage': total > 0 ? (unlocked / total) : 0.0,
      'common': {'total': commonTotal, 'unlocked': commonUnlocked},
      'rare': {'total': rareTotal, 'unlocked': rareUnlocked},
      'legendary': {'total': legendaryTotal, 'unlocked': legendaryUnlocked},
    };
  }
  
  double getCompletionPercentage() {
    final stats = getCollectionStats();
    return stats['percentage'] as double;
  }
}


final mokoCollectionProvider = NotifierProvider<MokoCollectionService, List<String>>(MokoCollectionService.new);
