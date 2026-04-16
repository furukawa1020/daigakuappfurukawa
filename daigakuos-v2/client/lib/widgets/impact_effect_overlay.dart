import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class ImpactEffectOverlay extends StatefulWidget {
  final Widget child;
  final Stream<ImpactEvent>? events;

  const ImpactEffectOverlay({super.key, required this.child, this.events});

  @override
  State<ImpactEffectOverlay> createState() => _ImpactEffectOverlayState();
}

class ImpactEvent {
  final double shake;
  final int hitStop;
  final bool isCritical;
  final bool isBounce;

  ImpactEvent({required this.shake, required this.hitStop, this.isCritical = false, this.isBounce = false});
}

class _ImpactEffectOverlayState extends State<ImpactEffectOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  bool _showFlash = false;
  Color _flashColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: 200.ms);
    widget.events?.listen(_handleEvent);
  }

  void _handleEvent(ImpactEvent event) async {
    // 1. Hitstop (Freeze Frame)
    if (event.hitStop > 0) {
       // Note: In a real game engine we would pause all animations. 
       // In Flutter, we can simulate by holding the current state.
       await Future.delayed(Duration(milliseconds: event.hitStop));
    }

    // 2. Shake
    if (event.shake > 0) {
      _shakeController.forward(from: 0);
    }

    // 3. Flash
    if (event.isCritical || event.isBounce) {
      setState(() {
        _showFlash = true;
        _flashColor = event.isCritical ? Colors.white : Colors.redAccent;
      });
      await Future.delayed(50.ms);
      if (mounted) setState(() => _showFlash = false);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final double offset = math.sin(_shakeController.value * math.pi * 10) * 8 * (1.0 - _shakeController.value);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: Stack(
            children: [
              widget.child,
              if (_showFlash)
                Container(
                  color: _flashColor.withOpacity(0.3),
                )
                  .animate()
                  .fadeOut(duration: 150.ms),
              if (_showFlash && _flashColor == Colors.white)
                 Center(
                   child: const Icon(Icons.star, color: Colors.white, size: 100)
                     .animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(2.0, 2.0)).fadeOut(),
                 ),
            ],
          ),
        );
      },
    );
  }
}
