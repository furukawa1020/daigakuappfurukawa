import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import '../state/app_state.dart';
import '../services/pet_service.dart';
import 'moko_card.dart';

class PetDisplay extends ConsumerWidget {
  const PetDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<PetState>(petProvider, (previous, next) {
      if (previous != null && next.stage.index > previous.stage.index) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _EvolutionDialog(oldPet: previous, newPet: next),
        );
      }
    });

    final petState = ref.watch(petProvider);
    
    return GestureDetector(
      onTap: () {
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

  void _showRandomMessage(BuildContext context, PetState pet, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final stats = ref.read(userStatsProvider).value;
    final streak = stats?.currentStreak ?? 0;

    List<String> messages = [];

    if (hour >= 5 && hour < 10) {
      messages.addAll(["おはよう！朝活えらいね！", "今日も一日がんばろ！", "朝の空気がおいしいね！"]);
    } else if (hour >= 22 || hour < 4) {
      messages.addAll(["もう遅いよ？休むのも大事！", "夜更かししすぎないでね…", "あくび出ちゃう…"]);
    } else {
      messages.addAll(["一緒にがんばろ！", "君ならできる！", "すごい集中力…！", "その調子！"]);
    }

    if (streak >= 3) {
      messages.addAll(["$streak日連続！天才！", "🔥継続の鬼！🔥"]);
    }

    if (pet.stage == PetStage.egg) {
      messages.addAll(["もっと成長したいな…", "孵化するのが楽しみ！"]);
    } else if (pet.stage == PetStage.master) {
      messages.addAll(["もうこれ以上進化できないみたい！", "君と一緒に成長できたよ！"]);
    }

    final msg = messages[Random().nextInt(messages.length)];
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${pet.name}: 「$msg」"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF7DBAA0),
        duration: const Duration(milliseconds: 2000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _EvolutionDialog extends StatefulWidget {
  final PetState oldPet;
  final PetState newPet;
  const _EvolutionDialog({required this.oldPet, required this.newPet});

  @override
  State<_EvolutionDialog> createState() => _EvolutionDialogState();
}

class _EvolutionDialogState extends State<_EvolutionDialog> {
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _revealed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_revealed) ...[
              const Text("あ… モコの様子が…！", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                  .animate().fadeIn().shimmer(duration: 1.seconds, color: Colors.white),
              const SizedBox(height: 32),
              Text(widget.oldPet.emoji, style: const TextStyle(fontSize: 100))
                  .animate(onPlay: (c) => c.repeat())
                  .shake(hz: 8, curve: Curves.easeInOutCubic, duration: 2.seconds)
                  .scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 2.seconds),
            ] else ...[
              const Text("おめでとう！", style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold))
                  .animate().scale(curve: Curves.elasticOut),
              const SizedBox(height: 8),
              Text("${widget.oldPet.name} は\n${widget.newPet.name} に進化した！",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16))
                  .animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 32),
              Text(widget.newPet.emoji, style: const TextStyle(fontSize: 120))
                  .animate()
                  .scale(curve: Curves.elasticOut, duration: 1.seconds)
                  .shimmer(duration: 2.seconds, color: Colors.amber),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                child: const Text("すごい！", style: TextStyle(fontWeight: FontWeight.bold)),
              ).animate().fadeIn(delay: 1.seconds),
            ]
          ],
        ),
      ),
    );
  }
}
