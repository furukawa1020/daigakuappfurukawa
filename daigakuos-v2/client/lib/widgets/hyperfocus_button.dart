import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../haptics_service.dart';

class HyperfocusButton extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  final Duration requiredDuration;

  const HyperfocusButton({
    super.key,
    required this.onComplete,
    this.requiredDuration = const Duration(seconds: 2), // 2秒チャージ
  });

  @override
  ConsumerState<HyperfocusButton> createState() => _HyperfocusButtonState();
}

class _HyperfocusButtonState extends ConsumerState<HyperfocusButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.requiredDuration);
    
    _controller.addListener(() {
      // プログレスに応じて振動を変える
      if (_controller.value > 0.1 && _controller.value < 0.2) {
         // Start charging
      }
      
      // 単純な閾値で振動を入れる (例: 30%, 60%, 90%)
      // 実際にはフレームごとに呼ばれるので、ここで連続振動は重いかもしれない
      // ステップごとに振動させるロジックは微調整が必要
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref.read(hapticsProvider.notifier).heavyImpact(); // 完了時の衝撃
        widget.onComplete();
        _controller.reset();
      }
    });

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _onTapDown(TapDownDetails details) {
    ref.read(hapticsProvider.notifier).lightImpact();
    _controller.forward();
    _startHapticBuildup();
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

  // 徐々に強くなる振動ループ
  void _startHapticBuildup() async {
    // int step = 0; // Unused
    while (_controller.isAnimating && !_controller.isCompleted) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!_controller.isAnimating) break;
      
      if (_controller.value < 0.5) {
        ref.read(hapticsProvider.notifier).lightImpact();
      } else if (_controller.value < 0.9) {
        ref.read(hapticsProvider.notifier).mediumImpact();
      } else {
        ref.read(hapticsProvider.notifier).heavyImpact();
      }
      // step++;
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
                // Background Progress Ring
                SizedBox(
                  width: 80, 
                  height: 80,
                  child: CircularProgressIndicator(
                    value: _controller.value,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
                        Color.lerp(const Color(0xFFB5EAD7), const Color(0xFFFFB7B2), _controller.value)!,
                        Color.lerp(const Color(0xFFC7CEEA), const Color(0xFFFFDAC1), _controller.value)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC7CEEA).withOpacity(0.4 + (_controller.value * 0.4)),
                        blurRadius: 20 + (_controller.value * 20),
                        spreadRadius: _controller.value * 10,
                      )
                    ],
                  ),
                  child: Icon(
                    _controller.value > 0.9 ? Icons.rocket_launch : Icons.fingerprint,
                    color: Colors.white,
                    size: 32,
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
