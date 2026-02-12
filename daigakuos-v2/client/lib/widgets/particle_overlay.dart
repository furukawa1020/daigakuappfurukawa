import 'dart:math';
import 'package:flutter/material.dart';

/// Particle Effect Overlay
/// Displays floating particles for celebrations
class ParticleOverlay extends StatefulWidget {
  final ParticleType type;
  final VoidCallback? onComplete;

  const ParticleOverlay({
    super.key,
    this.type = ParticleType.stars,
    this.onComplete,
  });

  @override
  State<ParticleOverlay> createState() => _ParticleOverlayState();
}

enum ParticleType {
  stars,
  sparkles,
  hearts,
}

class _ParticleOverlayState extends State<ParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Generate particles
    for (int i = 0; i < 30; i++) {
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble() * 0.3 + 0.7, // Start from bottom
        size: _random.nextDouble() * 15 + 10,
        speedX: (_random.nextDouble() - 0.5) * 0.3,
        speedY: -_random.nextDouble() * 0.5 - 0.3,
        rotation: _random.nextDouble() * pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
        color: _getColor(),
        opacity: 1.0,
      ));
    }

    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  Color _getColor() {
    switch (widget.type) {
      case ParticleType.stars:
        return [
          const Color(0xFFFFD700), // Gold
          const Color(0xFFFFA500), // Orange
          const Color(0xFFFFFF00), // Yellow
        ][_random.nextInt(3)];
      case ParticleType.sparkles:
        return [
          const Color(0xFFB5EAD7),
          const Color(0xFFC7CEEA),
          const Color(0xFFFFB7B2),
        ][_random.nextInt(3)];
      case ParticleType.hearts:
        return [
          const Color(0xFFFF69B4),
          const Color(0xFFFFB7B2),
          const Color(0xFFFFC0CB),
        ][_random.nextInt(3)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            type: widget.type,
          ),
          child: Container(),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Particle {
  double x;
  double y;
  final double size;
  final double speedX;
  final double speedY;
  double rotation;
  final double rotationSpeed;
  final Color color;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.opacity,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final ParticleType type;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.type,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Update positions
      particle.x += particle.speedX * progress;
      particle.y += particle.speedY * progress;
      particle.rotation += particle.rotationSpeed * progress;
      
      // Fade out in last 30%
      if (progress > 0.7) {
        particle.opacity = 1.0 - ((progress - 0.7) / 0.3);
      }

      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      final position = Offset(
        particle.x * size.width,
        particle.y * size.height,
      );

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(particle.rotation);

      switch (type) {
        case ParticleType.stars:
          _drawStar(canvas, particle.size, paint);
          break;
        case ParticleType.sparkles:
          _drawSparkle(canvas, particle.size, paint);
          break;
        case ParticleType.hearts:
          _drawHeart(canvas, particle.size, paint);
          break;
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    const points = 5;
    final angle = pi / points;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? size : size / 2;
      final x = r * cos(i * angle - pi / 2);
      final y = r * sin(i * angle - pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSparkle(Canvas canvas, double size, Paint paint) {
    // Cross shape
    final rect1 = Rect.fromCenter(center: Offset.zero, width: size * 2, height: size / 2);
    final rect2 = Rect.fromCenter(center: Offset.zero, width: size / 2, height: size * 2);
    
    canvas.drawRect(rect1, paint);
    canvas.drawRect(rect2, paint);
  }

  void _drawHeart(Canvas canvas, double size, Paint paint) {
    final path = Path();
    path.moveTo(0, size / 4);
    
    // Left curve
    path.cubicTo(-size / 2, -size / 3, -size, 0, -size / 2, size / 2);
    path.lineTo(0, size);
    
    // Right curve
    path.lineTo(size / 2, size / 2);
    path.cubicTo(size, 0, size / 2, -size / 3, 0, size / 4);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
