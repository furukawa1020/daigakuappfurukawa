import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;
  const PremiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base
        Container(color: const Color(0xFFFFF0F5)), // Lavender Blush
        
        // Blobs
        Positioned(
          top: -100, left: -50,
          child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              color: const Color(0xFFC7CEEA).withOpacity(0.4), // Periwinkle
              shape: BoxShape.circle
            ),
          ).animate().scale(duration: 5.seconds, curve: Curves.easeInOut).then().scale(begin: const Offset(1.0, 1.0), end: const Offset(0.9, 0.9)),
        ),
        Positioned(
          bottom: -50, right: -50,
          child: Container(
            width: 400, height: 400,
            decoration: BoxDecoration(
              color: const Color(0xFFFFDAC1).withOpacity(0.4), // Peach
              shape: BoxShape.circle
            ),
          ),
        ),
        
        // Content
        SafeArea(child: child),
      ],
    );
  }
}
