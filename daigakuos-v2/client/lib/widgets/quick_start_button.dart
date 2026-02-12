import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../haptics_service.dart';
import '../main.dart';

/// Quick Start Button: 1-Minute Micro-Session
/// Low-pressure entry point for quick focus sessions
class QuickStartButton extends ConsumerWidget {
  const QuickStartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        ref.read(hapticsProvider.notifier).mediumImpact();
        
        // Check location bonus
        final bonus = await checkLocationBonus();
        ref.read(locationBonusProvider.notifier).state = bonus;
        
        // Start session
        ref.read(sessionProvider.notifier).state = Session(startAt: DateTime.now());
        
        // Auto-finish after 1 minute
        Future.delayed(const Duration(minutes: 1), () {
          if (context.mounted) {
            final s = ref.read(sessionProvider);
            if (s != null) {
              ref.read(sessionProvider.notifier).state = Session(
                id: s.id, 
                startAt: s.startAt, 
                durationMinutes: 1
              );
              context.pushReplacement('/finish');
            }
          }
        });
        
        context.push('/now');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB7B2), Color(0xFFFFDAC1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB7B2).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text(
              "1分だけやる",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms, curve: Curves.elasticOut);
  }
}
