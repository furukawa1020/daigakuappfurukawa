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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'database_helper.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'haptics_service.dart';
import 'widgets/hyperfocus_button.dart';

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


class Session {
  final String? id;
  final DateTime startAt;
  final int? durationMinutes;

  Session({this.id, required this.startAt, this.durationMinutes});
}

class UserStats {
  final double totalPoints;
  final int level;
  final double progress;
  final double pointsToNext;
  final double dailyPoints;
  final int dailyMinutes;
  final int currentStreak;

  UserStats({
    required this.totalPoints,
    required this.level,
    required this.progress,
    required this.pointsToNext,
    required this.dailyPoints,
    required this.dailyMinutes,
    required this.currentStreak,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalPoints: (json['totalPoints'] as num).toDouble(),
      level: json['level'] as int,
      progress: (json['progress'] as num).toDouble(),
      pointsToNext: (json['pointsToNext'] as num).toDouble(),
      dailyPoints: (json['dailyPoints'] as num).toDouble(),
      dailyMinutes: json['dailyMinutes'] as int,
      currentStreak: json['currentStreak'] as int,
    );
  }
}

class DailyAgg {
  final double totalPoints;
  final int totalMinutes;
  final int sessionCount;
  
  DailyAgg({required this.totalPoints, required this.totalMinutes, required this.sessionCount});
}

// Global Providers

const double CAMPUS_LAT = 36.5639;
const double CAMPUS_LON = 136.6845;
const double CAMPUS_RADIUS_METERS = 500.0;

final sessionProvider = StateProvider<Session?>((ref) => null);
final locationBonusProvider = StateProvider<LocationBonus>((ref) => LocationBonus.none);

final userStatsProvider = FutureProvider<UserStats>((ref) async {
  try {
    final data = await DatabaseHelper().getUserStats();
    return UserStats.fromJson(data);
  } catch (e) {
    print("Stats Error: $e");
    return UserStats(totalPoints: 0, level: 1, progress: 0, pointsToNext: 100, dailyPoints: 0, dailyMinutes: 0, currentStreak: 0);
  }
});

final dailyAggProvider = FutureProvider<DailyAgg>((ref) async {
  try {
    final data = await DatabaseHelper().getDailyAgg();
    return DailyAgg(
      totalPoints: (data['totalPoints'] as num?)?.toDouble() ?? 0.0,
      totalMinutes: (data['totalMinutes'] as num?)?.toInt() ?? 0,
      sessionCount: 0
    );
  } catch (e) { return DailyAgg(totalPoints: 0, totalMinutes: 0, sessionCount: 0); }
});

final historyProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await DatabaseHelper().getSessions();
});

final weeklyAggProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await DatabaseHelper().getWeeklyAgg();
});

enum LocationBonus { none, campus, home }

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
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(path: '/now', builder: (context, state) => const NowScreen()),
    GoRoute(path: '/finish', builder: (context, state) => const FinishScreen()),
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
      title: 'DaigakuAPP v2',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo
          brightness: Brightness.light,
          primary: const Color(0xFF4F46E5),
          secondary: const Color(0xFFEC4899), // Pink
        ),
        textTheme: Typography.material2021().black,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      ),
      routerConfig: _router,
    );
  }
}

// -----------------------------------------------------------------------------
// 3. Reusable UI Components (Glassmorphism)
// -----------------------------------------------------------------------------

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? height;

  const GlassCard({super.key, required this.child, this.padding, this.height});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class PremiumBackground extends StatelessWidget {
  final Widget child;
  const PremiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient Mesh
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF818CF8).withOpacity(0.3),
              boxShadow: [BoxShadow(blurRadius: 100, color: const Color(0xFF818CF8).withOpacity(0.3))],
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF472B6).withOpacity(0.2),
              boxShadow: [BoxShadow(blurRadius: 100, color: const Color(0xFFF472B6).withOpacity(0.2))],
            ),
          ),
        ),
        // Content
        Positioned.fill(child: child),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 4. Screens
