import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/moko_card.dart';
import 'widgets/premium_background.dart';
import 'state/app_state.dart';
import 'services/theme_service.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencies = ref.watch(currencyProvider);
    final activeTheme = ref.watch(themeProvider);

    return Scaffold(
      body: PremiumBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text("モコショップ", style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            
            // Currency Balance Display
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: MokoCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _currencyBadge("💰", "${currencies.mokoCoins}", "モココイン", const Color(0xFFFFD700)),
                    _currencyBadge("⭐", "${currencies.starCrystals}", "スター", const Color(0xFF64B5F6)),
                    _currencyBadge("💎", "${currencies.campusGems}", "ジェム", const Color(0xFFB5EAD7)),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2, end: 0),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("アイテム ＆ テーマ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            
            // Shop Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _shopItem(
                    context,
                    ref,
                    icon: "🎫",
                    title: "ガチャチケット",
                    description: "モココレクションを1回引ける",
                    price: 100,
                    currencyType: CurrencyType.mokoCoins,
                    currencyIcon: "💰",
                  ),
                  _themeItem(context, ref, "🍓", "Strawberry Theme", "可愛らしいピンクのテーマ", 200, MokoThemePreset.strawberry, activeTheme),
                  _themeItem(context, ref, "🌊", "Ocean Theme", "爽やかなミントブルーのテーマ", 200, MokoThemePreset.ocean, activeTheme),
                  _themeItem(context, ref, "🌃", "Midnight Theme", "落ち着いたインディゴのテーマ", 300, MokoThemePreset.midnight, activeTheme),
                  _themeItem(context, ref, "🍇", "Lavender Theme", "優雅なラベンダーのテーマ", 300, MokoThemePreset.lavender, activeTheme),
                  _shopItem(
                    context,
                    ref,
                    icon: "✨",
                    title: "XPブースター",
                    description: "次のセッションXP +50%",
                    price: 50,
                    currencyType: CurrencyType.mokoCoins,
                    currencyIcon: "💰",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/'),
        child: const Icon(Icons.home),
      ),
    );
  }

  Widget _themeItem(BuildContext context, WidgetRef ref, String icon, String title, String description, int price, MokoThemePreset preset, MokoThemePreset active) {
    final bool isActive = active == preset;
    
    return FutureBuilder<bool>(
      future: _isThemeUnlocked(preset),
      builder: (context, snapshot) {
        final bool isUnlocked = snapshot.data ?? (preset == MokoThemePreset.classic);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: MokoCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                if (isActive)
                   const Text("適用中", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                else if (isUnlocked)
                   FilledButton(
                     onPressed: () => ref.read(themeProvider.notifier).setTheme(preset),
                     style: FilledButton.styleFrom(backgroundColor: Colors.blueGrey),
                     child: const Text("適用"),
                   )
                else
                   FilledButton.icon(
                     onPressed: () => _purchaseTheme(context, ref, title, price, preset),
                     icon: const Text("💰"),
                     label: Text("$price"),
                     style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFB7B2)),
                   )
              ],
            ),
          ),
        );
      }
    );
  }

  Future<bool> _isThemeUnlocked(MokoThemePreset preset) async {
    if (preset == MokoThemePreset.classic) return true;
    final prefs = await SharedPreferences.getInstance();
    final unlockedRaw = prefs.getStringList('unlocked_themes') ?? [];
    return unlockedRaw.contains(preset.name);
  }

  void _purchaseTheme(BuildContext context, WidgetRef ref, String name, int price, MokoThemePreset preset) async {
    final success = await ref.read(currencyProvider.notifier).spend(CurrencyType.mokoCoins, price);
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      final unlockedRaw = prefs.getStringList('unlocked_themes') ?? [];
      if (!unlockedRaw.contains(preset.name)) {
        unlockedRaw.add(preset.name);
        await prefs.setStringList('unlocked_themes', unlockedRaw);
      }
      await ref.read(themeProvider.notifier).setTheme(preset);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name アンロック！")));
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("コインが足りません")));
      }
    }
  }

  Widget _currencyBadge(String icon, String amount, String label, Color color) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _shopItem(
    BuildContext context,
    WidgetRef ref, {
    required String icon,
    required String title,
    required String description,
    required int price,
    required CurrencyType currencyType,
    required String currencyIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: MokoCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _purchase(context, ref, title, price, currencyType),
              icon: Text(currencyIcon),
              label: Text("$price"),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFB7B2),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideX(begin: 0.2, end: 0),
    );
  }

  void _purchase(BuildContext context, WidgetRef ref, String itemName, int price, CurrencyType currencyType) async {
    final currencyService = ref.read(currencyProvider.notifier);
    
    final success = await currencyService.spend(currencyType, price);
    
    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$itemName を購入しました！"), backgroundColor: Colors.green),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("通貨が不足しています"), backgroundColor: Colors.red),
        );
      }
    }
  }
}

