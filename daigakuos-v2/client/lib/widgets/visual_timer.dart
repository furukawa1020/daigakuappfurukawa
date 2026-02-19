import 'dart:math';
import 'package:flutter/material.dart';

class VisualTimer extends StatefulWidget {
  final Duration elapsed;
  final int? targetMinutes;
  final Color color;

  const VisualTimer({
    super.key,
    required this.elapsed,
    this.targetMinutes,
    this.color = Colors.white,
  });

  @override
  State<VisualTimer> createState() => _VisualTimerState();
}

class _VisualTimerState extends State<VisualTimer> {
  // If target exists, default to Visual (true). If no target, forced Digital (false).
  late bool _showVisual;

  @override
  void initState() {
    super.initState();
    _showVisual = widget.targetMinutes != null;
  }

  @override
  void didUpdateWidget(covariant VisualTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetMinutes != oldWidget.targetMinutes) {
       // If purely switching from null to non-null or vice versa
       if (widget.targetMinutes == null) {
         _showVisual = false;
       } else if (oldWidget.targetMinutes == null) {
         _showVisual = true;
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(widget.elapsed.inMinutes);
    final seconds = twoDigits(widget.elapsed.inSeconds % 60);
    final textStyle = TextStyle(
        color: widget.color, 
        fontSize: 80, 
        fontWeight: FontWeight.w200, 
        fontFamily: 'monospace'
    );

    if (widget.targetMinutes == null) {
      // Unlimited mode: Always Digital
      return Text("$minutes:$seconds", style: textStyle);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showVisual = !_showVisual;
        });
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showVisual
            ? SizedBox(
                key: const ValueKey('visual'),
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _PieTimerPainter(
                    elapsed: widget.elapsed,
                    targetMinutes: widget.targetMinutes!,
                    color: widget.color,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         // Small Digital Overlay
                         Text(
                           "$minutes:$seconds", 
                           style: textStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           "/${widget.targetMinutes}:00",
                           style: TextStyle(color: widget.color.withOpacity(0.7), fontSize: 12),
                         )
                      ],
                    ),
                  )
                ),
              )
            : Text(
                key: const ValueKey('digital'),
                "$minutes:$seconds", 
                style: textStyle
              ),
      ),
    );
  }
}

class _PieTimerPainter extends CustomPainter {
  final Duration elapsed;
  final int targetMinutes;
  final Color color;

  _PieTimerPainter({
    required this.elapsed,
    required this.targetMinutes,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final strokeWidth = 8.0;

    // Background Circle (Outline)
    final bgPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth/2, bgPaint);

    // Calculate progress
    // "Time Timer" usually shows "Remaining Time" as a filled wedge that disappears
    // Or "Elapsed Time" as a filling wedge. 
    // Let's do "Remaining Time" (Red wedge) that shrinks, or "Progress" (Filling up)?
    // The prompt implementation suggested "un-fills (or fills)".
    // Let's do "Filling" for consistency with bar loading, OR "Disappearing" for deadline pressure.
    // Time Timer standard is "Disappearing Red Disk". Let's try Disappearing wedge.
    // But we need to make it look positive.
    // Let's do: Start Full. Shrink as time passes.
    
    final totalSeconds = targetMinutes * 60;
    final elapsedSeconds = elapsed.inSeconds;
    final remainingPct = 1.0 - (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);

    final sweepAngle = 2 * pi * remainingPct;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.8) // Use theme color
      ..style = PaintingStyle.fill;

    // Draw Pie Wedge
    // Start from top (-pi/2)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth * 2), // Slightly smaller
      -pi / 2, 
      sweepAngle, 
      true, 
      fillPaint
    );
  }

  @override
  bool shouldRepaint(covariant _PieTimerPainter oldDelegate) {
    return oldDelegate.elapsed != elapsed || oldDelegate.targetMinutes != targetMinutes;
  }
}
