import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MokoThemePreset { classic, midnight, strawberry, ocean, lavender }

final themeProvider = StateNotifierProvider<ThemeNotifier, MokoThemePreset>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<MokoThemePreset> {
  ThemeNotifier() : super(MokoThemePreset.classic) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('active_moko_theme') ?? 'classic';
    state = MokoThemePreset.values.firstWhere(
      (e) => e.name == themeName, 
      orElse: () => MokoThemePreset.classic
    );
  }

  Future<void> setTheme(MokoThemePreset preset) async {
    state = preset;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_moko_theme', preset.name);
  }

  ThemeData getThemeData(bool isDark) {
    switch (state) {
      case MokoThemePreset.midnight:
        return _buildTheme(
          primary: const Color(0xFF6366F1), 
          secondary: const Color(0xFF818CF8),
          background: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          isDark: isDark
        );
      case MokoThemePreset.strawberry:
        return _buildTheme(
          primary: const Color(0xFFFF9AA2), 
          secondary: const Color(0xFFFFB7B2),
          background: isDark ? const Color(0xFF2D1B1B) : const Color(0xFFFFF5F6),
          isDark: isDark
        );
      case MokoThemePreset.ocean:
        return _buildTheme(
          primary: const Color(0xFF00ADB5), 
          secondary: const Color(0xFFB5EAD7),
          background: isDark ? const Color(0xFF222831) : const Color(0xFFE0F7FA),
          isDark: isDark
        );
      case MokoThemePreset.lavender:
        return _buildTheme(
          primary: const Color(0xFFC7CEEA), 
          secondary: const Color(0xFFE2F0CB),
          background: isDark ? const Color(0xFF1E1B2D) : const Color(0xFFF3E5F5),
          isDark: isDark
        );
      default:
        // Classic
        return _buildTheme(
          primary: const Color(0xFFB5EAD7), 
          secondary: const Color(0xFFFFB7B2),
          background: isDark ? const Color(0xFF121212) : const Color(0xFFFFF5F6),
          isDark: isDark
        );
    }
  }

  ThemeData _buildTheme({required Color primary, required Color secondary, required Color background, required bool isDark}) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: isDark 
        ? ColorScheme.dark(primary: primary, secondary: secondary, surface: background)
        : ColorScheme.light(primary: primary, secondary: secondary, surface: Colors.white),
      fontFamily: 'Roboto',
    );
  }
}
