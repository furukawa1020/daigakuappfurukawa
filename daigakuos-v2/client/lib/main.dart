import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // For StateProvider in Riverpod v3
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For DateFormat
import 'package:permission_handler/permission_handler.dart'; // For permission
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'state/app_state.dart';

import 'database_helper.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'haptics_service.dart';
import 'widgets/hyperfocus_button.dart';
import 'achievement_service.dart';
import 'moko_collection_screen.dart';
import 'widgets/moko_card.dart';
import 'widgets/premium_background.dart';
import 'widgets/stat_item.dart';
import 'widgets/quick_start_button.dart';

// -----------------------------------------------------------------------------
// 1. Models & State
// -----------------------------------------------------------------------------

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
    'daigaku_channel', 
    'DaigakuAPP Notifications',
    channelDescription: 'Notifications for study session completion',
    importance: Importance.max,
    priority: Priority.high,
  );
  const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
  await flutterLocalNotificationsPlugin.show(0, title, body, notificationDetails);
}


// Models and Providers moved to state/app_state.dart

const double CAMPUS_LAT = 36.5639;
const double CAMPUS_LON = 136.6845;
const double CAMPUS_RADIUS_METERS = 500.0;


Future<LocationBonus> checkLocationBonus() async {
  try {
    // Check permission
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
       await Geolocator.requestPermission();
    }
    
    // Quick check with timeout
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5)
    );

    // Check Campus
    double distCampus = Geolocator.distanceBetween(
      CAMPUS_LAT, CAMPUS_LON, position.latitude, position.longitude,
    );
    if (distCampus <= CAMPUS_RADIUS_METERS) return LocationBonus.campus;

    // Check Home
    final prefs = await SharedPreferences.getInstance();
    final homeLat = prefs.getDouble('home_lat');
    final homeLon = prefs.getDouble('home_lon');

    if (homeLat != null && homeLon != null) {
      double distHome = Geolocator.distanceBetween(
        homeLat, homeLon, position.latitude, position.longitude,
      );
      if (distHome <= 100) return LocationBonus.home; // 100m radius for home
    }

    return LocationBonus.none;
  } catch (e) {
    print("Geo Error: $e");
    return LocationBonus.none;
  }
}

// -----------------------------------------------------------------------------
// 2. Navigation & Theme
// -----------------------------------------------------------------------------

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => HomeScreen()),
    GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(path: '/now', builder: (context, state) => const NowScreen()),
    GoRoute(path: '/finish', builder: (context, state) => const FinishScreen()),
    GoRoute(path: '/collection', builder: (context, state) => const MokoCollectionScreen()),
  ],
);

void main() async { // Async main
  WidgetsFlutterBinding.ensureInitialized(); // Ensure binding
  await initNotifications(); // Init notifications
  runApp(const ProviderScope(child: DaigakuAPPApp()));
}

class DaigakuAPPApp extends StatelessWidget {
  const DaigakuAPPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'DaigakuAPP v2',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFF5F6), // Pale Pink Background
        primaryColor: const Color(0xFFB5EAD7), // Mint
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFFFFB7B2), // Salmon Pink
          surface: Colors.white,
        ),
        fontFamily: 'Roboto', // Ideally rounded font
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000), // Pure Black for OLED
        primaryColor: const Color(0xFF7DBAA0), // Softer Mint
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF7DBAA0),
          secondary: const Color(0xFFFF9D97), // Softer Salmon
          surface: const Color(0xFF121212), // Very Dark Gray
          background: const Color(0xFF000000),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFFE0E0E0), // Gentle white
          onBackground: const Color(0xFFE0E0E0),
        ),
        cardColor: const Color(0xFF1E1E1E),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Auto-switch based on system
    );
  }
}

// PremiumBackground moved to widgets/premium_background.dart

