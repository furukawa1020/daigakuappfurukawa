import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'state/app_state.dart';
import 'database_helper.dart';
import 'widgets/moko_card.dart';
import 'widgets/premium_background.dart';

class TreeScreen extends ConsumerStatefulWidget {
  const TreeScreen({super.key});

  @override
  ConsumerState<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends ConsumerState<TreeScreen> {
  @override
  Widget build(BuildContext context) {
    final nodesAsync = ref.watch(nodesProvider);

    return Scaffold(
      body: PremiumBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text("目標の樹", style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
            ),
            
            Expanded(
              child: nodesAsync.when(
                data: (nodes) {
                  if (nodes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.park_outlined, size: 80, color: Colors.green.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          const Text("まだ計画はありません", style: TextStyle(color: Colors.grey)),
                          const Text("新しいタスクを追加してみましょう！", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    );
                  }

                  // Group by Type
                  final groups = <String, List<DaigakuNode>>{};
                  for (var node in nodes) {
                    groups.putIfAbsent(node.type, () => []).add(node);
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: groups.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
                            child: Text(
                              _getTypeLabel(entry.key),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                            ),
                          ),
                          ...entry.value.map((node) => _TaskTile(node: node)).toList(),
                        ],
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("エラー: $e")),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNodeDialog(context),
        backgroundColor: const Color(0xFFB5EAD7), // Mint
        icon: const Icon(Icons.add),
        label: const Text("新しい目標"),
      ).animate().scale(delay: 400.ms, curve: Curves.elasticOut),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'STUDY': return '📚 学ぶ';
      case 'RESEARCH': return '🔍 調べる / 考える';
      case 'MAKE': return '🛠️ 作る';
      case 'ADMIN': return '📝 事務 / 整理';
      default: return '📍 その他';
    }
  }

  void _showAddNodeDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final estimateCtrl = TextEditingController(text: "25");
    String selectedType = 'STUDY';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("新しい目標を追加"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: "なにをしますか？",
                    hintText: "例: レポートの構成案作成",
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: estimateCtrl,
                  decoration: const InputDecoration(
                    labelText: "見積もり時間 (分)",
                    suffixText: "分",
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: "カテゴリー"),
                  items: const [
                    DropdownMenuItem(value: 'STUDY', child: Text('📚 学ぶ')),
                    DropdownMenuItem(value: 'RESEARCH', child: Text('🔍 調べる / 考える')),
                    DropdownMenuItem(value: 'MAKE', child: Text('🛠️ 作る')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('📝 事務 / 整理')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("キャンセル"),
            ),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                final mins = int.tryParse(estimateCtrl.text) ?? 25;
                
                await DatabaseHelper().insertNode(
                  title: titleCtrl.text,
                  estimateMinutes: mins,
                  type: selectedType,
                );
                
                ref.refresh(nodesProvider);
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text("追加"),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  final DaigakuNode node;
  const _TaskTile({required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          ref.read(hapticsProvider.notifier).lightImpact();
          _startTask(context, ref);
        },
        onLongPress: () => _showOptions(context, ref),
        child: MokoCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(node.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(_getTypeIcon(node.type), color: _getTypeColor(node.type)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      "${node.estimateMinutes} 分の見積もり",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_outline, color: Colors.grey),
            ],
          ),
        ),
      ).animate().fadeIn().slideX(begin: 0.1, end: 0),
    );
  }

  void _startTask(BuildContext context, WidgetRef ref) {
    // Select this node for the timer
    ref.read(selectedNodeProvider.notifier).state = node;
    ref.read(selectedTaskProvider.notifier).state = node.title;
    
    // Auto-fill session target minutes if needed
    ref.read(sessionProvider.notifier).state = Session(
      startAt: DateTime.now(),
      nodeId: node.id,
      targetMinutes: node.estimateMinutes,
    );
    
    context.push('/now');
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("削除"),
              onTap: () async {
                await DatabaseHelper().deleteNode(node.id);
                ref.refresh(nodesProvider);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'STUDY': return Icons.book;
      case 'RESEARCH': return Icons.search;
      case 'MAKE': return Icons.build;
      case 'ADMIN': return Icons.assignment;
      default: return Icons.push_pin;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'STUDY': return const Color(0xFFFFB7B2); // Pink
      case 'RESEARCH': return const Color(0xFFC7CEEA); // Blue
      case 'MAKE': return const Color(0xFFE2F0CB); // Green
      case 'ADMIN': return const Color(0xFFFFDAC1); // Orange
      default: return Colors.grey;
    }
  }
}
