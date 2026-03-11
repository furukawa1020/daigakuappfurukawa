import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticsService extends Notifier<void> {
  @override
  void build() {}

  void lightImpact() {
    HapticFeedback.lightImpact();
  }

  void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  void success() {
    HapticFeedback.vibrate();
  }
}

final hapticsProvider = NotifierProvider<HapticsService, void>(HapticsService.new);
