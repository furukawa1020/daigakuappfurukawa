import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Daily Moko Message Widget
/// Shows encouraging messages on app launch
class DailyMokoMessage extends ConsumerStatefulWidget {
  const DailyMokoMessage({super.key});

  @override
  ConsumerState<DailyMokoMessage> createState() => _DailyMokoMessageState();
}

class _DailyMokoMessageState extends ConsumerState<DailyMokoMessage> {
  static const List<String> messages = [
    "今日も会えて嬉しい！✨",
    "無理しないでね🌸",
    "1分でも大丈夫だよ！",
    "あなたのペースで💫",
    "今日もがんばろうね！",
    "ちょっとだけでもOK🌈",
    "休憩も大事だよ🌙",
    "焦らなくていいよ💕",
    "小さな一歩が大切✨",
    "今日は何する？🎯",
    "気楽にいこう🌟",
    "できることからね！",
    "応援してるよ💪",
    "マイペースでGO🚀",
    "あなたは素敵✨",
    "今日もよろしくね！",
    "一緒にがんばろう💖",
    "完璧じゃなくていい🌺",
    "リラックスしてね🍀",
    "笑顔でいこう😊",
  ];

  late String _todayMessage;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    // Select message based on day of year
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    _todayMessage = messages[dayOfYear % messages.length];
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB5EAD7), Color(0xFFC7CEEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB5EAD7).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          const Text("🐻", style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _todayMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => setState(() => _dismissed = true),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }
}
