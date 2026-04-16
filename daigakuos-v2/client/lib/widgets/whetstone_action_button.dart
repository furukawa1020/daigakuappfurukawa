import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

class WhetstoneActionButton extends ConsumerStatefulWidget {
  const WhetstoneActionButton({super.key});

  @override
  ConsumerState<WhetstoneActionButton> createState() => _WhetstoneActionButtonState();
}

class _WhetstoneActionButtonState extends ConsumerState<WhetstoneActionButton> {
  bool _isSharpening = false;

  Future<void> _sharpen() async {
    final deviceId = ref.read(deviceIdProvider);
    setState(() => _isSharpening = true);
    
    // Simulate sharpening time
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      final result = await ApiService().sharpen(deviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.amberAccent.withOpacity(0.8),
          ),
        );
      }
      ref.refresh(userProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharpening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: _isSharpening ? null : _sharpen,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isSharpening ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _isSharpening ? Colors.amberAccent : Colors.white10),
            boxShadow: _isSharpening ? [
              BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
            ] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSharpening)
                const Icon(Icons.auto_fix_high, color: Colors.amberAccent, size: 20)
                  .animate(onPlay: (c) => c.repeat()).rotate(duration: 500.ms).scale()
              else
                const Icon(Icons.hardware, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Text(
                _isSharpening ? "SHARPENING..." : "USE WHETSTONE (砥石)",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _isSharpening ? Colors.amberAccent : Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
