import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

class CombinationScreen extends ConsumerStatefulWidget {
  const CombinationScreen({super.key});

  @override
  ConsumerState<CombinationScreen> createState() => _CombinationScreenState();
}

class _CombinationScreenState extends ConsumerState<CombinationScreen> {
  final Map<String, dynamic> _recipes = {
    'potion': { 
      'name': '回復薬', 
      'materials': {'herb': 1, 'blue_mushroom': 1},
      'icon': '🧪',
    },
    'mega_potion': { 
      'name': '回復薬グレート', 
      'materials': {'potion': 1, 'honey': 1},
      'icon': '🍯',
    },
    'antidote': { 
      'name': '解毒薬', 
      'materials': {'antidote_herb': 1, 'blue_mushroom': 1},
      'icon': '🌿',
    },
    'energy_drink': { 
      'name': 'エナジードリンク', 
      'materials': {'honey': 1, 'nitroshroom': 1},
      'icon': '⚡',
    }
  };

  Future<void> _combine(String id) async {
    final deviceId = ref.read(deviceIdProvider);
    try {
      final result = await ApiService().combine(deviceId, id);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message']), backgroundColor: Colors.greenAccent),
          );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error']), backgroundColor: Colors.redAccent),
          );
        }
      }
      ref.refresh(userProvider);
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("ITEM COMBINATION", style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: userAsync.when(
        data: (user) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader("CRAFTING RECIPES"),
            ..._recipes.entries.map((e) => _buildRecipeCard(user, e.key, e.value)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amberAccent, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildRecipeCard(User user, String id, dynamic recipe) {
    final mats = Map<String, int>.from(recipe['materials']);
    bool canCraft = true;
    mats.forEach((mat, count) {
      final total = (user.inventory[mat] ?? 0) + (user.materials[mat] ?? 0);
      if (total < count) canCraft = false;
    });

    return Container(
      margin: const EdgeInsets.bottom(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: canCraft ? Colors.amberAccent.withOpacity(0.3) : Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(recipe['icon'], style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recipe['name'],
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: canCraft ? () => _combine(id) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white10,
                  ),
                  child: const Text("調合"),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),
            Row(
              children: mats.entries.map((m) {
                final total = (user.inventory[m.key] ?? 0) + (user.materials[m.key] ?? 0);
                final has = total >= m.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    "${m.key}: $total/${m.value}",
                    style: GoogleFonts.inter(fontSize: 10, color: has ? Colors.white70 : Colors.redAccent),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}
