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
      'name': 'モコ特製・秘伝の肉煮込み', 
      'buffs': '体力・スタミナ上限 +50',
      'icon': '🍲',
      'color': Colors.greenAccent,
      'flavor': '何代にもわたって受け継がれてきた、濃厚な出汁の香りが鼻腔をくすぐるもこ。',
    },
    'hunter_steak': { 
      'name': '豪傑の極厚ステーキ', 
      'buffs': '攻撃力 +15% (Master Rank)',
      'icon': '🍖',
      'color': Colors.orangeAccent,
      'flavor': '強大なモンスターの肉を直火で豪快に焼き上げた、力と勇気を象徴する一皿だもこ。',
    },
    'veggie_platter': { 
      'name': '深緑の豊穣野菜盛り', 
      'buffs': '防御力 +20%',
      'icon': '🥗',
      'color': Colors.cyanAccent,
      'flavor': '森の恵みを凝縮した一皿。体の芯から抵抗力が高まるのを感じるもこ。',
    }
  };

  Future<void> _eat(String mealId) async {
    setState(() => _isEating = true);
    final deviceId = ref.read(deviceIdProvider);
    
    // Play "Gourmet Kitchen" animation
    await Future.delayed(const Duration(seconds: 4));
    
    try {
      final result = await ApiService().eat(deviceId, mealId);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Text("完食！ご馳走様もこ！✨", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.amberAccent, size: 48),
                const SizedBox(height: 16),
                Text(result['message'], style: const TextStyle(color: Colors.white70)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("戦場へ戻る")),
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
          // Background textures
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.network(
                'https://www.transparenttextures.com/patterns/carbon-fibre.png',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: const Color(0xFF1E293B),
                flexibleSpace: FlexibleSpaceBar(
                   centerTitle: true,
                  title: Text(
                    "MOKO'S GOURMET KITCHEN", 
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://images.unsplash.com/photo-1547523106-3f6ef05f2fa4?auto=format&fit=crop&q=80',
                        fit: BoxFit.cover,
                      ),
                      Container(  // Better Gradient
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withOpacity(0.2), const Color(0xFF0F172A)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final id = _meals.keys.elementAt(index);
                      final meal = _meals[id];
                      return _buildPlatter(id, meal);
                    },
                    childCount: _meals.length,
                  ),
                ),
              ),
            ],
          ),
          if (_isEating)
            Container(
              color: Colors.black.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("🍳🔥🥘🍖", style: TextStyle(fontSize: 60)).animate(onPlay: (c) => c.repeat()).shake(duration: 800.ms),
                    const SizedBox(height: 32),
                    Text(
                      "調理中だもこ！最高の食材を厳選しているもこ...",
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ).animate().fadeIn().shimmer(duration: 2.seconds),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlatter(String id, dynamic meal) {
    return Container(
      margin: const EdgeInsets.bottom(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          onTap: _isEating ? null : () => _eat(id),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(meal['icon'], style: const TextStyle(fontSize: 48)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: meal['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: meal['color'].withOpacity(0.3)),
                      ),
                      child: Text(
                        "READY",
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: meal['color']),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  meal['name'],
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  meal['buffs'],
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.amberAccent, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  meal['flavor'],
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white54, height: 1.5),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.restaurant_menu, color: Colors.white24, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "TAP TO START FEAST",
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white24, letterSpacing: 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.1, end: 0);
  }
}
