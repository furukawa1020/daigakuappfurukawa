import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../haptics_service.dart';

class HyperfocusButton extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  final Duration requiredDuration;

  const HyperfocusButton({
    super.key,
    required this.onComplete,
    this.requiredDuration = const Duration(seconds: 3), // Slightly longer for the "Ritual"
  });

  @override
  ConsumerState<HyperfocusButton> createState() => _HyperfocusButtonState();
}

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.requiredDuration);
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref.read(hapticsProvider.notifier).heavyImpact();
        widget.onComplete();
        _controller.reset();
      }
    });

    // "Gathering Energy" - Scale down from 1.0 to 0.85 as you hold
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _onTapDown(TapDownDetails details) {
    ref.read(hapticsProvider.notifier).lightImpact();
    _controller.forward();
    _startHeartbeatHaptics();
  }

  void _onTapUp(TapUpDetails details) {
    if (!_controller.isCompleted) {
      _controller.reverse();
      ref.read(hapticsProvider.notifier).lightImpact();
    }
  }

  void _onTapCancel() {
    if (!_controller.isCompleted) {
      _controller.reverse();
    }
  }

  // Heartbeat Logic: Speed increases as progress fills
  void _startHeartbeatHaptics() async {
    while (_controller.isAnimating && !_controller.isCompleted) {
      double progress = _controller.value;
      
      // Calculate delay based on progress (Slower -> Faster)
      // 0.0 -> 800ms
      // 1.0 -> 100ms
      int delayMs = (800 * (1 - progress) + 100).toInt();
      
      // Haptic strength
      if (progress < 0.3) {
        ref.read(hapticsProvider.notifier).lightImpact();
      } else if (progress < 0.7) {
        ref.read(hapticsProvider.notifier).mediumImpact();
      } else {
        ref.read(hapticsProvider.notifier).heavyImpact();
      }

      await Future.delayed(Duration(milliseconds: delayMs));
      
      // Check again to avoid haptic after release
      if (!_controller.isAnimating) break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Progress Ring (Glow gets stronger)
                Container(
                  width: 90, 
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orangeAccent.withOpacity(_controller.value * 0.6),
                        blurRadius: 10 + (_controller.value * 30),
                        spreadRadius: _controller.value * 10,
                      )
                    ]
                  ),
                  child: CircularProgressIndicator(
                    value: _controller.value,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                  ),
                ),
                // Main Button
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(const Color(0xFFB5EAD7), Colors.orange, _controller.value)!,
                        Color.lerp(const Color(0xFFC7CEEA), Colors.deepOrange, _controller.value)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                       BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                       )
                    ],
                  ),
                  child: Icon(
                    _controller.value > 0.9 ? Icons.flash_on : Icons.power_settings_new,
                    color: Colors.white,
                    size: 32 + (_controller.value * 5), // Icon grows slightly inside
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
