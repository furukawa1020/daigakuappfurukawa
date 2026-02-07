import 'package:flutter/material.dart';

class MokoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;

  const MokoCard({super.key, required this.child, this.padding, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC7CEEA).withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: child,
      ),
    );
  }
}
