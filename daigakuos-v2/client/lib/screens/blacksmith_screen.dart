import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

class BlacksmithScreen extends ConsumerStatefulWidget {
  const BlacksmithScreen({super.key});

  @override
  ConsumerState<BlacksmithScreen> createState() => _BlacksmithScreenState();
}

class _BlacksmithScreenState extends ConsumerState<BlacksmithScreen> {
  Map<String, dynamic>? _blacksmithData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBlacksmith();
  }

  Future<void> _loadBlacksmith() async {
    final deviceId = ref.read(deviceIdProvider);
    final data = await ApiService().fetchBlacksmith(deviceId);
    if (mounted) setState(() { _blacksmithData = data; _loading = false; });
  }

  Future<void> _craft(String itemId) async {
    final deviceId = ref.read(deviceIdProvider);
    try {
      final result = await ApiService().craftItem(deviceId, itemId);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text("生産成功！🔨", style: TextStyle(color: Colors.white)),
            content: Text(result['message'], style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
            ],
          ),
        );
      }
      _loadBlacksmith();
      ref.refresh(userProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("BLACKSMITH", style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader("YOUR INVENTORY"),
              _buildInventoryGrid(),
              const SizedBox(height: 24),
              _buildSectionHeader("CRAFTING RECIPES"),
              ...((_blacksmithData?['recipes'] as Map?) ?? {})
                  .entries.map((e) => _buildRecipeCard(e.key, e.value)),
            ],
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amberAccent, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildInventoryGrid() {
    final inventory = Map<String, int>.from(_blacksmithData?['inventory'] ?? {});
    if (inventory.isEmpty) {
      return const Text("素材を持っていないもこ...", style: TextStyle(color: Colors.white24, fontSize: 12));
    }
    return Wrap(
      spacing: 8,
      children: inventory.entries.map((e) => _buildMaterialChip(e.key, e.value)).toList(),
    );
  }

  Widget _buildMaterialChip(String key, int count) {
    return Chip(
      backgroundColor: Colors.white.withOpacity(0.05),
      label: Text(
        "${key.replaceAll('_', ' ')} x$count",
        style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
      ),
    );
  }

  Widget _buildRecipeCard(String id, dynamic recipe) {
    final inventory = Map<String, int>.from(_blacksmithData?['inventory'] ?? {});
    final reqs = Map<String, int>.from(recipe['materials'] ?? {});
    bool canCraft = true;
    for (var m in reqs.entries) {
       if ((inventory[m.key] ?? 0) < m.value) canCraft = false;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: canCraft ? Colors.amberAccent : Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recipe['name'],
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              recipe['desc'],
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white54),
            ),
            const SizedBox(height: 12),
            Wrap(
               spacing: 8,
               children: reqs.entries.map((m) {
                 final has = inventory[m.key] ?? 0;
                 return _buildMaterialReqChip(m.key, has, m.value);
               }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
               onPressed: canCraft ? () => _craft(id) : null,
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.amberAccent,
                 foregroundColor: Colors.black87,
                 disabledBackgroundColor: Colors.white.withOpacity(0.05),
                 disabledForegroundColor: Colors.white24,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               ),
               child: const Text("生産する", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildMaterialReqChip(String key, int has, int req) {
    bool ok = has >= req;
    return Chip(
      backgroundColor: Colors.white.withOpacity(0.02),
      label: Text(
        "${key.replaceAll('_', ' ')}: $has / $req",
        style: GoogleFonts.inter(fontSize: 9, color: ok ? Colors.white70 : Colors.redAccent),
      ),
    );
  }
}
