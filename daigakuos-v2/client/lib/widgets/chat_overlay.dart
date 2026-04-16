import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../services/action_cable_service.dart';

class ChatOverlay extends ConsumerStatefulWidget {
  const ChatOverlay({super.key});

  @override
  ConsumerState<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends ConsumerState<ChatOverlay> {
  final TextEditingController _msgCtrl = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  void _send() {
    if (_msgCtrl.text.isEmpty) return;
    final user = ref.read(userProvider).asData?.value;
    final username = user?.username ?? "MokoUser";
    
    ref.read(actionCableProvider).sendMessage(_msgCtrl.text, username);
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.forum, size: 16, color: Colors.cyanAccent),
              const SizedBox(width: 8),
              Text(
                "WORLD CHAT",
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.cyanAccent,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(_isExpanded ? Icons.expand_more : Icons.expand_less, size: 18, color: Colors.white70),
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
              ),
            ],
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final msg = messages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                        children: [
                          TextSpan(
                            text: "[${msg.timestamp}] ",
                            style: const TextStyle(color: Colors.white30, fontSize: 10),
                          ),
                          TextSpan(
                            text: "${msg.username}: ",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                          ),
                          TextSpan(text: msg.content),
                        ],
                      ),
                    ),
                  ).animate().fadeIn().slideX(begin: 0.1, end: 0);
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "メッセージを入力...",
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.cyanAccent, size: 20),
                  onPressed: _send,
                ),
              ],
            ),
          ] else if (messages.isNotEmpty) ...[
             const SizedBox(height: 4),
             Text(
               "${messages.last.username}: ${messages.last.content}",
               style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
               maxLines: 1,
               overflow: TextOverflow.ellipsis,
             ).animate().fadeIn(),
          ],
        ],
      ),
    );
  }
}
