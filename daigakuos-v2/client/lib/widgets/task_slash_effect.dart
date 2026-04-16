import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class TaskSlashEffect extends StatefulWidget {
  final Stream<void> trigger;

  const TaskSlashEffect({super.key, required this.trigger});

  @override
  State<TaskSlashEffect> createState() => _TaskSlashEffectState();
}

class _TaskSlashEffectState extends State<TaskSlashEffect> with SingleTickerProviderStateMixin {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    widget.trigger.listen((_) => _startSlash());
  }

  void _startSlash() async {
    if (_isVisible) return;
    setState(() => _isVisible = true);
    await Future.delayed(600.ms);
    if (mounted) setState(() => _isVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return IgnorePointer(
      child: Center(
        child: CustomPaint(
          size: const Size(400, 400),
          painter: _SlashPainter(),
        )
        .animate()
        .scale(begin: const Offset(0.2, 0.2), end: const Offset(2.0, 2.0), curve: Curves.easeOutBack)
        .blur(begin: const Offset(20, 20), end: const Offset(0, 0))
        .fadeOut(delay: 400.ms),
      ),
    );
  }
}

class _SlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.white, Colors.cyanAccent, Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticTo(size.width * 0.5, size.height * 0.5, size.width, size.height * 0.2);

    // Draw the main slash and a glow
    canvas.drawPath(path, paint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0);
    
    // Add "Particles"
    final particlePaint = Paint()..color = Colors.cyanAccent.withOpacity(0.6);
    final random = math.Random();
    for (int i = 0; i < 20; i++) {
        canvas.drawCircle(
          Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
          random.nextDouble() * 3,
          particlePaint
        );
    }
  }

  @override
  bool shouldRepaint(covariant _SlashPainter oldDelegate) => false;
}
