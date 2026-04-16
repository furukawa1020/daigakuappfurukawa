import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';
import 'role_selection_dialog.dart';

class PartyWidget extends ConsumerWidget {
  const PartyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partyAsync = ref.watch(partyProvider);
    final user = ref.watch(userProvider).asData?.value;

    return partyAsync.when(
      data: (party) {
        if (party == null) {
          return _buildNoParty(context, ref);
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: Colors.cyan.withOpacity(0.1), blurRadius: 10)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "PARTY RAIDS",
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        party.name,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      if (user != null)
                        GestureDetector(
                          onTap: () => showDialog(context: context, builder: (ctx) => const RoleSelectionDialog()),
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getRoleColor(user.role).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _getRoleColor(user.role).withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getRoleIcon(user.role), size: 12, color: _getRoleColor(user.role)),
                                const SizedBox(width: 4),
                                Text(
                                  user.role.toUpperCase(),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getRoleColor(user.role)),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit, size: 10, color: Colors.white54),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Icon(Icons.groups, color: Colors.cyanAccent, size: 32)
                    .animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: party.members.map((m) => _buildMemberAvatar(m)).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.amberAccent, size: 20)
                      .animate(onPlay: (c) => c.repeat()).shake(hz: 3),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                         "パーティシナジー！ 同時集中でダメージ +${(party.members.length - 1) * 20}%",
                         style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'tank': return Colors.blueAccent;
      case 'healer': return Colors.purpleAccent;
      case 'dps': return Colors.redAccent;
      default: return Colors.white54;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'tank': return Icons.shield;
      case 'healer': return Icons.auto_fix_high;
      case 'dps': return Icons.swords;
      default: return Icons.person;
    }
  }

  Widget _buildMemberAvatar(PartyMember member) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
              color: Colors.white.withOpacity(0.1),
            ),
            child: Center(
               child: Text(
                 member.mokoMood == 'focus_god' ? '🔥' : '🐶',
                 style: const TextStyle(fontSize: 24),
               ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            member.username,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildNoParty(BuildContext context, WidgetRef ref) {
    return Container(
       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
         color: Colors.white.withOpacity(0.05),
         borderRadius: BorderRadius.circular(24),
         border: Border.all(color: Colors.white10),
       ),
       child: Column(
         children: [
            const Icon(Icons.group_add, color: Colors.white30, size: 40),
            const SizedBox(height: 12),
            const Text(
              "ソロでもいいけど、パーティならもっと強い！",
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showCreatePartyDialog(context, ref),
              icon: const Icon(Icons.create, size: 18),
              label: const Text("パーティ作成 / 参加"),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.cyanAccent.withOpacity(0.8),
                foregroundColor: Colors.black87,
              ),
            ),
         ],
       ),
    );
  }

  void _showCreatePartyDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("パーティ管理", style: GoogleFonts.outfit(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "パーティ名",
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "パスコード (任意)",
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () async {
              final deviceId = ref.read(deviceIdProvider);
              final success = await ApiService().joinParty(deviceId, nameCtrl.text, passCtrl.text);
              if (!success) {
                await ApiService().createParty(deviceId, nameCtrl.text, passCtrl.text);
              }
              ref.refresh(partyProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("決定！"),
          ),
        ],
      ),
    );
  }
}
