import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

enum MokoEmotion { normal, happy, pained, angry, exhausted }

class MokoReactionOverlay extends StatelessWidget {
  final MokoEmotion emotion;
  final String message;
  final bool visible;

  const MokoReactionOverlay({
    super.key,
    required this.emotion,
    required this.message,
    this.visible = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Positioned(
      bottom: 250,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Speech Bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(maxWidth: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Text(
              message,
              style: GoogleFonts.outfit(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().scale(begin: const Offset(0.5, 0.5)).fadeIn().shake(duration: 500.ms),
          
          const SizedBox(height: 8),
          
          // Moko Figure
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getEmotionColor(emotion),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Center(
              child: Text(
                _getEmotionEmoji(emotion),
                style: const TextStyle(fontSize: 40),
              ),
            ),
          )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -10, duration: 1000.ms, curve: Curves.easeInOut)
          .animate(target: emotion == MokoEmotion.pained ? 1 : 0)
          .shake(duration: 200.ms),
        ],
      ),
    );
  }

  Color _getEmotionColor(MokoEmotion e) {
    switch (e) {
      case MokoEmotion.happy: return Colors.amberAccent;
      case MokoEmotion.pained: return Colors.redAccent;
      case MokoEmotion.angry: return Colors.orangeAccent;
      case MokoEmotion.exhausted: return Colors.blueGrey;
      default: return Colors.lightBlueAccent;
    }
  }

  String _getEmotionEmoji(MokoEmotion e) {
    switch (e) {
      case MokoEmotion.happy: return "🤩";
      case MokoEmotion.pained: return "😖";
      case MokoEmotion.angry: return "😤";
      case MokoEmotion.exhausted: return "😫";
      default: return "🐾";
    }
  }
}
