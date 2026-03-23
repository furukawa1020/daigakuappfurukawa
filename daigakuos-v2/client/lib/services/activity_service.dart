import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activityProvider = NotifierProvider<ActivityNotifier, bool>(ActivityNotifier.new);

class ActivityNotifier extends Notifier<bool> {
  Timer? _idleTimer;
  static const Duration _idleThreshold = Duration(seconds: 10);

  @override
  bool build() {
    ref.onDispose(() {
      _idleTimer?.cancel();
    });
    
    _idleTimer = Timer(_idleThreshold, () {
      state = false;
    });
    return true;
  }

  void resetTimer() {
    state = true; // User is active
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleThreshold, () {
      state = false; // User is idle
    });
  }
}
