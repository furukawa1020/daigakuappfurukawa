import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/app_state.dart';
import 'api_service.dart';

final actionCableProvider = Provider((ref) => ActionCableService(ref));

class ActionCableService {
  final Ref _ref;
  WebSocket? _socket;
  bool _isConnected = false;
  
  ActionCableService(this._ref);

  Future<void> connect() async {
    if (_isConnected) return;

    final baseUrl = ApiService.baseUrl;
    final wsUrl = baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://') + '/cable';
    
    try {
      _socket = await WebSocket.connect(wsUrl);
      _isConnected = true;
      print('Connected to ActionCable World 🌍');

      // 1. Subscribe to ChatChannel
      _subscribe('ChatChannel');
      // 2. Subscribe to RaidChannel
      _subscribe('RaidChannel');

      _socket!.listen((data) {
        _handleIncomingData(data);
      }, onDone: () {
        _isConnected = false;
        print('Connection closed. Reconnecting...');
        Future.delayed(const Duration(seconds: 5), () => connect());
      }, onError: (e) {
        _isConnected = false;
        print('ActionCable Error: $e');
      });

    } catch (e) {
      print('WebSocket Connection Error: $e');
      Future.delayed(const Duration(seconds: 5), () => connect());
    }
  }

  void _subscribe(String channel) {
    if (_socket == null) return;
    _socket!.add(jsonEncode({
      "command": "subscribe",
      "identifier": jsonEncode({"channel": channel}),
    }));
  }

  void sendMessage(String content, String username) {
    if (_socket == null) return;
    _socket!.add(jsonEncode({
      "command": "message",
      "identifier": jsonEncode({"channel": "ChatChannel"}),
      "data": jsonEncode({
        "action": "speak",
        "content" : content,
        "username": username
      })
    }));
  }

  void _handleIncomingData(String data) {
    final Map<String, dynamic> payload = jsonDecode(data);
    if (payload['type'] == 'ping') return;
    if (payload['message'] == null) return;

    final msg = payload['message'];
    final identifier = jsonDecode(payload['identifier']);
    final channel = identifier['channel'];

    if (channel == 'ChatChannel') {
      final chatMsg = ChatMessage.fromJson(msg);
      _ref.read(chatProvider.notifier).update((state) => [...state, chatMsg].take(50).toList());
    } else if (channel == 'RaidChannel') {
      // Handle real-time raid updates (Damage logs, boss spawn, etc.)
      // We can use another provider for this if needed, or just refresh the raid stats
      _ref.refresh(globalRaidProvider);
    }
  }
}
