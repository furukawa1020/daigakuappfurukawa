import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

class QuestBoardScreen extends ConsumerStatefulWidget {
  const QuestBoardScreen({super.key});

  @override
  ConsumerState<QuestBoardScreen> createState() => _QuestBoardScreenState();
}

class _QuestBoardScreenState extends ConsumerState<QuestBoardScreen> {
  Map<String, dynamic>? _questData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    final deviceId = ref.read(deviceIdProvider);
    final data = await ApiService().fetchQuests(deviceId);
    if (mounted) setState(() { _questData = data; _loading = false; });
  }

  Future<void> _startQuest(int id) async {
    final deviceId = ref.read(deviceIdProvider);
    final success = await ApiService().startQuest(deviceId, id);
    if (success) {
      _loadQuests();
      ref.refresh(userProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("QUEST BOARD", style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadQuests,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_questData?['active_quest'] != null) ...[
                  _buildSectionHeader("ACTIVE HUNT"),
                  _buildQuestCard(HuntingQuest.fromJson(_questData!['active_quest']), isActive: true),
                  const SizedBox(height: 24),
                ],
                _buildSectionHeader("AVAILABLE QUESTS"),
                ...((_questData?['available_quests'] as List?) ?? [])
                    .map((q) => _buildQuestCard(HuntingQuest.fromJson(q))),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildQuestCard(HuntingQuest quest, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isActive ? Colors.cyanAccent : Colors.white10, width: isActive ? 2 : 1),
        boxShadow: isActive ? [BoxShadow(color: Colors.cyan.withOpacity(0.1), blurRadius: 10)] : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "⭐" * quest.difficulty,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quest.targetMonster.replaceAll('_', ' ').toUpperCase(),
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
                if (isActive)
                  const Icon(Icons.gps_fixed, color: Colors.cyanAccent)
                    .animate(onPlay: (c) => c.repeat()).scale(duration: 1.seconds)
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: quest.progress / quest.requiredMinutes,
              backgroundColor: Colors.white10,
              color: Colors.cyanAccent,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "PROGRESS: ${quest.progress} / ${quest.requiredMinutes} MIN",
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white54),
                ),
                if (!isActive)
                  ElevatedButton(
                    onPressed: () => _startQuest(quest.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("受注する", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}
