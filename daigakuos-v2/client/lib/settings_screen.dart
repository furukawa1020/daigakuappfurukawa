import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:file_picker/file_picker.dart'; // Removed due to v1 embedding error
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'database_helper.dart';
import 'haptics_service.dart';
import 'main.dart'; // accessing global providers like wakeLockProvider if needed
import 'widgets/moko_card.dart';
import 'widgets/premium_background.dart';

// Providers for Settings
final wakeLockProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = "";

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadVersion();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    ref.read(wakeLockProvider.notifier).state = prefs.getBool('wakelock') ?? true;
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = "${info.version} (${info.buildNumber})";
    });
  }

  Future<void> _toggleWakeLock(bool value) async {
    ref.read(wakeLockProvider.notifier).state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wakelock', value);
    if (value) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  Future<void> _importData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("データインポート機能は現在利用できません（file_pickerプラグイン互換性問題）"))
    );
  }

  Future<void> _resetData() async {
    bool confirm = await showDialog(
      context: context, 
      builder: (c) => AlertDialog(
         title: const Text("データをリセットしますか？"),
         content: const Text("学習記録がすべて削除されます。本当に実行しますか？"),
         actions: [
           TextButton(onPressed:()=>Navigator.pop(c,false), child: const Text("キャンセル")),
           TextButton(onPressed:()=>Navigator.pop(c,true), child: const Text("削除", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
         ],
      )
    ) ?? false;

    if (confirm) {
       await DatabaseHelper().deleteAllData();
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("データをリセットしました。")));
       ref.refresh(dailyAggProvider);
       ref.refresh(weeklyAggProvider);
       ref.refresh(userStatsProvider);
       ref.refresh(historyProvider);
    }
  }

  Future<void> _setHomeLocation(BuildContext context) async {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) throw "Location services are disabled.";

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) throw "Location permissions are denied";
        }
        
        if (permission == LocationPermission.deniedForever) {
          throw "Location permissions are permanently denied.";
        }

        final position = await Geolocator.getCurrentPosition();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('home_lat', position.latitude);
        await prefs.setDouble('home_lon', position.longitude);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("現在地を自宅に設定しました🏠"))
          );
          ref.read(hapticsProvider.notifier).mediumImpact();
        }
      } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
         }
      }
  }

  @override
  Widget build(BuildContext context) {
    final wakeLock = ref.watch(wakeLockProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F6),
      body: PremiumBackground(
        child: Column(
          children: [
            AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF888888)),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text("設定", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF888888))),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                   const _SectionHeader(title: "一般"),
                   MokoCard(
                     padding: EdgeInsets.zero,
                     child: Column(
                       children: [
                         SwitchListTile(
                           title: const Text("画面を常時ONにする", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                           subtitle: const Text("集中セッション中、スリープを無効化します", style: TextStyle(color: Colors.grey)),
                           value: wakeLock, 
                           onChanged: _toggleWakeLock,
                           activeColor: const Color(0xFFB5EAD7), // Mint
                         ),
                         const Divider(height: 1),
                         Consumer(
                           builder: (context, ref, child) {
                             final hapticsEnabled = ref.watch(hapticsProvider);
                             return SwitchListTile(
                               title: const Text("触覚フィードバック", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                               subtitle: const Text("ボタン操作時などに振動します", style: TextStyle(color: Colors.grey)),
                               value: hapticsEnabled,
                               onChanged: (value) {
                                 ref.read(hapticsProvider.notifier).toggle(value);
                               },
                               activeColor: const Color(0xFFB5EAD7), // Mint
                             );
                           },
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 24),
                   
                   const _SectionHeader(title: "データ管理"),
                   MokoCard(
                     padding: EdgeInsets.zero,
                     child: Column(
                       children: [
                         ListTile(
                            leading: const Icon(Icons.home, color: Color(0xFFFFB7B2)),
                            title: const Text("自宅の場所を設定", style: TextStyle(color: Colors.black87)),
                            subtitle: const Text("現在地を「自宅」として登録します", style: TextStyle(color: Colors.grey)),
                            onTap: () async {
                               await _setHomeLocation(context);
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                           leading: const Icon(Icons.download, color: Color(0xFFC7CEEA)),
                           title: const Text("データをエクスポート", style: TextStyle(color: Colors.black87)),
                           onTap: () async {
                               await DatabaseHelper().exportData();
                           },
                         ),
                         const Divider(height: 1),
                         ListTile(
                           leading: const Icon(Icons.upload, color: Color(0xFFFFDAC1)),
                           title: const Text("データをインポート (復元)", style: TextStyle(color: Colors.black87)),
                           onTap: _importData,
                         ),
                         const Divider(height: 1),
                         ListTile(
                           leading: const Icon(Icons.delete_forever, color: Color(0xFFFF9AA2)),
                           title: const Text("データを全消去", style: TextStyle(color: Colors.black87)),
                           onTap: _resetData,
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 24),

                   const _SectionHeader(title: "アプリについて"),
                   MokoCard(
                     padding: EdgeInsets.zero,
                     child: ListTile(
                       title: const Text("バージョン", style: TextStyle(color: Colors.black87)),
                       trailing: Text(_version, style: const TextStyle(color: Colors.grey)),
                     ),
                   ),
                   const SizedBox(height: 20),
                   Center(
                     child: Text("DaigakuAPP v2.2\nMoko-Moko Edition", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                   )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
    );
  }
}
