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

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "GLOBAL RAID EVENT",
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          raid.title,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 32)
                      .animate(onPlay: (controller) => controller.repeat())
                      .shake(duration: 2000.ms, hz: 4),
                ],
              ),
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
                            gradient: const LinearGradient(
                              colors: [Colors.red, Color(0xFFB91C1C)],
                            ),
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
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