// -----------------------------------------------------------------------------

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final historyAsync = ref.watch(historyProvider);
    final weeklyAsync = ref.watch(weeklyAggProvider);
    // final bonus = ref.watch(locationBonusProvider); // Consumed in specific widget

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
                    
                    const SizedBox(height: 24),

                    // Main Stats Card
                    statsAsync.when(
                      data: (stats) => GlassCard(
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
                            const SizedBox(height: 20),
                            // Progress Bar
                            ClipRRect(
                               borderRadius: BorderRadius.circular(10),
                               child: LinearProgressIndicator(value: stats.progress, minHeight: 8, backgroundColor: Colors.grey.withOpacity(0.1), color: const Color(0xFF4F46E5)),
                            ),
                            const SizedBox(height: 8),
                            Align(alignment: Alignment.centerRight, child: Text("あと ${stats.pointsToNext.toInt()} XP でレベルアップ", style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
                            
                            const Divider(height: 32),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                 _Metric(label: "今日のポイント", value: "${stats.dailyPoints.toInt()}"),
                                 _Metric(label: "集中時間(分)", value: "${stats.dailyMinutes}"),
                              ],
                            )
                          ],
                        ),
                      ),
                      loading: () => const GlassCard(child: SizedBox(height: 150, child: Center(child: CircularProgressIndicator()))),
                      error: (e, _) => const SizedBox(),
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 16),
                    
                    // Weekly Chart
                    GlassCard(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("週間アクティビティ", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 120,
                            child: weeklyAsync.when(
                              data: (data) => BarChart(
                                BarChartData(
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) {
                                       if (val.toInt() >= 0 && val.toInt() < data.length) {
                                         return Padding(padding: const EdgeInsets.only(top: 8), child: Text(data[val.toInt()]['day'].toString().substring(8), style: const TextStyle(fontSize: 10, color: Colors.grey)));
                                       }
                                       return const SizedBox();
                                    })),
                                  ),
                                  gridData: FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  barGroups: data.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: (e.value['points'] as num).toDouble(), color: const Color(0xFF6366F1), width: 12, borderRadius: BorderRadius.circular(4))])).toList(),
                                )
                              ),
                              loading: () => const SizedBox(),
                              error: (_,__) => const SizedBox(),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0, delay: 100.ms),

                    const SizedBox(height: 24),
                    
                    // Calendar Button (Header)
                    GlassCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        onTap: () {
                          ref.read(hapticsProvider.notifier).lightImpact();
                          context.push('/calendar');
                        },
                        leading: Container(
                           padding: const EdgeInsets.all(8),
                           decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                           child: const Icon(Icons.calendar_month, color: Colors.purple),
                        ),
                        title: const Text("学習カレンダー", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("月ごとの記録を確認"),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ).animate().fadeIn().slideX(),
                    
                    const SizedBox(height: 16),

                    const Align(alignment: Alignment.centerLeft, child: Text("最近の履歴", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
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
                       child: GlassCard(
                         padding: const EdgeInsets.all(16),
                         child: Row(
                           children: [
                             Container(
                               padding: const EdgeInsets.all(10),
                               decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                               child: const Icon(Icons.check_circle, color: Color(0xFF4F46E5), size: 20),
                             ),
                             const SizedBox(width: 16),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(s['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                   Text("${s['minutes']} 分 • ${s['points']} pts", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                 ],
                               ),
                             ),
                             IconButton(icon: const Icon(Icons.more_horiz), onPressed: () => _editSession(context, s, ref)),
                           ],
                         ),
                       ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(),
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
            
            ref.read(sessionProvider.notifier).state = Session(startAt: DateTime.now());
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
  const _Metric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(children:[Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]))]);
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
                           child: const Text("DaigakuAPP 実行中...", style: TextStyle(color: Colors.white38, fontSize: 12)),
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
           )
        ],
      ),
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

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _confetti.play();
    _loadSuggestions();
  }
  
  void _loadSuggestions() async {
     final s = await DatabaseHelper().getSuggestions();
     setState(() => _suggestions = s);
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _finish([String? nodeId]) async {
     ref.read(hapticsProvider.notifier).mediumImpact();
     final session = ref.read(sessionProvider);
     if (session == null) return;
     
     final mins = session.durationMinutes ?? 0;
     final title = _titleCtrl.text;
     final draftTitle = title.isEmpty ? "(No Title)" : title;
     
     await DatabaseHelper().insertSession(
       startAt: session.startAt,
       minutes: session.durationMinutes ?? 0,
       draftTitle: draftTitle,
       nodeId: nodeId,
       isOnCampus: bonus == LocationBonus.campus, // Legacy field, maybe update DB? For now map properly
       // TODO: Add support for Home Bonus in DB points calculation if needed
     );
     
     ref.refresh(historyProvider);
     ref.refresh(userStatsProvider);
     ref.refresh(dailyAggProvider);
     
     // Show Notification
     showNotification("セッション記録完了！", "お疲れ様！ $mins 分間の集中を記録しました。");

     if (mounted) context.go('/');
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
                  const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  const SizedBox(height: 24),
                  Text("お疲れ様でした！", style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("$mins 分間集中しました。", style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
                  
                  const SizedBox(height: 40),
                  const Align(alignment: Alignment.centerLeft, child: Text("何をしていましたか？", style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _suggestions.map((s) => ActionChip(
                      elevation: 0,
                      backgroundColor: Colors.white,
                      label: Text(s['title']),
                      onPressed: () {
                         _titleCtrl.text = s['title'];
                         _finish(s['id']);
                      },
                    )).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      hintText: "タスク名を入力...",
                      prefixIcon: const Icon(Icons.edit)
                    ),
                  ),
                  
                  const Spacer(),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _finish(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      child: const Text("記録する", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
