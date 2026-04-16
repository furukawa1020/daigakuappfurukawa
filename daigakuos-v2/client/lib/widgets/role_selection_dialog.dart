import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

class RoleSelectionDialog extends ConsumerWidget {
  const RoleSelectionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.95),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.1),
              blurRadius: 40,
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "SELECT YOUR ROLE",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "役割を選んでパーティに貢献するもこ！",
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 32),
            _buildRoleCard(
              context,
              ref,
              'tank',
              '🛡️ TANK',
              '守りの要',
              'パーティ全員のシナジーボーナスを大幅強化。仲間の力を引き出すもこ！',
              Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              context,
              ref,
              'healer',
              '🔮 HEALER',
              '癒やしの聖職者',
              '集中終了時、パーティ全員にXPボーナスを分け与える支援のプロだもこ！',
              Colors.purpleAccent,
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              context,
              ref,
              'dps',
              '⚔️ DPS',
              '攻撃の騎士',
              '圧倒的なダメージを叩き出し、10%の確率でクリティカルヒットが発生するもこ！',
              Colors.redAccent,
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "CLOSE",
                style: GoogleFonts.outfit(color: Colors.white30, letterSpacing: 2),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: 0.9, end: 1, curve: Curves.easeOutBack),
    );
  }

  Widget _buildRoleCard(
    BuildContext context,
    WidgetRef ref,
    String role,
    String title,
    String sub,
    String desc,
    Color color,
  ) {
    final user = ref.watch(userProvider).asData?.value;
    final isSelected = user?.role == role;

    return GestureDetector(
      onTap: () async {
        final deviceId = ref.read(deviceIdProvider);
        await ApiService().updateRole(deviceId, role);
        ref.refresh(userProvider);
        if (context.mounted) Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sub,
                        style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white54, height: 1.4),
                  ),
                ],
              ),
            ),
            if (isSelected)
               Icon(Icons.check_circle, color: color, size: 24)
                 .animate().scale(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
