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
      } else {
        await ApiService().useItem(deviceId, type);
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
        final items = [
          {'id': 'potion', 'label': 'POTION', 'icon': Icons.science, 'color': Colors.greenAccent},
          {'id': 'whetstone', 'label': 'WHETSTONE', 'icon': Icons.hardware, 'color': Colors.amberAccent},
          {'id': 'antidote', 'label': 'ANTIDOTE', 'icon': Icons.health_and_safety, 'color': Colors.deepPurpleAccent},
          {'id': 'energy_drink', 'label': 'ENERGY', 'icon': Icons.bolt, 'color': Colors.yellowAccent},
        ];

        return Container(
          height: 90,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (c, i) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final count = user.inventory[item['id']] ?? 0;
              return _buildItemBox(
                label: item['label'] as String,
                icon: item['icon'] as IconData,
                color: item['color'] as Color,
                count: count,
                onTap: () => _useItem(item['id'] as String),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 90),
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
            color: isEmpty ? Colors.white10 : color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: isEmpty ? Colors.white24 : color, size: 28),
                if (!isEmpty)
                   Positioned(
                     right: -8,
                     top: -4,
                     child: Container(
                       padding: const EdgeInsets.all(4),
                       decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                       child: Text(
                         count.toString(),
                         style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                       ),
                     ),
                   ),
              ],
            ),
            const SizedBox(height: 4),
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