// -----------------------------------------------------------------------------
// 4. Screens
// -----------------------------------------------------------------------------

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final historyAsync = ref.watch(historyProvider);
    final weeklyAsync = ref.watch(weeklyAggProvider);

    // Level Up Check
    ref.listen<AsyncValue<UserStats>>(userStatsProvider, (previous, next) async {
      final oldLevel = previous?.asData?.value.level;
      final newLevel = next.asData?.value.level;
      if (oldLevel != null && newLevel != null && newLevel > oldLevel) {
         final prefs = await SharedPreferences.getInstance();
         await prefs.setInt('last_seen_level', newLevel);
         _showLevelUpDialog(context, newLevel, ref);
      }
    });

    return Scaffold(
      body: PremiumBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text("DaigakuAPP", style: TextStyle(fontWeight: FontWeight.w800)),
              centerTitle: false,
              backgroundColor: Colors.transparent,
            actions: [
                IconButton(
                  icon: const Icon(Icons.collections_bookmark, color: Colors.brown),
                  onPressed: () {
                    ref.read(hapticsProvider.notifier).lightImpact();
                    context.push('/collection');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    ref.read(hapticsProvider.notifier).lightImpact();
                    context.push('/settings');
                  },
                )
              ],
            ),

            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                  // Daily Moko Message (ADHD Deep Dive)
                    Consumer(builder: (context, ref, _) {
                       final messages = [
                         "今日もよろしくね✨",
                         "マイペースでいこう💫",
                         "1分でも十分だよ🌟",
                         "あなたならできる！",
                         "焦らなくて大丈夫",
                         "小さな一歩が大事",
                         "今日のあなたが最高",
                         "完璧じゃなくてOK💕",
                       ];
                       final today = DateTime.now().day;
                       final message = messages[today % messages.length];
                       
                       return MokoCard(
                         color: const Color(0xFFFFE5EC), // Light pink
                         child: Row(
                           children: [
                             const Text("💌", style: TextStyle(fontSize: 32)),
                             const SizedBox(width: 12),
                             Expanded(
                               child: Text(
                                 message,
                                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF666666)),
                               ),
                             ),
                           ],
                         ),
                       ).animate().fadeIn().slideX();
                    }),
                    
                    const SizedBox(height: 16),
                    
                  // Location Status Badge (Pill)
                    Consumer(builder: (context, ref, _) {
                        final bonus = ref.watch(locationBonusProvider);
                        
                        Color getBgColor() {
                          switch (bonus) {
                            case LocationBonus.campus: return Colors.green.shade100;
                            case LocationBonus.home: return Colors.orange.shade100;
                            default: return Colors.white.withOpacity(0.5);
                          }
                        }
                        
                        Color getFgColor() {
                          switch (bonus) {
                            case LocationBonus.campus: return Colors.green[800]!;
                            case LocationBonus.home: return Colors.orange[800]!;
                            default: return Colors.grey[700]!;
                          }
                        }
                        
                        String getText() {
                           switch (bonus) {
                            case LocationBonus.campus: return "キャンパス内 (1.5倍)";
                            case LocationBonus.home: return "自宅警備中 (1.2倍)";
                            default: return "キャンパス外";
                          }
                        }

                        return GestureDetector(
                          onTap: () async {
                              ref.read(hapticsProvider.notifier).lightImpact();
                              final newBonus = await checkLocationBonus();
                              ref.read(locationBonusProvider.notifier).state = newBonus;
                              
                              String msg;
                              if (newBonus == LocationBonus.campus) msg = "キャンパス内にいます！ (1.5倍ボーナス)";
                              else if (newBonus == LocationBonus.home) msg = "自宅警備モード！ (1.2倍ボーナス)";
                              else msg = "位置情報を更新しました";
                              
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                          },
                          child: AnimatedContainer(
                            duration: 500.ms,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: getBgColor(),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: getBgColor().withOpacity(1.0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, size: 16, color: getFgColor()),
                                const SizedBox(width: 8),
                                Text(
                                  getText(),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: getFgColor()),
                                )
                              ],
                            ),
                          ),
                        );
                    }),
                    
                    const SizedBox(height: 12),

                    // Rest Day Toggle (ADHD Deep Dive)
                    statsAsync.when(
                      data: (stats) => GestureDetector(
                        onTap: () async {
                          ref.read(hapticsProvider.notifier).mediumImpact();
                          final today = DateTime.now().toIso8601String().substring(0, 10);
                          await DatabaseHelper().toggleRestDay(today);
                          ref.refresh(userStatsProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(stats.isRestDay ? "しっかり休んでね！🌟" : "今日の休みを取り消しました。"),
                              duration: const Duration(seconds: 2),
                            )
                          );
                        },
                        child: AnimatedContainer(
                          duration: 400.ms,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: stats.isRestDay ? const Color(0xFFC7CEEA) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: (stats.isRestDay ? const Color(0xFFC7CEEA) : Colors.black).withOpacity(0.1), blurRadius: 10)]
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                               Text(stats.isRestDay ? "⛱️ 今日は休み！" : "💤 今日を休みにする", 
                                 style: TextStyle(
                                   fontWeight: FontWeight.bold, 
                                   color: stats.isRestDay ? Colors.white : Colors.grey[600],
                                   fontSize: 13
                                 )
                               ),
                            ],
                          ),
                        ).animate(target: stats.isRestDay ? 1 : 0).shimmer(duration: 2.seconds),
                      ),
                      loading: () => const SizedBox(),
                      error: (_,__) => const SizedBox(),
                    ),

                    
                    const SizedBox(height: 24),

                    // Main Stats Card
                    statsAsync.when(
                      data: (stats) => MokoCard(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("LEVEL ${stats.level}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.blueAccent)),
                                      const SizedBox(height: 4),
                                      Text("${stats.totalPoints.toInt()} XP", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 8),
                                      Column(
                                        children: [
                                          SizedBox(
                                            width: 140,
                                            height: 8,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: stats.levelProgress,
                                                backgroundColor: Colors.blue.withOpacity(0.1),
                                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "あと ${(stats.nextLevelPoints - stats.totalPoints).toInt()} XP で Level Up!",
                                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                // Streak Ring
                                Container(
                                  width: 60, height: 60,
                                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Colors.orange.shade300, Colors.red.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text("🔥", style: TextStyle(fontSize: 16)),
                                        Text("${stats.currentStreak}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                              ],
                            ),
                            StatItem(label: "Level", value: "${stats.level}", icon: Icons.star, color: const Color(0xFFFFB7B2)),
                            StatItem(label: "XP", value: "${stats.totalPoints.toInt()}", icon: Icons.bolt, color: const Color(0xFFFFDAC1)),
                            StatItem(label: "Streak", value: "${stats.currentStreak}日", icon: Icons.local_fire_department, color: const Color(0xFFFF9AA2)),
                          ],
                        ),
                      ),
                      loading: () => const MokoCard(child: SizedBox(height: 150, child: Center(child: CircularProgressIndicator()))),
                      error: (e, _) => const SizedBox(),
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 16),
                    
                    const SizedBox(height: 32),
                    
                    // "No-Pressure" One-Tap Start Section
                    Consumer(
                      builder: (context, ref, _) {
                         final history = ref.watch(historyProvider).asData?.value ?? [];
                         String? recentTitle;
                         if (history.isNotEmpty) {
                            // Find first valid title
                            recentTitle = history.firstWhere((item) => (item['title'] as String).isNotEmpty, orElse: () => {'title': ''})['title'];
                            if (recentTitle!.isEmpty) recentTitle = null;
                         }

                         return Column(
                           crossAxisAlignment: CrossAxisAlignment.stretch,
                           children: [
                              Text(
                                "さあ、始めましょう", // Let's get started
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey[800])
                              ),
                              const SizedBox(height: 12),
                              
                              if (recentTitle != null)
                                GestureDetector(
                                  onTap: () {
                                     ref.read(hapticsProvider.notifier).heavyImpact();
                                     ref.read(selectedTaskProvider.notifier).state = recentTitle!;
                                     // "One-Tap" -> Immediate Launch
                                     ref.read(sessionProvider.notifier).state = Session(startAt: DateTime.now());
                                     context.push('/now');
                                  },
                                  child: MokoCard(
                                    color: const Color(0xFFB5EAD7), // Mint
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                           const Icon(Icons.play_circle_fill, size: 48, color: Colors.white),
                                           const SizedBox(height: 12),
                                           Text(
                                             recentTitle,
                                             style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
                                             textAlign: TextAlign.center,
                                           ),
                                           const SizedBox(height: 8),
                                           Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                                              child: const Text("前回の続きをやる", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
                                           ),
                                        ],
                                      ),
                                    ),
                                  ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                                ),
                              else
                                MokoCard(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        const Icon(Icons.nature_people, size: 40, color: Color(0xFFFFB7B2)),
                                        const SizedBox(height: 8),
                                        const Text("まずは5分、\n何も考えずにやってみよう", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                                
                              // One-Minute Mode (ADHD Deep Dive)
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                   ref.read(hapticsProvider.notifier).mediumImpact();
                                   ref.read(selectedTaskProvider.notifier).state = "1分チャレンジ";
                                   ref.read(sessionProvider.notifier).state = Session(startAt: DateTime.now());
                                   context.push('/now');
                                   
                                   // Show encouraging message
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     const SnackBar(
                                       content: Text("1分だけでOK！やめたくなったらやめてOK💫"),
                                       duration: Duration(seconds: 2),
                                     )
                                   );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F5), // Lavender blush
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(color: const Color(0xFFFFB7B2), width: 2),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.timer, size: 20, color: Color(0xFFFF9AA2)),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "1分だけやる",
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF666666), fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(delay: 300.ms).slideX(),
                              ),
                           ],
                         );
                      }
                    ),

                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("最近の履歴", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.calendar_month, color: Colors.grey),
                          onPressed: () => context.push('/calendar'),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // History List
            historyAsync.when(
               data: (sessions) => SliverList(
                 delegate: SliverChildBuilderDelegate(
                   (context, index) {
                     final s = sessions[index];
                     return Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                       child: InkWell(
                         onTap: () => _editSession(context, s, ref),
                         child: MokoCard(
                           padding: const EdgeInsets.all(16),
                           child: Row(
                             children: [
                               Container(
                                 width: 40, height: 40,
                                 decoration: BoxDecoration(
                                   color: Colors.blue.shade50,
                                   borderRadius: BorderRadius.circular(12)
                                 ),
                                 child: const Icon(Icons.check, color: Colors.blue),
                               ),
                               const SizedBox(width: 16),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(s['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                     Text("${s['minutes']}分間 • ${s['points'].toStringAsFixed(0)} pts", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                   ],
                                 ),
                               ),
                               Text(
                                 DateTime.parse(s['startAt']).toLocal().toString().substring(11, 16),
                                 style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)
                               ),
                             ],
                           ),
                         ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(),
                       ),
                     );
                   },
                   childCount: sessions.length
                 ),
               ),
               loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
               error: (_,__) => const SliverToBoxAdapter(child: SizedBox()),
            ),
            
            // Spacer for FAB
            const SliverPadding(padding: EdgeInsets.only(bottom: 150)),
            
            SliverToBoxAdapter(
              child: Center(
                child: Text(
                  "長押しでチャージして開始",
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, letterSpacing: 1.2),
                ).animate().fadeIn(delay: 1.seconds),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 50)),
          ],
        ),
      ),
      floatingActionButton: HyperfocusButton(
        onComplete: () async {
            // Start Session Logic
            final bonus = await checkLocationBonus();
            ref.read(locationBonusProvider.notifier).state = bonus;
            
            // Get selected task if any
            final selectedTask = ref.read(selectedTaskProvider);
            
            ref.read(sessionProvider.notifier).state = Session(
              startAt: DateTime.now(), 
              // We could pass the title here if Session had a title field, 
              // but Session model is currently minimal. 
              // We'll pass it via constructor or another provider if needed.
              // For now, let's assume we handle it in NowScreen by reading the provider.
            );
            context.push('/now');
        },
      ).animate().scale(delay: 500.ms, curve: Curves.elasticOut),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      extendBody: true, // For better visual integration
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Metric({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
}

Future<void> _editSession(BuildContext context, Map<String, dynamic> session, WidgetRef ref) async {
    final titleCtrl = TextEditingController(text: session['title']);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("セッション編集"),
        content: TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "タスク名")),
        actions: [
          TextButton(
            onPressed: () async {
               if (await _confirmDelete(ctx)) {
                  await DatabaseHelper().deleteSession(session['id']);
                  ref.refresh(historyProvider);
                  ref.refresh(dailyAggProvider);
                  ref.refresh(userStatsProvider);
                  Navigator.pop(ctx);
               }
            }, 
            child: const Text("削除", style: TextStyle(color: Colors.red))
          ),
          FilledButton(
            onPressed: () async {
               ref.read(hapticsProvider.notifier).mediumImpact();
               await DatabaseHelper().updateSessionTitle(session['id'], titleCtrl.text);
               ref.refresh(historyProvider);
               Navigator.pop(ctx);
            },
            child: const Text("保存")
          ),
        ],
      )
    );
}

