import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';

class BossArchiveScreen extends ConsumerWidget {
  const BossArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1E293B),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "BOSS ARCHIVE",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1614728263952-84ea256f9679?auto=format&fit=crop&q=80',
                    fit: BoxFit.cover,
                  ).animate().fadeIn(duration: 800.ms),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0F172A).withOpacity(0.8),
                          const Color(0xFF0F172A),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          userAsync.when(
            data: (user) {
              final archive = user.bossArchive;
              if (archive.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_stories, color: Colors.white24, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          "記録はまだないもこ...",
                          style: GoogleFonts.inter(color: Colors.white38),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "レイドボスを倒して部位を集めるもこ！",
                          style: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final bossKey = archive.keys.elementAt(index);
                      final bossData = archive[bossKey];
                      return _buildBossCard(bossKey, bossData);
                    },
                    childCount: archive.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, st) => SliverFillRemaining(child: Center(child: Text("Error: $e"))),
          ),
        ],
      ),
    );
  }

  Widget _buildBossCard(String key, dynamic data) {
    final parts = List<String>.from(data['parts'] ?? []);
    final kills = data['kills'] ?? 0;
    final isComplete = parts.length >= 3;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isComplete ? Colors.amberAccent.withOpacity(0.3) : Colors.white10,
          width: isComplete ? 2 : 1,
        ),
        boxShadow: isComplete ? [
          BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
        ] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (isComplete)
              Positioned(
                right: -10,
                top: -10,
                child: RotationTransition(
                   turns: const AlwaysStoppedAnimation(15 / 360),
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                     color: Colors.amber,
                     child: Text(
                       "COMPLETED",
                       style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87),
                     ),
                   ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        isComplete ? '🏆' : '💀',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    key.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$kills KILLS",
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildPartIndicator('C', parts.contains('core')),
                      _buildPartIndicator('S', parts.contains('shell')),
                      _buildPartIndicator('E', parts.contains('essence')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildPartIndicator(String label, bool active) {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: active ? Colors.cyanAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: active ? Colors.cyanAccent : Colors.white10),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: active ? Colors.cyanAccent : Colors.white24,
          ),
        ),
      ),
    );
  }
}
