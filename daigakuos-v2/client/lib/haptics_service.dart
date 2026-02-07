import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final hapticsProvider = StateNotifierProvider<HapticsService, bool>((ref) {
  return HapticsService();
});

class HapticsService extends StateNotifier<bool> {
  HapticsService() : super(true) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('haptics_enabled') ?? true;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptics_enabled', value);
    if (value) {
      lightImpact();
    }
  }

  void lightImpact() {
    if (state) HapticFeedback.lightImpact();
  }

  void mediumImpact() {
    if (state) HapticFeedback.mediumImpact();
  }

  void heavyImpact() {
    if (state) HapticFeedback.heavyImpact();
  }

  void vibrate() {
    if (state) HapticFeedback.vibrate();
  }
  
  void selectionClick() {
    if (state) HapticFeedback.selectionClick();
  }
}
