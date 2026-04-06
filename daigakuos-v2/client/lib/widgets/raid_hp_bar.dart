import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../state/app_state.dart';
import 'package:intl/intl.dart';

class RaidHPBar extends ConsumerWidget {
  const RaidHPBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raidAsync = ref.watch(globalRaidProvider);
    final worldAsync = ref.watch(worldStatusProvider);

    return raidAsync.when(
      data: (raid) {
        if (raid == null) {
          return const SizedBox.shrink();
        }

        final isCursed = raid.activeSkill != null &&
            raid.skillEndsAt != null &&
            raid.skillEndsAt!.isAfter(DateTime.now());

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCursed ? const Color(0xFF2E1065) : const Color(0xFF1E293B).withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCursed ? Colors.purpleAccent.withOpacity(0.6) : Colors.redAccent.withOpacity(0.5),
              width: 2,
            ),
            color: const Color(0xFF1E293B).withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: barColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: barColor.withOpacity(0.1), blurRadius: 10)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              ),
              if (isCursed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history_toggle_off, color: Colors.purpleAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${raid.activeSkill == 'shadow_mist' ? '影の霧 (XP 0.5x)' : raid.activeSkill}: あと ${raid.skillEndsAt!.difference(DateTime.now()).inMinutes} 分",
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().slideX(),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.elasticOut,
                          width: constraints.maxWidth * (raid.healthPercentage / 100),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isCursed
                                  ? [Colors.purple, Colors.deepPurple]
                                  : [Colors.red, const Color(0xFFB91C1C)],
                            ),
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: isCursed ? Colors.purple.withOpacity(0.4) : Colors.red.withOpacity(0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                        ).animate().shimmer(duration: 2.seconds, color: Colors.white24),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${NumberFormat('#,###').format(raid.currentHp)} / ${NumberFormat('#,###').format(raid.maxHp)} HP",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade200,
                    ),
                  ),
                  Text(
                    "Ends at: ${DateFormat('HH:mm').format(raid.endsAt)}",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              if (worldAsync.asData?.value.raidBuff != 1.0)
                Padding(
                  padding: const EdgeInsets.top(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "WORLD BUFF ACTIVE: XP x${worldAsync.asData?.value.raidBuff} 🔥",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().scale(),
            ],
          ),
        ).animate().slideY(begin: -0.2, end: 0, duration: 600.ms, curve: Curves.easeOutBack).fadeIn();
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}
