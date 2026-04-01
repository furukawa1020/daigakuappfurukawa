import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'api_service.dart';

class NativeCommandListener {
  static WebSocket? _socket;
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> init(String username) async {
    // Determine the base WebSocket URL based on ApiService
    String wsUrl = ApiService.baseUrl.replaceFirst('http://', 'ws://').replaceFirst('/api/v1', '/cable');
    
    try {
      _socket = await WebSocket.connect(wsUrl);
      print('Connected to ActionCable 🚀');

      // Subscribe to ActivityFeedChannel
      final identifier = jsonEncode({"channel": "ActivityFeedChannel"});
      _socket!.add(jsonEncode({
        "command": "subscribe",
        "identifier": identifier,
      }));

      // Listen for commands
      _socket!.listen((data) {
        final payload = jsonDecode(data);
        if (payload['type'] == 'ping') return;
        
        if (payload['message'] != null) {
          final message = payload['message'];
          if (message['type'] == 'native_command') {
            // Only execute if the command targets this user
            if (message['target_username'] == username) {
              _executeCommand(message['command'], message['payload']);
            }
          }
        }
      }, onDone: () {
        print('ActionCable connection closed. Reconnecting in 5s...');
        Future.delayed(const Duration(seconds: 5), () => init(username));
      }, onError: (err) {
        print('ActionCable Error: $err');
      });
    } catch (e) {
      print('Failed to connect to ActionCable: $e. Retrying...');
      Future.delayed(const Duration(seconds: 5), () => init(username));
    }
  }

  static void _executeCommand(String command, Map<String, dynamic> payload) {
    print('Execute Native Command from Ruby: $command -> $payload');
    
    switch (command) {
      case 'vibrate':
        _handleVibrate(payload['pattern']);
        break;
      case 'notify':
        _handleNotify(payload['title'], payload['body']);
        break;
      case 'play_sound':
        _handleSound(payload['sound_name']);
        break;
      default:
        print('Unknown command: $command');
    }
  }

  static void _handleVibrate(String? pattern) {
    if (pattern == 'heavy') {
      HapticFeedback.heavyImpact();
    } else if (pattern == 'medium') {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  static void _handleNotify(String? title, String? body) {
    // For now, we print. A real integration uses flutter_local_notifications.
    // In DaigakuAPP, NotificationService is available but requires context or global access.
    print('🔔 NATIVE NOTIFICATION TRIGGERED: $title - $body');
  }

  static void _handleSound(String? soundName) async {
    if (soundName != null) {
      try {
        await _audioPlayer.play(AssetSource('sounds/$soundName'));
      } catch (e) {
        print('Sound play error: $e');
      }
    }
  }
}
