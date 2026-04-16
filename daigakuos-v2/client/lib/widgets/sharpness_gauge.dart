import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SharpnessGauge extends StatelessWidget {
  final int current;
  final int max;
  final String colorName;

  const SharpnessGauge({
    super.key,
    required this.current,
    required this.max,
    required this.colorName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SHARPNESS",
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white54,
                ),
              ),
              Text(
                colorName.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _getColor(colorName),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 6,
                width: (MediaQuery.of(context).size.width - 60) * (current / max),
                decoration: BoxDecoration(
                  color: _getColor(colorName),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(color: _getColor(colorName).withOpacity(0.4), blurRadius: 4),
                  ],
                ),
              ).animate().shimmer(duration: 2.seconds, color: Colors.white24),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColor(String name) {
    switch (name) {
      case 'white': return const Color(0xFFF8FAFC);
      case 'blue': return const Color(0xFF3B82F6);
      case 'green': return const Color(0xFF22C55E);
      case 'yellow': return const Color(0xFFEAB308);
      case 'orange': return const Color(0xFFF97316);
      case 'red': return const Color(0xFFEF4444);
      default: return Colors.grey;
    }
  }
}
