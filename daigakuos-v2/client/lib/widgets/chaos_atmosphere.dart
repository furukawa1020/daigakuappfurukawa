import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class ChaosAtmosphere extends StatelessWidget {
  final double chaosLevel; // 0.0 - 1.0
  final Widget child;

  const ChaosAtmosphere({super.key, required this.chaosLevel, required this.child});

  @override
  Widget build(BuildContext context) {
    if (chaosLevel <= 0.1) return child;

    return Stack(
      children: [
        child,
        // The Entropy Fog / Static Noise overlay
        IgnorePointer(
          child: Opacity(
            opacity: chaosLevel * 0.4, // Stronger as chaos increases
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: [0.6, 1.0],
                ),
              ),
              child: _StaticNoise(intensity: chaosLevel),
            ),
          ),
        ),
        if (chaosLevel > 0.7)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.red.withOpacity(0.1),
              ).animate(onPlay: (c) => c.repeat()).shake(toggle: true, duration: 200.ms),
            ),
          ),
      ],
    );
  }
}

class _StaticNoise extends StatefulWidget {
  final double intensity;
  const _StaticNoise({required this.intensity});

  @override
  State<_StaticNoise> createState() => _StaticNoiseState();
}

class _StaticNoiseState extends State<_StaticNoise> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: 100.ms)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _NoisePainter(math.Random().nextDouble()),
        );
      },
    );
  }
}

class _NoisePainter extends CustomPainter {
  final double seed;
  _NoisePainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.1);
    final random = math.Random((seed * 1000).toInt());
    
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final w = random.nextDouble() * 2;
      canvas.drawRect(Rect.fromLTWH(x, y, w, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) => true;
}
