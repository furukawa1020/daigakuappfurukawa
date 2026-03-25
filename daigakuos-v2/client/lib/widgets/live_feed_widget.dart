import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LiveFeedWidget extends StatelessWidget {
  const LiveFeedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // This would normally connect to ActionCable using a package like 'action_cable'
    // For this demonstration, we'll show the concept of a living community.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors, size: 16, color: Colors.greenAccent),
              const SizedBox(width: 8),
              Text(
                'LIVE COMMUNITY FEED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.greenAccent.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _feedItem('MokoUser_8a2b', 'Level Up! reached Lv. 12', '🎉'),
          _feedItem('Researcher_Ken', 'Focused for 45 mins', '🧠'),
          _feedItem('Hatake_Dev', 'Discovered a Legendary Moko', '✨'),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _feedItem(String user, String event, String emoji) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                children: [
                  TextSpan(text: user, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  TextSpan(text: ' $event'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
