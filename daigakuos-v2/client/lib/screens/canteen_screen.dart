import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

class CanteenScreen extends ConsumerStatefulWidget {
  const CanteenScreen({super.key});

  @override
  ConsumerState<CanteenScreen> createState() => _CanteenScreenState();
}

class _CanteenScreenState extends ConsumerState<CanteenScreen> {
  bool _isEating = false;

  final Map<String, dynamic> _meals = {
    'moko_stew': { 
      'name': 'モコ特製煮込み', 
      'buffs': '体力・スタミナ上限UP',
      'icon': '🍲',
      'color': Colors.greenAccent,
    },
    'hunter_steak': { 
      'name': 'ハンター・ステーキ', 
      'buffs': '攻撃力 +15%',
      'icon': '🍖',
      'color': Colors.orangeAccent,
    },
    'veggie_platter': { 
      'name': '山盛り野菜盛り合わせ', 
      'buffs': '防御力 +20%',
      'icon': '🥗',
      'color': Colors.cyanAccent,
    }
  };

  Future<void> _eat(String mealId) async {
    setState(() => _isEating = true);
    final deviceId = ref.read(deviceIdProvider);
    
    // Play "Eating" animation/delay
    await Future.delayed(const Duration(seconds: 3));
    
    try {
      final result = await ApiService().eat(deviceId, mealId);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text("ごちそうさまだもこ！😋", style: TextStyle(color: Colors.white)),
            content: Text(result['message'], style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("いくもこ！")),
            ],
          ),
        );
      }
      ref.refresh(userProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isEating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: const Color(0xFF1E293B),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text("MOKO'S CANTEEN", style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&q=80',
                        fit: BoxFit.cover,
                      ),
                      Container(color: Colors.black.withOpacity(0.4)),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final id = _meals.keys.elementAt(index);
                      final meal = _meals[id];
                      return _buildMealCard(id, meal);
                    },
                    childCount: _meals.length,
                  ),
                ),
              ),
            ],
          ),
          if (_isEating)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("もぐもぐ... 🍖", style: TextStyle(fontSize: 48)).animate(onPlay: (c) => c.repeat()).shake(duration: 500.ms),
                    const SizedBox(height: 24),
                    Text(
                      "食事中だもこ！力を蓄えているもこ...",
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ).animate().fadeIn(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMealCard(String id, dynamic meal) {
    return Container(
      margin: const EdgeInsets.bottom(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: InkWell(
        onTap: _isEating ? null : () => _eat(id),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text(meal['icon'], style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal['name'],
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meal['buffs'],
                      style: GoogleFonts.inter(fontSize: 12, color: meal['color'], fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}
