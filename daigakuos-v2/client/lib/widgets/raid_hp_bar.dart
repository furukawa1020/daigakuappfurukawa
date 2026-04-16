import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';

class RaidHPBar extends ConsumerWidget {
  const RaidHPBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raidAsync = ref.watch(globalRaidProvider);
    final worldAsync = ref.watch(worldStatusProvider);

    return raidAsync.when(
      data: (raid) {
        if (raid == null) return const SizedBox.shrink();

        final isCursed = raid.activeSkill != null &&
            raid.skillEndsAt != null &&
            raid.skillEndsAt!.isAfter(DateTime.now());

        final isPhase2 = raid.currentPhase >= 2;
        final barColor = isCursed 
            ? Colors.deepPurpleAccent 
            : (isPhase2 ? Colors.orangeAccent : Colors.redAccent);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isCursed 
                ? const Color(0xFF2E1065).withOpacity(0.9) 
                : const Color(0xFF1E293B).withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: barColor.withOpacity(0.4),
              width: isPhase2 ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(color: barColor.withOpacity(0.1), blurRadius: 15, spreadRadius: 2)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isCursed ? "BOSS CURSED ⚠️" : (isPhase2 ? "PHASE 2: ENRAGED 🔥" : "WORLD RAID"),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: barColor,
                            ),
                          ),
                          if (isPhase2)
                             const Icon(Icons.bolt, size: 12, color: Colors.orangeAccent)
                               .animate(onPlay: (c) => c.repeat()).shake(hz: 3),
                        ],
                      ),
                      if (worldAsync.asData?.value.monsterState != null)
                        _buildMonsterStateBadge(worldAsync.asData!.value.monsterState!),
                      const SizedBox(height: 4),
                      Text(
                        raid.title,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                         BoxShadow(color: barColor.withOpacity(0.3), blurRadius: 10)
                      ],
                    ),
                    child: const Icon(Icons.adb, color: Colors.white70, size: 30)
                      .animate(onPlay: (c) => c.repeat()).shake(duration: 2.seconds, hz: 4),
                  ),
                ],
              ),
              if (isCursed) _buildCurseBanner(raid),
              if (worldAsync.asData?.value.activeGimmick != null)
                _buildGimmickBanner(worldAsync.asData!.value.gimmickName ?? "ギミック発動中"),
              const SizedBox(height: 16),
              _buildHPBar(context, raid, barColor, worldAsync.asData?.value.activeGimmick),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${NumberFormat('#,###').format(raid.currentHp)} / ${NumberFormat('#,###').format(raid.maxHp)} HP",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    "${raid.healthPercentage.toStringAsFixed(1)}%",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: barColor,
                    ),
                  ),
                ],
              ),
              if (worldAsync.asData?.value.raidBuff != 1.0)
                _buildWorldBuffBanner(worldAsync.asData!.value.raidBuff),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildHPBar(BuildContext context, GlobalRaid raid, Color color, String? gimmick) {
    final hasIronDefense = gimmick == 'iron_defense';
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 16,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutExpo,
                width: constraints.maxWidth * (raid.healthPercentage / 100),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.4), blurRadius: 4),
                  ],
                ),
              ).animate().shimmer(duration: 3.seconds, color: Colors.white24),
              // Gimmick Shield Effect
              if (hasIronDefense)
                const Positioned.fill(
                  child: Icon(Icons.shield, color: Colors.white24, size: 14)
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.seconds),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGimmickBanner(String name) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orangeAccent, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "ギミック：【$name】発動中！",
                style: GoogleFonts.inter(fontSize: 12, color: Colors.orangeAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shake(hz: 2);
  }

  Widget _buildCurseBanner(GlobalRaid raid) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.history_toggle_off, color: Colors.purpleAccent, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "呪い：${raid.activeSkill == 'shadow_mist' ? '影の霧' : raid.activeSkill} 発動中！",
                style: GoogleFonts.inter(fontSize: 12, color: Colors.purpleAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildMonsterStateBadge(Map<String, dynamic> state) {
    return Container(
      margin: const EdgeInsets.top(4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(state['icon'] ?? '😐', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            "STATE: ${state['name']}".toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldBuffBanner(double buff) {
    return Padding(
      padding: const EdgeInsets.top(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flash_on, color: Colors.amber, size: 16),
            const SizedBox(width: 6),
            Text(
              "WORLD BUFF: XP x$buff 🔥",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale();
  }
}
