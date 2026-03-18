import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import '../state/app_state.dart';
import 'moko_card.dart';

class PetDisplay extends ConsumerWidget {
  const PetDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petState = ref.watch(petProvider);
    
    return GestureDetector(
      onTap: () {
        ref.read(hapticsProvider.notifier).lightImpact();
        _showRandomMessage(context, petState.name);
      },
      child: MokoCard(
        child: Row(
          children: [
            Text(
              petState.emoji,
              style: const TextStyle(fontSize: 56),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 2.seconds, lowerBound: 0.9, upperBound: 1.1),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    petState.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "累計 ${(petState.totalMinutes / 60).toStringAsFixed(1)} 時間",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  if (petState.stage != PetStage.master) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: petState.progressToNextStage.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFB5EAD7)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "次の進化まで ${(petState.minutesUntilNextStage / 60).toStringAsFixed(1)}時間",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ] else ...[
                    const Text(
                      "⭐ MAX LEVEL ⭐",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRandomMessage(BuildContext context, String name) {
    final messages = [
      "今日もえらい！",
      "ずっと見てるよ。",
      "休憩も大事だよ？",
      "一緒にがんばろ！",
      "君ならできる！",
      "すごい集中力…！",
      "ふわふわ〜",
      "おやつほしいな…",
      "レベルアップしたい？",
      "その調子！",
    ];
    final msg = messages[Random().nextInt(messages.length)];
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$name: 「$msg」"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF7DBAA0),
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
