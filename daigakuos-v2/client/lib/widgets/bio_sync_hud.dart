import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class BioHelixGaugePainter extends CustomPainter {
  final double order;  // 0.0 - 1.0 (Streak/Discipline)
  final double entropy; // 0.0 - 1.0 (Chaos/Tasks)
  final double animationValue;

  BioHelixGaugePainter({
    required this.order,
    required this.entropy,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    final double width = size.width;
    
    // Wave parameters
    final double amplitude = 8.0 + (entropy * 15.0); // Higher chaos = Wilder waves
    final double frequency = 0.05 + (order * 0.05); // Higher order = Faster rhythm

    void drawStrand(Color color, bool inverse, double glow) {
      final Paint paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 + (glow * 2.0)
        ..strokeCap = StrokeCap.round;

      final Path path = Path();
      bool first = true;

      for (double x = 0; x <= width; x += 2) {
        final double phase = (x * frequency) + (animationValue * 2 * math.pi);
        double y = midY + math.sin(phase) * amplitude * (inverse ? -1 : 1);
        
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      
      // Glow effect
      canvas.drawPath(path, paint..maskFilter = MaskFilter.blur(BlurStyle.normal, glow * 4));
      canvas.drawPath(path, Paint()..color = Colors.white.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    }

    // Strand Alpha: Order (Golden)
    drawStrand(const Color(0xFFFFD700), false, order);
    
    // Strand Beta: Life Force (Cyan)
    drawStrand(const Color(0xFF00FFFF), true, 0.5);

    // Connecting pulses
    final Paint pulsePaint = Paint()..color = Colors.white24..strokeWidth = 1.0;
    for (double x = 0; x <= width; x += 30) {
       final double phase = (x * frequency) + (animationValue * 2 * math.pi);
       final double y1 = midY + math.sin(phase) * amplitude;
       final double y2 = midY + math.sin(phase) * amplitude * -1;
       canvas.drawLine(Offset(x, y1), Offset(x, y2), pulsePaint);
    }
  }

  @override
  bool shouldRepaint(covariant BioHelixGaugePainter oldDelegate) => true;
}

class BioSyncHUD extends StatefulWidget {
  final double orderLevel;
  final double chaosLevel;
  final int hp;
  final int maxHp;
  final double oxygenLevel; // Phase 52
  final double toxinLevel;  // Phase 52
  final int stamina;        // Phase 53
  final int maxStamina;     // Phase 53
  final String? fieldNotes; // Phase 60

  const BioSyncHUD({
    super.key,
    required this.orderLevel,
    required this.chaosLevel,
    required this.hp,
    required this.maxHp,
    required this.oxygenLevel,
    required this.toxinLevel,
    required this.stamina,
    required this.maxStamina,
    this.fieldNotes,
  });

  @override
  State<BioSyncHUD> createState() => _BioSyncHUDState();
}

class _BioSyncHUDState extends State<BioSyncHUD> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double hpRatio = (widget.hp / widget.maxHp).clamp(0.0, 1.0);
    final double oxRatio = (widget.oxygenLevel / 100.0).clamp(0.0, 1.0);
    final double toxRatio = (widget.toxinLevel / 100.0).clamp(0.0, 1.0);
    final double stRatio = (widget.stamina / widget.maxStamina).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "BIO-SYNC INTEGRITY",
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent.withOpacity(0.8),
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                "${(hpRatio * 100).toInt()}%",
                style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              // The Helix
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(double.infinity, 40),
                    painter: BioHelixGaugePainter(
                      order: widget.orderLevel,
                      entropy: widget.chaosLevel,
                      animationValue: _controller.value,
                    ),
                  );
                },
              ),
              // HP Overlay (Dying out from right)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerRight,
                  widthFactor: 1.0 - hpRatio,
                  child: Container(color: Colors.black.withOpacity(0.6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatInfo("METABOLIC SYNC", widget.orderLevel, Colors.amberAccent),
              _buildStatInfo("TOXIN LOAD", widget.chaosLevel, Colors.redAccent),
            ],
          ),
          const SizedBox(height: 12),
          // Phase 60: Field Observer Terminal
          if (widget.fieldNotes != null)
            Container(
              height: 80,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white10),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.fieldNotes!,
                  style: GoogleFonts.shareTechMono(
                    fontSize: 9, 
                    color: const Color(0xFFB5EAD7), 
                    height: 1.4
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Phase 52: Metabolic Depth
          Row(
            children: [
              _buildMetabolicBar("OXYGEN", oxRatio, Colors.greenAccent),
              const SizedBox(width: 8),
              _buildMetabolicBar("TOXINS", toxRatio, Colors.deepPurpleAccent),
              const SizedBox(width: 8),
              _buildMetabolicBar("STAMINA", stRatio, Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetabolicBar(String label, double ratio, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.white24)),
          const SizedBox(height: 2),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatInfo(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white38)),
        Container(
          width: 60,
          height: 2,
          color: Colors.white12,
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(color: color),
          ),
        ),
      ],
    );
  }
}