Future<bool> _confirmDelete(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text("削除しますか？"), 
      actions: [TextButton(onPressed:()=>Navigator.pop(c,false), child:const Text("キャンセル")), TextButton(onPressed:()=>Navigator.pop(c,true), child:const Text("削除", style:TextStyle(color:Colors.red)))]
    )
  ) ?? false;
}

// -----------------------------------------------------------------------------
// NOW SCREEN (Focus Mode)
// -----------------------------------------------------------------------------

class NowScreen extends ConsumerStatefulWidget {
  const NowScreen({super.key});

  @override
  ConsumerState<NowScreen> createState() => _NowScreenState();
}

class _NowScreenState extends ConsumerState<NowScreen> with TickerProviderStateMixin {
  late Timer _timer;
  Duration _elapsed = Duration.zero;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Pre-fill from selectedTaskProvider
    final selected = ref.read(selectedTaskProvider);
    if (selected != null) {
      // We don't have a title field in Session state, so simple ephemeral storage is used in _finish
      // For now, let's just log or set it if we add a local controller
    }

    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    
    final session = ref.read(sessionProvider);
    if (session != null) {
       _elapsed = DateTime.now().difference(session.startAt);
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = ref.read(sessionProvider);
      if (s != null) setState(() => _elapsed = DateTime.now().difference(s.startAt));
    });

    // Enable WakeLock if setting is true
    _enableWakeLock();
  }

  Future<void> _enableWakeLock() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('wakelock') ?? true) {
      WakelockPlus.enable();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    WakelockPlus.disable(); // Always disable on exit
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(_elapsed.inMinutes);
    final seconds = twoDigits(_elapsed.inSeconds % 60);
    final taskTitle = ref.watch(selectedTaskProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF111827), // Dark Mode
      body: Stack(
        children: [
          // Background Glow
           Center(
             child: AnimatedBuilder(
               animation: _pulseController,
               builder: (_, __) {
                 return Container(
                   width: 300 + (_pulseController.value * 20),
                   height: 300 + (_pulseController.value * 20),
                   decoration: BoxDecoration(
                     shape: BoxShape.circle,
                     color: const Color(0xFF4F46E5).withOpacity(0.1 + (_pulseController.value * 0.1)),
                     boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 50 + (_pulseController.value * 20))]
                   ),
                 );
               },
             ),
           ),
           
           SafeArea(
             child: Column(
               children: [
                  const SizedBox(height: 20),
                  const Text("Deep Focus", style: TextStyle(color: Colors.white54, letterSpacing: 4, fontSize: 14)),
                  
                  // Mood Selector (v3)
                  const SizedBox(height: 24),
                  Consumer(builder: (context, ref, _) {
                    final session = ref.watch(sessionProvider);
                    if (session?.moodPre != null) return const SizedBox();
                    
                    final moods = [
                      {'e': '😃', 'l': 'Energetic'},
                      {'e': '🙂', 'l': 'Good'},
                      {'e': '😐', 'l': 'Neutral'},
                      {'e': '😔', 'l': 'Tired'},
                      {'e': '😫', 'l': 'Stressed'},
                    ];
                    
                    return Column(
                      children: [
                        const Text("今の気分は？", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: moods.map((m) => GestureDetector(
                            onTap: () {
                              ref.read(hapticsProvider.notifier).lightImpact();
                              ref.read(sessionProvider.notifier).state = Session(
                                id: session?.id,
                                startAt: session?.startAt ?? DateTime.now(),
                                durationMinutes: session?.durationMinutes,
                                moodPre: m['e'],
                                moodPost: session?.moodPost,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Text(m['e']!, style: const TextStyle(fontSize: 24)),
                            ),
                          )).toList(),
                        ),
                      ],
                    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
                  }),

                  Expanded(
                    child: Center(
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Text(
                           "$minutes:$seconds", 
                           style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.w200, fontFamily: 'monospace'),
                         ).animate().fadeIn(duration: 1.seconds),
                         const SizedBox(height: 10),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                           decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                           child: Text(taskTitle ?? "DaigakuAPP 実行中...", style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                         )
                       ],
                     ),
                   ),
                 ),
                 
                 // Slider to Finish
                 Padding(
                   padding: const EdgeInsets.all(40),
                   child: GestureDetector(
                     onTap: () {
                        ref.read(hapticsProvider.notifier).heavyImpact();
                        // Complete logic
                        final s = ref.read(sessionProvider);
                        if (s != null) {
                           int duration = _elapsed.inMinutes;
                           if (duration < 1) duration = 1;
                           ref.read(sessionProvider.notifier).state = Session(id: s.id, startAt: s.startAt, durationMinutes: duration);
                        }
                        context.pushReplacement('/finish');
                     },
                     child: Container(
                       height: 60,
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(30),
                         border: Border.all(color: Colors.white24),
                         color: Colors.white.withOpacity(0.05)
                       ),
                       child: const Center(
                         child: Text("完了", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                       ),
                     ),
                   ),
                 ),
               ],
             ),
           ),
        ],
      )
    );
  }
}

