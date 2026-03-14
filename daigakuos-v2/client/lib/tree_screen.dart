import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/app_state.dart';
import 'database_helper.dart';

class TreeScreen extends ConsumerStatefulWidget {
  const TreeScreen({super.key});

  @override
  ConsumerState<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends ConsumerState<TreeScreen> {
  @override
  Widget build(BuildContext context) {
    final nodesAsyncValue = ref.watch(nodesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('目標 / タスク管理'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: nodesAsyncValue.when(
        data: (nodes) {
          if (nodes.isEmpty) {
            return const Center(
              child: Text(
                '現在計画されている目標はありません。\n「+」ボタンからタスクを追加してください。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          // Group by Type
          final Map<String, List<DaigakuNode>> groupedNodes = {
            'STUDY': [],
            'RESEARCH': [],
            'MAKE': [],
            'ADMIN': [],
          };

          for (var node in nodes) {
            if (groupedNodes.containsKey(node.type)) {
              groupedNodes[node.type]!.add(node);
            } else {
               groupedNodes['STUDY']!.add(node); // Default fallback
            }
          }

          return ListView(
             padding: const EdgeInsets.all(16.0),
             children: [
                _buildSection('学習 (Study)', groupedNodes['STUDY']!),
                _buildSection('研究 (Research)', groupedNodes['RESEARCH']!),
                _buildSection('制作 (Make)', groupedNodes['MAKE']!),
                _buildSection('事務/運営 (Admin)', groupedNodes['ADMIN']!),
                const SizedBox(height: 80), // Padding for FAB
             ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNodeDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSection(String title, List<DaigakuNode> nodes) {
      if (nodes.isEmpty) return const SizedBox.shrink();

      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Padding(
                 padding: const EdgeInsets.symmetric(vertical: 8.0),
                 child: Text(
                     title,
                     style: const TextStyle(
                         fontSize: 18,
                         fontWeight: FontWeight.bold,
                         color: Colors.white,
                     ),
                 ),
             ),
             ...nodes.map((node) => _buildNodeItem(node)),
             const SizedBox(height: 16),
          ],
      );
  }

  Widget _buildNodeItem(DaigakuNode node) {
      return Card(
          color: Colors.white.withValues(alpha: 0.1),
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
              title: Text(node.title, style: const TextStyle(color: Colors.white)),
              subtitle: Text('${node.estimateMinutes} 分', style: const TextStyle(color: Colors.white54)),
              trailing: const Icon(Icons.play_arrow, color: Colors.white70),
              onTap: () {
                  // Set active task and return to NowScreen
                  ref.read(selectedTaskProvider.notifier).state = node;
                  Navigator.pop(context); // Go back to Home/Now
              },
          ),
      );
  }

  void _showAddNodeDialog() {
      String title = '';
      String minutesStr = '25';
      String selectedType = 'STUDY';

      showDialog(
          context: context,
          builder: (context) {
              return StatefulBuilder(
                  builder: (context, setState) {
                      return AlertDialog(
                          backgroundColor: Colors.grey[900],
                          title: const Text('新しいタスク', style: TextStyle(color: Colors.white)),
                          content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                  TextField(
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                          labelText: 'タイトル',
                                          labelStyle: TextStyle(color: Colors.white70),
                                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30))
                                      ),
                                      onChanged: (val) => title = val,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                      style: const TextStyle(color: Colors.white),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: '見積もり時間 (分)',
                                          labelStyle: TextStyle(color: Colors.white70),
                                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)) // Fixed typo
                                      ),
                                      controller: TextEditingController(text: minutesStr),
                                      onChanged: (val) => minutesStr = val,
                                  ),
                                  const SizedBox(height: 20),
                                  DropdownButtonFormField<String>(
                                      value: selectedType,
                                      dropdownColor: Colors.grey[800],
                                      style: const TextStyle(color: Colors.white),
                                      items: const [
                                          DropdownMenuItem(value: 'STUDY', child: Text('学習')),
                                          DropdownMenuItem(value: 'RESEARCH', child: Text('研究')),
                                          DropdownMenuItem(value: 'MAKE', child: Text('制作')),
                                          DropdownMenuItem(value: 'ADMIN', child: Text('事務')),
                                      ],
                                      onChanged: (val) {
                                          if (val != null) setState(() => selectedType = val);
                                      },
                                      decoration: const InputDecoration(
                                          labelText: 'カテゴリー',
                                          labelStyle: TextStyle(color: Colors.white70),
                                      ),
                                  ),
                              ],
                          ),
                          actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('キャンセル', style: TextStyle(color: Colors.white54)),
                              ),
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                                  onPressed: () async {
                                      if (title.isNotEmpty) {
                                          final mins = int.tryParse(minutesStr) ?? 25;
                                          await DatabaseHelper().insertNode(
                                              title: title, 
                                              estimateMinutes: mins, 
                                              type: selectedType
                                          );
                                          // ignore: use_build_context_synchronously
                                          Navigator.pop(context);
                                          ref.invalidate(nodesProvider); // Refresh list
                                      }
                                  },
                                  child: const Text('追加', style: TextStyle(color: Colors.white)),
                              )
                          ],
                      );
                  }
              );
          }
      );
  }
}
