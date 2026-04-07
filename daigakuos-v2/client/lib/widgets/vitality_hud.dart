import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VitalityHUD extends StatelessWidget {
  final int hp;
  final int maxHp;
  final int stamina;
  final int maxStamina;
  final Map<String, dynamic> statusEffects; // Phase 46

  const VitalityHUD({
    super.key,
    required this.hp,
    required this.maxHp,
    required this.stamina,
    required this.maxStamina,
    required this.statusEffects,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HP Bar
          _buildBar(
            label: "HP",
            current: hp,
            max: maxHp,
            color: statusEffects.containsKey('poisoned') ? const Color(0xFF9333EA) : const Color(0xFF22C55E),
            icon: Icons.favorite,
            statusIcon: statusEffects.containsKey('poisoned') ? '🤢' : null,
          ),
          const SizedBox(height: 6),
          // Stamina Bar
          _buildBar(
            label: "ST",
            current: stamina,
            max: maxStamina,
            color: const Color(0xFFEAB308),
            icon: Icons.bolt,
            statusIcon: statusEffects.containsKey('stunned') ? '💫' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBar({
    required String label,
    required int current,
    required int max,
    required Color color,
    required IconData icon,
    String? statusIcon,
  }) {
    final double width = 180.0;
    final double ratio = current / max;
    final bool isLow = ratio < 0.25;

    return Row(
      children: [
        Container(
          width: 24,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isLow ? Colors.redAccent : Colors.white70,
            ),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Background
            Container(
              height: 12,
              width: width,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border: Border.all(color: Colors.white05),
              ),
            ),
            // Progress
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 12,
              width: width * ratio,
              decoration: BoxDecoration(
                color: isLow && label == "HP" && statusIcon == null ? Colors.redAccent : color,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isLow ? Colors.redAccent : color).withOpacity(0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ).animate(target: isLow ? 1 : 0).shimmer(duration: 1.seconds),
            if (statusIcon != null)
              Positioned(
                right: -20,
                top: -4,
                child: Text(statusIcon, style: const TextStyle(fontSize: 14)).animate().shake(),
              ),
          ],
        ),
      ],
    );
  }
}
