import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rest Day Provider
/// Tracks whether today is marked as an intentional rest day
final restDayProvider = StateNotifierProvider<RestDayNotifier, bool>((ref) {
  return RestDayNotifier();
});

class RestDayNotifier extends StateNotifier<bool> {
  RestDayNotifier() : super(false) {
    _loadRestStatus();
  }

  Future<void> _loadRestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final restDay = prefs.getString('rest_day');
    state = (restDay == todayStr);
  }

  Future<void> setRestDay(bool isRest) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    
    if (isRest) {
      await prefs.setString('rest_day', todayStr);
    } else {
      await prefs.remove('rest_day');
    }
    
    state = isRest;
  }
}

/// Rest Day Toggle Widget
/// Allows users to mark today as intentional rest without guilt
class RestDayToggle extends ConsumerWidget {
  const RestDayToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRestDay = ref.watch(restDayProvider);

    return GestureDetector(
      onTap: () {
        ref.read(restDayProvider.notifier).setRestDay(!isRestDay);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRestDay 
                ? "がんばろう！" 
                : "今日はゆっくり休んでね🌙"
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: isRestDay 
            ? const Color(0xFFC7CEEA).withOpacity(0.3)
            : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRestDay 
              ? const Color(0xFFC7CEEA)
              : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRestDay ? Icons.bedtime : Icons.bedtime_outlined,
              color: isRestDay 
                ? const Color(0xFFC7CEEA)
                : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isRestDay ? "今日は休息日🌙" : "今日は休む",
              style: TextStyle(
                color: isRestDay 
                  ? const Color(0xFFC7CEEA)
                  : Colors.grey.shade700,
                fontWeight: isRestDay ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
