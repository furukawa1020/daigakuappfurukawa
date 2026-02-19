import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';

class TaskRouletteDialog extends ConsumerStatefulWidget {
  const TaskRouletteDialog({super.key});

  @override
  ConsumerState<TaskRouletteDialog> createState() => _TaskRouletteDialogState();
}

class _TaskRouletteDialogState extends ConsumerState<TaskRouletteDialog> {
  Timer? _timer;
  String _currentTask = "???";
  bool _isSpinning = true;
  final Random _random = Random();
  
  // Default candidates if history is empty or sparse
  final List<String> _defaults = [
    "深呼吸する (Deep Breath)",
    "机を拭く (Clean Desk)",
    "水を1杯飲む (Drink Water)",
    "メール1件確認 (Check 1 Email)",
    "ストレッチ (Stretch)",
    "好きな曲を1曲聞く",
    "ゴミを1つ捨てる",
    "目薬をさす",
  ];

  List<String> _candidates = [];

  @override
  void initState() {
    super.initState();
    _initializeCandidates();
    _startSpinning();
  }

  void _initializeCandidates() {
    final history = ref.read(historyProvider).asData?.value ?? [];
    // Extract unique titles from history
    final historyTitles = history
        .map((s) => s['title'] as String?)
        .where((t) => t != null && t.isNotEmpty)
        .toSet() // Unique
        .toList();
    
    // Combine with defaults
    _candidates = [...historyTitles.whereType<String>(), ..._defaults];
    // Shuffle ensuring variety
    _candidates.shuffle();
  }

  void _startSpinning() {
    int ticks = 0;
    // Speed up first, then slow down? Or just rapid constant speed?
    // Let's do rapid constant for 1.5s then slow down.
    
    // Phase 1: Rapid (1.5s)
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      
      setState(() {
        _currentTask = _candidates[_random.nextInt(_candidates.length)];
      });
      ref.read(hapticsProvider.notifier).selectionClick();

      ticks++;
      if (ticks > 30) { // 30 * 50ms = 1.5s
        timer.cancel();
        _slowDownSpinning();
      }
    });
  }

  void _slowDownSpinning() {
    // Phase 2: Slow down (5 steps with increasing delay)
    // We'll use a recursive function with increasing delay
    _spinStep(100, 5);
  }

  void _spinStep(int delayMs, int stepsLeft) {
    if (!mounted) return;
    
    setState(() {
      _currentTask = _candidates[_random.nextInt(_candidates.length)];
    });
    ref.read(hapticsProvider.notifier).selectionClick();

    if (stepsLeft > 0) {
      Timer(Duration(milliseconds: delayMs), () {
        _spinStep(delayMs + 100, stepsLeft - 1); // Increase delay by 100ms
      });
    } else {
      // Final stop
      ref.read(hapticsProvider.notifier).mediumImpact();
      setState(() {
        _isSpinning = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.casino, color: Colors.orange),
          SizedBox(width: 8),
          Text("運命のタスク..."),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isSpinning ? Colors.grey[100] : const Color(0xFFFFF0F5), // Lavender blush on stop
              borderRadius: BorderRadius.circular(16),
              border: _isSpinning ? null : Border.all(color: const Color(0xFFFFB7B2), width: 3),
            ),
            child: Text(
              _currentTask,
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: _isSpinning ? Colors.grey : Colors.black87
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          if (!_isSpinning)
            const Text("これで5分だけ、どうですか？", style: TextStyle(color: Colors.grey)),
        ],
      ),
      actions: [
        if (_isSpinning)
          const Center(child: Text("回転中...", style: TextStyle(color: Colors.grey)))
        else ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("やめとく", style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () {
               ref.read(hapticsProvider.notifier).heavyImpact();
               ref.read(selectedTaskProvider.notifier).state = _currentTask;
               // Start "Just 5 Minutes" Mode by default for lower barrier
               ref.read(sessionProvider.notifier).state = Session(
                 startAt: DateTime.now(),
                 targetMinutes: 5,
               );
               Navigator.pop(context);
               context.push('/now');
            },
            child: const Text("5分だけやる！"),
          ),
        ]
      ],
    );
  }
}
