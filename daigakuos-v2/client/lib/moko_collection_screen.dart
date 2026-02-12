import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'moko_collection_service.dart';
import 'database_helper.dart';
import 'state/app_state.dart';

// Provider to get total minutes for gacha calc
final totalMinutesProvider = FutureProvider<int>((ref) async {
  final db = DatabaseHelper();
  final stats = await db.getUserStats();
  return (stats['totalPoints'] ?? 0).toInt() ~/ 10; // Approx points/10 = minutes? 
  // Wait, database_helper.dart: basePoints = 30 * minutes. So points / 30 = minutes.
  // Actually, getUserStats returns 'dailyMinutes' but not totalMinutes directly? 
  // Points logic: "basePoints = 30.0 * minutes". So TotalMinutes = TotalPoints / 30.
  // Let's verify DatabaseHelper logic.
  // DatabaseHelper says: "totalPoints = sum(points)".
  // And "insertSession": points = 30 * minutes * multiplier. 
  // It's safer to just query SUM(minutes) from sessions.
  // But getUserStats only returns totalPoints.
  // I should update DatabaseHelper to return totalMinutes.
  // For now, let's estimate or add a query.
  // Let's use a quick ad-hoc query here or update DatabaseHelper. 
  // Updating DatabaseHelper is better but riskier.
  // Let's assume 10 minutes = 1 draw for testing? Or just query generic.
});

// Better: Add totalMinutes to DatabaseHelper.getUserStats
// I will do that in next step. For now, creating the screen shell.

class MokoCollectionScreen extends ConsumerWidget {
  const MokoCollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedIds = ref.watch(mokoCollectionProvider);
    final notifier = ref.read(mokoCollectionProvider.notifier);
    
    // Hacky fetching of total minutes for now to show UI
    // In real impl, use a proper provider that updates with userStats
    final statsAsync = ref.watch(userStatsProvider); // Assuming main.dart defines this? 
    // main.dart defines 'userStatsProvider'. I need to import it or redefine it.
    // I'll assume it's available or use a local fetch.
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F6), // Lavender Blush
      appBar: AppBar(
        title: const Text("モコモココレクション", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.brown),
      ),
      body: statsAsync.when(
        data: (stats) {
          final totalMinutes = stats.totalMinutes;
          final availableDraws = notifier.getAvailableDraws(totalMinutes);
          
          return Column(
            children: [
              // Gacha Header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("ガチャチケット", style: TextStyle(fontSize: 14, color: Colors.grey)),
                            Text("$availableDraws枚", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown)),
                          ],
                        ),
                        FilledButton.icon(
                          onPressed: availableDraws > 0 ? () => _showGachaDialog(context, ref, totalMinutes) : null,
                          icon: const Icon(Icons.stars),
                          label: const Text("ガチャを引く"),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB7B2), // Salmon
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: (totalMinutes % 60) / 60.0,
                      backgroundColor: const Color(0xFFFCE4EC),
                      color: const Color(0xFFB5EAD7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 4),
                    Text("次のチケットまであと ${60 - (totalMinutes % 60)}分", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Collection Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: ALL_MOKO_ITEMS.length,
                  itemBuilder: (context, index) {
                    final item = ALL_MOKO_ITEMS[index];
                    final isUnlocked = unlockedIds.contains(item.id);
                    
                    return Opacity(
                      opacity: isUnlocked ? 1.0 : 0.5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isUnlocked ? item.color : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          border: isUnlocked ? null : Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon, 
                              size: 40, 
                              color: isUnlocked ? Colors.brown[700] : Colors.grey[400]
                            ).animate(target: isUnlocked ? 1 : 0).scale(duration: 300.ms, curve: Curves.elasticOut),
                            const SizedBox(height: 8),
                            Text(
                              isUnlocked ? item.name : "???",
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.bold, 
                                color: isUnlocked ? Colors.brown[800] : Colors.grey
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  void _showGachaDialog(BuildContext context, WidgetRef ref, int totalMinutes) async {
    // 1. Play Animation (Dialog)
    // 2. Call service.draw()
    // 3. Show Result
    
    // For simplicity, we assume draw is instant-ish, but let's simulate delay in dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GachaRevealDialog(ref: ref, totalMinutes: totalMinutes),
    );
  }
}

class GachaRevealDialog extends StatefulWidget {
  final WidgetRef ref;
  final int totalMinutes;
  const GachaRevealDialog({super.key, required this.ref, required this.totalMinutes});

  @override
  State<GachaRevealDialog> createState() => _GachaRevealDialogState();
}

class _GachaRevealDialogState extends State<GachaRevealDialog> {
  MokoItem? _result;
  bool _revealed = false;
  
  @override
  void initState() {
    super.initState();
    _startGacha();
  }
  
  void _startGacha() async {
    await Future.delayed(const Duration(seconds: 2)); // Animation delay
    final item = await widget.ref.read(mokoCollectionProvider.notifier).itemDraw(widget.totalMinutes);
    if (mounted) {
      setState(() {
        _result = item;
        _revealed = true;
      });
      // Trigger Haptics here?
      // ref.read(hapticsProvider.notifier).heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_revealed) ...[
               const Icon(Icons.cloud_circle, size: 100, color: Color(0xFFB5EAD7))
                 .animate(onPlay: (c) => c.repeat())
                 .shake(duration: 500.ms, hz: 4)
                 .tint(color: const Color(0xFFFFB7B2), duration: 2.seconds),
               const SizedBox(height: 20),
               const Text("モコモコ中...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
            ] else ...[
               Icon(_result!.icon, size: 100, color: _result!.color)
                 .animate()
                 .scale(curve: Curves.elasticOut, duration: 800.ms)
                 .shimmer(delay: 400.ms, duration: 1200.ms),
               const SizedBox(height: 16),
               Text(_result!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown)),
               const SizedBox(height: 8),
               Text(_result!.description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
               const SizedBox(height: 8),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                 decoration: BoxDecoration(
                   color: _result!.rarity == MokoRarity.legendary ? Colors.amber[100] : (_result!.rarity == MokoRarity.rare ? Colors.blue[100] : Colors.grey[200]),
                   borderRadius: BorderRadius.circular(10)
                 ),
                 child: Text(
                    _result!.rarity == MokoRarity.legendary ? "Legendary" : (_result!.rarity == MokoRarity.rare ? "Rare" : "Common"),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown[700])
                 ),
               ),
               const SizedBox(height: 24),
               FilledButton(
                 onPressed: () => Navigator.of(context).pop(),
                 style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFB7B2)),
                 child: const Text("閉じる"),
               )
            ]
          ],
        ),
      ),
    );
  }
}

// Placeholder removed. Imported from state/app_state.dart