// -----------------------------------------------------------------------------
// FINISH SCREEN
// -----------------------------------------------------------------------------

class FinishScreen extends ConsumerStatefulWidget {
  const FinishScreen({super.key});

  @override
  ConsumerState<FinishScreen> createState() => _FinishScreenState();
}

class _FinishScreenState extends ConsumerState<FinishScreen> {
  late ConfettiController _confetti;
  final TextEditingController _titleCtrl = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];

  String _praiseMessage = "お疲れ様でした！";

  final List<String> _praiseMessages = [
    "天才ですか？",
    "その集中力、神。",
    "偉業を成し遂げましたね。",
    "今日も世界を救いました",
    "ゆっくり休んでね。",
    "君ならできると信じてた！",
    "1分でも勝利です🎉",
    "戻ってきてくれてありがとう✨",
    "完璧じゃなくて大丈夫💕",
    "あなたのペースが一番",
    "今日もよくがんばった！",
    "小さな一歩が素敵✨",
    "休むのも大事だよ🌙",
    "マイペースでOK💫", "またやれるよ！",
    "あなたは十分がんばった",
    "焦らなくていいからね",
    "続けてるだけで偉い🌟",
  ];

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _confetti.play();
    
    // Play sound/haptics
    ref.read(hapticsProvider.notifier).heavyImpact();
    
    // Pre-fill title from provider
    final selectedTask = ref.read(selectedTaskProvider);
    if (selectedTask != null) {
      _titleCtrl.text = selectedTask;
    }
    
    // Random Praise
    _praiseMessage = _praiseMessages[Random().nextInt(_praiseMessages.length)];
    
    // Suggest next actions (Could be from API or local logic)
    _loadSuggestions();
  }

  void _loadSuggestions() async {
    // Mock suggestions for now. In real app, analyze context or time.
    setState(() {
      _suggestions = [
        {'title': 'レポート執筆', 'node_id': 'task_1'},
        {'title': '読書', 'node_id': 'task_2'},
        {'title': 'プログラミング', 'node_id': 'task_3'},
        {'title': '休憩', 'node_id': 'task_break'},
      ];
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  void _finish(String? nodeId) async {
     final session = ref.read(sessionProvider);
     if (session != null) {
        final title = _titleCtrl.text.isNotEmpty ? _titleCtrl.text : (nodeId != null ? _suggestions.firstWhere((s) => s['node_id'] == nodeId)['title'] : "無題のセッション");
        final mins = session.durationMinutes ?? 0;
        
        await DatabaseHelper().insertSession(
          draftTitle: title,
          startAt: session.startAt,
          minutes: mins,
          isOnCampus: ref.read(locationBonusProvider) == LocationBonus.campus,
          nodeId: nodeId,
          moodPre: session.moodPre,
          moodPost: session.moodPost,
        );

        // Update Stats
        // await DatabaseHelper().updateUserStats(mins, (mins * 10).toDouble()); // Removed: Stats are calculated dynamically from sessions
        
        // Refresh Providers
        ref.refresh(userStatsProvider);
        ref.refresh(historyProvider);
        ref.refresh(dailyAggProvider);
        ref.refresh(weeklyAggProvider);
        
        // Check Achievements
        final homeBonus = ref.read(locationBonusProvider) == LocationBonus.home; // This might be reset by now, but let's try
     
        final newAchievements = await ref.read(achievementProvider.notifier).checkAchievements(mins, session.startAt, homeBonus);
     
        if (mounted) {
           if (newAchievements.isNotEmpty) {
             // Show Achievement Dialog or SnackBar
             for (var ach in newAchievements) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Row(children: [Icon(ach.icon, color: Colors.white), SizedBox(width:8), Text("実績解除: ${ach.title}")]),
                  backgroundColor: ach.color,
                ));
             }
           }
           
           // Show Notification (Local)
           await showNotification("セッション完了", "お疲れ様でした！ $mins分間の集中を記録しました。");
           
           // Return home
           if (context.canPop()) {
              context.pop(); 
              // We need to pop 'now' screen or go root. 
              // Since we pushedReplacement to finish, we might need to go home explicitly.
              context.go('/'); 
           } else {
              context.go('/');
           }
        }
     }
  }
  



  @override
  Widget build(BuildContext context) {
    final session = ref.read(sessionProvider);
    final mins = session?.durationMinutes ?? 0;

    return Scaffold(
      body: Stack(
        children: [
          Align(alignment: Alignment.topCenter, child: ConfettiWidget(confettiController: _confetti, blastDirectionality: BlastDirectionality.explosive, numberOfParticles: 30, colors: const [Colors.blue, Colors.pink, Colors.orange])),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Moko-Moko Finish Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: const Color(0xFFC7CEEA).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         const Icon(Icons.check_circle, color: Color(0xFFB5EAD7), size: 80).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                         const SizedBox(height: 16),
                         Text(_praiseMessage, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[800]), textAlign: TextAlign.center),
                         const SizedBox(height: 8),
                         Text("$mins分間の集中", style: TextStyle(color: Colors.grey[500])),
                         
                         // Post-session Mood Selector
                         const SizedBox(height: 24),
                         const Text("今の気分を教えてね ✨", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                         const SizedBox(height: 12),
                         Consumer(builder: (context, ref, _) {
                           final session = ref.watch(sessionProvider);
                           final moods = ['😃', '🙂', '😐', '😔', '😫'];
                           
                           return Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: moods.map((m) => GestureDetector(
                               onTap: () {
                                 ref.read(hapticsProvider.notifier).lightImpact();
                                 ref.read(sessionProvider.notifier).state = Session(
                                   id: session?.id,
                                   startAt: session?.startAt ?? DateTime.now(),
                                   durationMinutes: session?.durationMinutes,
                                   moodPre: session?.moodPre,
                                   moodPost: m,
                                 );
                               },
                               child: Container(
                                 margin: const EdgeInsets.symmetric(horizontal: 6),
                                 padding: const EdgeInsets.all(10),
                                 decoration: BoxDecoration(
                                   color: session?.moodPost == m ? const Color(0xFFC7CEEA).withOpacity(0.5) : Colors.grey[100],
                                   shape: BoxShape.circle,
                                   border: session?.moodPost == m ? Border.all(color: const Color(0xFFC7CEEA), width: 2) : null,
                                 ),
                                 child: Text(m, style: const TextStyle(fontSize: 24)),
                               ),
                             )).toList(),
                           );
                         }),

                         const SizedBox(height: 24),
                         TextField(
                           controller: _titleCtrl,
                           decoration: InputDecoration(
                             filled: true,
                             fillColor: const Color(0xFFFFF5F6),
                             hintText: "何をしていましたか？",
                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                           ),
                         ),
                         const SizedBox(height: 16),
                         Wrap(
                           spacing: 8,
                           children: _suggestions.map((s) => ActionChip(
                             elevation: 0,
                             backgroundColor: const Color(0xFFE2F0CB),
                             label: Text(s['title'], style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                             onPressed: () {
                               ref.read(hapticsProvider.notifier).lightImpact();
                               _titleCtrl.text = s['title'];
                             },
                           )).toList(),
                         ),
                         const SizedBox(height: 32),
                         SizedBox(
                           width: double.infinity,
                           height: 50,
                           child: FilledButton(
                             style: FilledButton.styleFrom(
                               backgroundColor: const Color(0xFFFFB7B2),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))
                             ),
                             onPressed: () => _finish(_suggestions.isNotEmpty ? _suggestions.first['node_id'] : null),
                             child: const Text("記録する", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                           ),
                         ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// LEVEL UP DIALOG
// -----------------------------------------------------------------------------

void _showLevelUpDialog(BuildContext context, int level, WidgetRef ref) {
  ref.read(hapticsProvider.notifier).heavyImpact();
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🌟 LEVEL UP 🌟", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 2)),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                   Container(
                     width: 100, height: 100,
                     decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent.withOpacity(0.1)),
                   ).animate(onPlay:(c)=>c.repeat()).scale(duration: 1.seconds, curve: Curves.easeInOut),
                   Text("$level", style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
                ],
              ),
              const SizedBox(height: 20),
              const Text("すごいです！", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text("新しい高みに到達しました。", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("やったね！", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ).animate().scale(curve: Curves.elasticOut, duration: 800.ms).fadeIn(),
      ),
    ),
  );
}

