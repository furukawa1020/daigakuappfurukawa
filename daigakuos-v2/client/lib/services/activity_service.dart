import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activityProvider = StateNotifierProvider<ActivityNotifier, bool>((ref) {
  return ActivityNotifier();
});

class ActivityNotifier extends StateNotifier<bool> {
  Timer? _idleTimer;
  static const Duration _idleThreshold = Duration(seconds: 10);

  ActivityNotifier() : super(true) {
    resetTimer();
  }

  void resetTimer() {
    state = true; // User is active
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleThreshold, () {
      state = false; // User is idle
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }
}
