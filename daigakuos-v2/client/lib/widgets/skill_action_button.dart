import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

class SkillActionButton extends ConsumerStatefulWidget {
  const SkillActionButton({super.key});

  @override
  ConsumerState<SkillActionButton> createState() => _SkillActionButtonState();
}

class _SkillActionButtonState extends ConsumerState<SkillActionButton> {
  bool _isLoading = false;

  Future<void> _useSkill() async {
    final deviceId = ref.read(deviceIdProvider);
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService().useSkill(deviceId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.cyanAccent.withOpacity(0.8),
          ),
        );
      }
      ref.refresh(userProvider);
      ref.refresh(worldStatusProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) {
        final color = _getRoleColor(user.role);
        final icon = _getRoleIcon(user.role);
        final canUse = user.canUseSkill;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: (canUse && !_isLoading) ? _useSkill : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: canUse 
                          ? [color.withOpacity(0.8), color] 
                          : [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.2)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: canUse ? [
                      BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, spreadRadius: 2)
                    ] : [],
                    border: Border.all(color: canUse ? Colors.white24 : Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: _isLoading 
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getSkillName(user.role).toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              canUse ? "READY TO ACTIVATE!" : "COOLDOWN: ${user.skillCooldown}s",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (canUse)
                         const Icon(Icons.bolt, color: Colors.white, size: 28)
                           .animate(onPlay: (c) => c.repeat()).shake(hz: 3),
                    ],
                  ),
                ),
              ).animate(target: canUse ? 1 : 0).shimmer(duration: 2.seconds, color: Colors.white24),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
      case 'dps': return Icons.flash_on;
      default: return Icons.person;
    }
  }

  String _getSkillName(String role) {
    switch (role) {
      case 'tank': return 'Aegis Shield';
      case 'healer': return 'Sanctuary';
      case 'dps': return 'Limit Break';
      default: return 'Special Skill';
    }
  }
}
