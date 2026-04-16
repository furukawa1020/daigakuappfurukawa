import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class MHGaugePainter extends CustomPainter {
  final double ratio;
  final Color color;
  final bool isPoisoned;

  MHGaugePainter({required this.ratio, required this.color, this.isPoisoned = false});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - 10, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(10, size.height)
      ..close();

    canvas.drawPath(path, bgPaint);
    canvas.drawPath(path, borderPaint);

    if (ratio > 0) {
      final double fillWidth = size.width * ratio;
      final Paint fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color,
            color.withOpacity(0.6),
            color,
          ],
        ).createShader(Rect.fromLTWH(0, 0, fillWidth, size.height));

      final Path fillPath = Path()
        ..moveTo(0, 0)
        ..lineTo(fillWidth - 10, 0)
        ..lineTo(fillWidth, size.height)
        ..lineTo(10, size.height)
        ..close();

      canvas.drawPath(fillPath, fillPaint);
      
      // Add "Segment" lines for texture
      final Paint linePaint = Paint()
        ..color = Colors.black26
        ..strokeWidth = 1;
      
      for (double i = 20; i < fillWidth; i += 20) {
        canvas.drawLine(Offset(i, 0), Offset(i + 10, size.height), linePaint);
      }
      
      // Top Glow highlight
      final Paint glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
       canvas.drawLine(const Offset(5, 2), Offset(fillWidth - 8, 2), glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MHGaugePainter oldDelegate) => 
    oldDelegate.ratio != ratio || oldDelegate.color != color;
}

class VitalityHUD extends StatelessWidget {
  final int hp;
  final int maxHp;
  final int stamina;
  final int maxStamina;
  final Map<String, dynamic> statusEffects;

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGauge(
            label: "HP",
            current: hp,
            max: maxHp,
            color: statusEffects.containsKey('poisoned') ? const Color(0xFF9333EA) : const Color(0xFF22C55E),
            isPoisoned: statusEffects.containsKey('poisoned'),
          ),
          const SizedBox(height: 8),
          _buildGauge(
            label: "ST",
            current: stamina,
            max: maxStamina,
            color: const Color(0xFFEAB308),
          ),
        ],
      ),
    );
  }

  Widget _buildGauge({
    required String label,
    required int current,
    required int max,
    required Color color,
    bool isPoisoned = false,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(200, 14),
          painter: MHGaugePainter(
            ratio: (current / max).clamp(0.0, 1.0),
            color: color,
            isPoisoned: isPoisoned,
          ),
        ),
        if (isPoisoned) 
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text("🤢", style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}
