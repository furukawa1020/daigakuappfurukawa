import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

class RubyEngineService {
  static final RubyEngineService _instance = RubyEngineService._internal();
  factory RubyEngineService() => _instance;
  RubyEngineService._internal();

  Process? _process;
  final StreamController<Map<String, dynamic>> _responseController = StreamController.broadcast();
  bool _isReady = false;

  Future<void> init() async {
    if (_isReady) return;

    try {
      // Launch MokoEngine (Assume Ruby is in PATH)
      // Path is relative to the workspace ROOT for the desktop runner
      // Adjust path for production as needed (bundled sidecar)
      _process = await Process.start('ruby', ['ruby_native/moko_engine.rb']);
      
      _process!.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        debugPrint('Ruby Engine Output: $line');
        final data = jsonDecode(line);
        if (data['status'] == 'ready') {
          _isReady = true;
        } else {
          _responseController.add(data);
        }
      });

      _process!.stderr.transform(utf8.decoder).listen((error) {
        debugPrint('Ruby Engine Error: $error');
      });

      // Wait for engine to be ready
      int timeout = 0;
      while (!_isReady && timeout < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        timeout++;
      }
    } catch (e) {
      debugPrint('Failed to start Ruby Engine: $e');
    }
  }

  Future<Map<String, dynamic>> sendCommand(Map<String, dynamic> command) async {
    if (!_isReady) await init();
    
    final completer = Completer<Map<String, dynamic>>();
    
    // Send command as JSON line
    _process!.stdin.writeln(jsonEncode(command));
    
    // Wait for the NEXT response matching this command (simple sequential for now)
    final subscription = _responseController.stream.listen((response) {
      if (!completer.isCompleted) {
        completer.complete(response);
      }
    });

    return completer.future.timeout(const Duration(seconds: 5)).whenComplete(() => subscription.cancel());
  }

  void dispose() {
    _process?.kill();
    _responseController.close();
  }
}
