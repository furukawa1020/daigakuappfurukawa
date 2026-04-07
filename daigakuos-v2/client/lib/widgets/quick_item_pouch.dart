import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

class QuickItemPouch extends ConsumerStatefulWidget {
  const QuickItemPouch({super.key});

  @override
  ConsumerState<QuickItemPouch> createState() => _QuickItemPouchState();
}

class _QuickItemPouchState extends ConsumerState<QuickItemPouch> {
  bool _isProcessing = false;

  Future<void> _useItem(String type) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    
    final deviceId = ref.read(deviceIdProvider);
    try {
      if (type == 'potion') {
        await ApiService().heal(deviceId);
      } else if (type == 'whetstone') {
        await ApiService().sharpen(deviceId);
      }
      ref.refresh(userProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) {
        final potionCount = user.inventory['potion'] ?? 0;
        final whetstoneCount = user.inventory['whetstone'] ?? 0;

        return Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildItemBox(
                label: "POTION",
                icon: Icons.science,
                color: Colors.greenAccent,
                count: potionCount,
                onTap: () => _useItem('potion'),
              ),
              const SizedBox(width: 12),
              _buildItemBox(
                label: "WHETSTONE",
                icon: Icons.hardware,
                color: Colors.amberAccent,
                count: whetstoneCount,
                onTap: () => _useItem('whetstone'),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 100),
      error: (e, st) => Container(),
    );
  }

  Widget _buildItemBox({
    required String label,
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) {
    final bool isEmpty = count <= 0;
    return GestureDetector(
      onTap: isEmpty || _isProcessing ? null : onTap,
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEmpty ? Colors.white10 : color.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Icon(icon, color: isEmpty ? Colors.white24 : color, size: 32),
                if (!isEmpty)
                   Positioned(
                     right: 0,
                     bottom: 0,
                     child: Container(
                       padding: const EdgeInsets.all(2),
                       decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                       child: Text(
                         count.toString(),
                         style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                       ),
                     ),
                   ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isEmpty ? Colors.white24 : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    ).animate(target: _isProcessing ? 1 : 0).shimmer(duration: 500.ms);
  }
}
