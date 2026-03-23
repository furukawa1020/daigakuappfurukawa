import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/api_service.dart';
import 'widgets/premium_background.dart';

final mokoDictionaryProvider = FutureProvider<List<dynamic>>((ref) async {
  return await ApiService.fetchMokoDictionary();
});

class MokoDictionaryScreen extends ConsumerWidget {
  const MokoDictionaryScreen({super.key});

  String getEmojiForName(String name) {
    if (name.contains('Angel') || name.contains('エンジェル')) return '👼';
    if (name.contains('Devil') || name.contains('デビル')) return '👿';
    if (name.contains('Ninja') || name.contains('忍者')) return '🥷';
    if (name.contains('Sakura') || name.contains('サクラ')) return '🌸';
    if (name.contains('Golden') || name.contains('黄金')) return '✨';
    if (name.contains('Egg') || name.contains('タマゴ')) return '🥚';
    if (name.contains('Baby') || name.contains('ベビー')) return '🐣';
    if (name.contains('Adult') || name.contains('アダルト')) return '🦅';
    if (name.contains('Elder') || name.contains('エルダー')) return '🦉';
    return '🐾';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dictAsync = ref.watch(mokoDictionaryProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('サーバー連携 Moko辞典', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(mokoDictionaryProvider),
          )
        ],
      ),
      body: PremiumBackground(
        child: dictAsync.when(
          data: (mokos) {
            if (mokos.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    "サーバーからモコデータを取得できませんでした。\n\nRailsサーバーが起動しているか確認してください。\n(rails s)", 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16)
                  ),
                )
              );
            }
            return GridView.builder(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60, left: 16, right: 16, bottom: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: mokos.length,
              itemBuilder: (context, index) {
                final m = mokos[index];
                final name = m['name'] ?? 'Unknown';
                final emoji = getEmojiForName(name);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                    ]
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 50)),
                      const SizedBox(height: 12),
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: Text(
                          'Phase ${m['phase']} / Lv ${m['required_level']}', 
                          style: TextStyle(color: Colors.purple.shade400, fontSize: 10, fontWeight: FontWeight.bold)
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          m['description'] ?? '', 
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 10, height: 1.3), 
                          textAlign: TextAlign.center, 
                          maxLines: 3, 
                          overflow: TextOverflow.ellipsis
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (err, stack) => Center(child: Text('エラーが発生しました: $err', style: const TextStyle(color: Colors.red))),
        ),
      ),
    );
  }
}
