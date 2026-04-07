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
import 'services/achievement_service.dart';
import 'moko_collection_screen.dart';
import 'shop_screen.dart';
import 'achievements_gallery_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'widgets/moko_card.dart';
import 'services/quotes.dart';
import 'services/theme_service.dart';
import 'widgets/task_roulette_dialog.dart';
import 'widgets/visual_timer.dart';
import 'widgets/focus_sound_player.dart';
import 'widgets/pet_display.dart';
import 'widgets/premium_background.dart';
import 'widgets/stat_item.dart';
import 'widgets/quick_start_button.dart';
import 'stats_screen.dart';
import 'tree_screen.dart';
import 'moko_dictionary_screen.dart';
import 'screens/social_screen.dart';
import 'widgets/live_feed_widget.dart';
import 'widgets/raid_hp_bar.dart';
import 'widgets/skill_action_button.dart';
import 'widgets/sharpness_gauge.dart';
import 'widgets/quick_item_pouch.dart';
import 'widgets/vitality_hud.dart';

import 'services/native_command_listener.dart';
import 'services/api_service.dart';
import 'services/action_cable_service.dart';
import 'widgets/chat_overlay.dart';
import 'widgets/party_widget.dart';
import 'screens/boss_archive_screen.dart';
import 'screens/quest_board_screen.dart';
import 'screens/blacksmith_screen.dart';
import 'screens/canteen_screen.dart';
import 'screens/combination_screen.dart';

// -----------------------------------------------------------------------------
// 1. Models & State
// -----------------------------------------------------------------------------

import 'services/notification_service.dart';

// Models and Providers moved to state/app_state.dart


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
    GoRoute(path: '/achievements', builder: (context, state) => const AchievementsGalleryScreen()),
    GoRoute(path: '/shop', builder: (context, state) => const ShopScreen()),
    GoRoute(path: '/stats', builder: (context, state) => const StatsScreen()),
    GoRoute(path: '/tree', builder: (context, state) => const TreeScreen()),
    GoRoute(path: '/server_dictionary', builder: (context, state) => const MokoDictionaryScreen()),
    GoRoute(path: '/social', builder: (context, state) => const SocialScreen()),
    GoRoute(path: '/quest_board', builder: (context, state) => const QuestBoardScreen()),
    GoRoute(path: '/blacksmith', builder: (context, state) => const BlacksmithScreen()),
    GoRoute(path: '/canteen', builder: (context, state) => const CanteenScreen()),
    GoRoute(path: '/combination', builder: (context, state) => const CombinationScreen()),
  ],
);

void main() async { // Async main
  WidgetsFlutterBinding.ensureInitialized(); // Ensure binding
  await NotificationService().init(); // Init notifications

  // Schedule daily 9 PM summary (fire-and-forget on startup)
  DatabaseHelper().getUserStats().then((stats) {
    NotificationService().scheduleDailySummary(
      todayXP: ((stats['dailyPoints'] as double?) ?? 0.0).toInt(),
      streak: (stats['currentStreak'] as int?) ?? 0,
    );
  });

  // ActionCable Native Bridge Init
  ApiService.getDeviceId().then((deviceId) {
    NativeCommandListener.init(deviceId);
  });

  runApp(const ProviderScope(child: DaigakuAPPApp()));
}

class DaigakuAPPApp extends ConsumerStatefulWidget {
  const DaigakuAPPApp({super.key});

  @override
  ConsumerState<DaigakuAPPApp> createState() => _DaigakuAPPAppState();
}

class _DaigakuAPPAppState extends ConsumerState<DaigakuAPPApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Schedule invitation when app goes to background
      NotificationService().scheduleMokoInvitation();
    } else if (state == AppLifecycleState.resumed) {
      // Cancel when app comes back
      NotificationService().cancelAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return MaterialApp.router(
      routerConfig: _router,
      title: 'DaigakuAPP v2',
      theme: themeNotifier.getThemeData(false),
      darkTheme: themeNotifier.getThemeData(true),
      themeMode: ThemeMode.system, 
    );
  }
}

// PremiumBackground moved to widgets/premium_background.dart

// -----------------------------------------------------------------------------
// 4. Screens
// -----------------------------------------------------------------------------

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _resetIdleTimer();
    _connectRealTime();
    _startPolling();
  }

  void _connectRealTime() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(actionCableProvider).connect();
    });
  }

  void _startPolling() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        ref.invalidate(globalRaidProvider);
        ref.invalidate(worldStatusProvider);
        ref.invalidate(partyProvider);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) _showMokoInvitation();
    });
  }

  void _showMokoInvitation() {
    ref.read(hapticsProvider.notifier).lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("ねぇ..."),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             const Icon(Icons.sentiment_neutral, size: 48, color: Color(0xFFFFB7B2)),
             const SizedBox(height: 16),
             const Text("10秒くらい止まってたけど、\n何から始めるか迷ってる？", textAlign: TextAlign.center),
             const SizedBox(height: 16),
             FilledButton(
               onPressed: () {
                 Navigator.pop(ctx);
                 ref.read(sessionProvider.notifier).state = Session(startAt: DateTime.now(), targetMinutes: 5);
                 context.push('/now');
               },
               child: const Text("とりあえず5分やる")
             ),
             const SizedBox(height: 8),
             OutlinedButton.icon(
               onPressed: () {
                 Navigator.pop(ctx);
                 showDialog(context: context, builder: (_) => const TaskRouletteDialog());
               },
               icon: const Icon(Icons.casino, size: 18),
               label: const Text("ルーレットで決める！"),
             ),
             TextButton(
               onPressed: () => Navigator.pop(ctx),
               child: const Text("ちょっと考え中")
             )
          ],
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
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

    return Listener(
      onPointerDown: (_) => _resetIdleTimer(),
      onPointerMove: (_) => _resetIdleTimer(),
      onPointerHover: (_) => _resetIdleTimer(),
      child: Scaffold(
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
                  icon: const Icon(Icons.public, color: Color(0xFF6366F1)),
                  onPressed: () {
                    ref.read(hapticsProvider.notifier).lightImpact();
                    context.push('/social');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.bar_chart, color: Colors.brown),
                  onPressed: () => context.push('/stats'),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month, color: Colors.brown),
                  onPressed: () => context.push('/calendar'),
                ),
                IconButton(
                  icon: const Icon(Icons.collections_bookmark, color: Colors.brown),
                  onPressed: () {
                    ref.read(hapticsProvider.notifier).lightImpact();
                    context.push('/collection');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.park_outlined, color: Colors.green),
                  onPressed: () {
                    ref.read(hapticsProvider.notifier).lightImpact();
                    context.push('/tree');
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
                    
                    // Daily Challenge Card (ADHD Deep Dive)
                    Consumer(builder: (context, ref, _) {
                      final challengeAsync = ref.watch(dailyChallengeProvider);
                      
                      return challengeAsync.when(
                        data: (challenge) => MokoCard(
                          color: challenge.isCompleted ? const Color(0xFFFFD700).withOpacity(0.2) : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          onTap: () {
                             ref.read(hapticsProvider.notifier).lightImpact();
                             showDialog(context: context, builder: (_) => AlertDialog(
                               title: Text(challenge.title),
                               content: Text("${challenge.description}\n\n報酬: ${challenge.bonusXP} XP"),
                               actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))]
                             ));
                          },
                          child: Row(
                            children: [
                              Icon(
                                challenge.isCompleted ? Icons.emoji_events : Icons.flag, 
                                color: challenge.isCompleted ? Colors.amber : Colors.blueGrey,
                                size: 32
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      challenge.title, 
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[800], decoration: challenge.isCompleted ? TextDecoration.lineThrough : null)
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: challenge.progress,
                                        backgroundColor: Colors.grey[200],
                                        valueColor: AlwaysStoppedAnimation<Color>(challenge.isCompleted ? Colors.amber : Colors.blueAccent),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (challenge.isCompleted)
                                const Text("CLEAR!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 12))
                              else
                                Text("${(challenge.progress * 100).toInt()}%", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        loading: () => const SizedBox(), 
                        error: (_,__) => const SizedBox(),
                      );
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
                                    SizedBox(
                                      width: 140,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: stats.progress,
                                          backgroundColor: Colors.blueAccent.withOpacity(0.1),
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                                          minHeight: 8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "あと ${(stats.pointsToNext).toInt()} XP で Level Up!",
                                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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

                    // Server Moko Discovery UI
                    GestureDetector(
                      onTap: () {
                        ref.read(hapticsProvider.notifier).heavyImpact();
                        context.push('/server_dictionary');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.purple.shade300, Colors.blue.shade300]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,4))],
                        ),
                        child: Row(
                          children: [
                            const Text("☁️", style: TextStyle(fontSize: 40)),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Moko Dictionary", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                  Text("サーバーから新しいモコの種類を確認！", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                    ),
                    
                    const SizedBox(height: 16),
                    const LiveFeedWidget(),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "さあ、始めましょう", // Let's get started
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey[800])
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      ref.read(hapticsProvider.notifier).lightImpact();
                                      showDialog(context: context, builder: (_) => const TaskRouletteDialog());
                                    },
                                    icon: const Icon(Icons.casino, size: 20, color: Colors.orange),
                                    label: const Text("迷ったらSpin", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      backgroundColor: Colors.orange.withOpacity(0.1),
                                    ),
                                  ),
                                ],
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
                                )
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
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Just 5 Min Button
          Padding(
            padding: const EdgeInsets.only(right: 20, bottom: 10),
            child: FloatingActionButton.extended(
              heroTag: 'just5min',
              elevation: 4,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFFFB7B2),
              icon: const Icon(Icons.timer_outlined),
              label: const Text("とりあえず5分", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                 ref.read(hapticsProvider.notifier).mediumImpact();
                 
                 // Start Session (Target = 5)
                 final bonus = await checkLocationBonus();
                 ref.read(locationBonusProvider.notifier).state = bonus;
                 
                 ref.read(sessionProvider.notifier).state = Session(
                   startAt: DateTime.now(),
                   targetMinutes: 5, // Just 5 Minutes Mode
                 );
                 if (context.mounted) context.push('/now');
              },
            ).animate().slideX(begin: -0.5, end: 0, delay: 200.ms).fadeIn(),
          ),

          // Main Charge Button
          HyperfocusButton(
            onComplete: () async {
                // Start Session Logic (Unlimited)
                final bonus = await checkLocationBonus();
                ref.read(locationBonusProvider.notifier).state = bonus;
                
                final selectedTask = ref.read(selectedTaskProvider);
                
                ref.read(sessionProvider.notifier).state = Session(
                  startAt: DateTime.now(), 
                  targetMinutes: null, // Unlimited
                );
                if (context.mounted) context.push('/now');
            },
          ).animate().scale(delay: 500.ms, curve: Curves.elasticOut),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      extendBody: true, // For better visual integration
    ));
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
      if (s != null) {
        final now = DateTime.now();
        final diff = now.difference(s.startAt);
        setState(() => _elapsed = diff);

        // Just 5 Minutes Mode Logic
        if (s.targetMinutes != null && diff.inMinutes >= s.targetMinutes!) {
          _timer.cancel();
          _showTimeUpDialog(context, ref);
        }
      }
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
                  
                  const SizedBox(height: 16),
                  
                  // Pet Display Card (Phase 14)
                  const PetDisplay().animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  // Currency Display (Phase 14)
                  Consumer(builder: (context, ref, _) {
                    final currencies = ref.watch(currencyProvider);
                    
                    return MokoCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text("💰", style: TextStyle(fontSize: 24)),
                              const SizedBox(height: 4),
                              Text("${currencies.mokoCoins}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const Text("コイン", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          Container(width: 1, height: 40, color: Colors.grey[300]),
                          Column(
                            children: [
                              const Text("⭐", style: TextStyle(fontSize: 24)),
                              const SizedBox(height: 4),
                              Text("${currencies.starCrystals}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const Text("スター", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          Container(width: 1, height: 40, color: Colors.grey[300]),
                          Column(
                            children: [
                              const Text("💎", style: TextStyle(fontSize: 24)),
                              const SizedBox(height: 4),
                              Text("${currencies.campusGems}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const Text("ジェム", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
                  }),
                  
                  const SizedBox(height: 16),
                  
                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.go('/collection'),
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: const Text("コレクション"),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFB5EAD7),
                            foregroundColor: Colors.brown,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.go('/achievements'),
                          icon: const Icon(Icons.workspace_premium, size: 18),
                          label: const Text("称号・勲章"),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFC7CEEA),
                            foregroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),
                  
                  const SizedBox(height: 24),

                  Expanded(
                    child: Center(
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         VisualTimer(
                           elapsed: _elapsed,
                           targetMinutes: ref.watch(sessionProvider)?.targetMinutes,
                         ).animate().fadeIn(duration: 1.seconds),
                         const SizedBox(height: 10),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                           decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                           child: Text(taskTitle ?? "DaigakuAPP 実行中...", style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                         ),
                         // Phase 45: Vitality HUD (Self-Management)
                         if (user != null)
                           VitalityHUD(
                             hp: user.hp,
                             maxHp: user.maxHp,
                             stamina: user.stamina,
                             maxStamina: user.maxStamina,
                           ),
                         const SizedBox(height: 8),
                         
                         // Phase 34: Moko Card
                         const MokoCard(),
                         
                         // Phase 37: Raid HP Bar
                         const RaidHPBar(),
                         
                         // Phase 41: Skill Action Button
                         const SkillActionButton(),
                         
                         // Phase 42: Quick Item Pouch
                         const QuickItemPouch(),
                         
                         const SizedBox(height: 12),
                         // Preparation Row
                         _buildMetaRow(context),

                         const SizedBox(height: 12),
                         // Phase 39: Party Widget
                         const PartyWidget(),
                       ],
                     ),
                   ),
                  ),
                  
                  // Focus Sound Controls
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: FocusSoundPlayer(),
                  ),
                  const SizedBox(height: 16),
                  
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

  Future<void> _showTimeUpDialog(BuildContext context, WidgetRef ref) async {
    ref.read(hapticsProvider.notifier).heavyImpact();
    
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text("5分経過！"),
          content: const Text("お疲れ様です。どうしますか？"),
          actionsAlignment: MainAxisAlignment.center,
          actionsOverflowDirection: VerticalDirection.up,
          actions: [
            // Option 3: Unlimited
            TextButton(
              onPressed: () {
                final s = ref.read(sessionProvider);
                if (s != null) {
                  ref.read(sessionProvider.notifier).state = Session(
                    id: s.id,
                    startAt: s.startAt,
                    targetMinutes: null, // Remove limit
                    moodPre: s.moodPre,
                  );
                }
                Navigator.pop(ctx);
                // Restart timer
                _timer = Timer.periodic(const Duration(seconds: 1), (_) {
                   final s = ref.read(sessionProvider);
                   if (s != null) {
                      final now = DateTime.now();
                      final diff = now.difference(s.startAt);
                      setState(() => _elapsed = diff);
                   }
                });
              }, 
              child: const Text("ゾーン突入 (制限なしで続行)")
            ),
            
            // Option 2: Extend +5
            TextButton(
              onPressed: () {
                 final s = ref.read(sessionProvider);
                 if (s != null) {
                   ref.read(sessionProvider.notifier).state = Session(
                     id: s.id,
                     startAt: s.startAt,
                     targetMinutes: (s.targetMinutes ?? 0) + 5,
                     moodPre: s.moodPre,
                   );
                 }
                 Navigator.pop(ctx);
                 // Restart timer with new check
                 _timer = Timer.periodic(const Duration(seconds: 1), (_) {
                   final s = ref.read(sessionProvider);
                   if (s != null) {
                      final now = DateTime.now();
                      final diff = now.difference(s.startAt);
                      setState(() => _elapsed = diff);
                      if (s.targetMinutes != null && diff.inMinutes >= s.targetMinutes!) {
                        _timer.cancel();
                        if (context.mounted) _showTimeUpDialog(context, ref);
                      }
                   }
                 });
              },
              child: const Text("あと5分だけ延長")
            ),
            
            // Option 1: Finish
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                
                // Finish Logic copied from build
                ref.read(hapticsProvider.notifier).heavyImpact();
                final s = ref.read(sessionProvider);
                if (s != null) {
                   int duration = _elapsed.inMinutes;
                   if (duration < 1) duration = 1;
                   ref.read(sessionProvider.notifier).state = Session(id: s.id, startAt: s.startAt, durationMinutes: duration);
                }
                if (context.mounted) context.pushReplacement('/finish');
              },
              icon: const Icon(Icons.check),
              label: const Text("終わり！ (記録して終了)", style: TextStyle(fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
              ),
            ),
          ],
        ),
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
  String? _selectedNodeId;
  int _focusRating = 3; // 1-5
  String _praiseMessage = "お疲れ様でした！";
  String _motivationalQuote = "";
  bool _isSaving = false;

  // Grade calculation
  String _gradeEmoji = "🙂";
  String _gradeLabel = "C";
  Color _gradeColor = Colors.grey;

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
    "マイペースでOK💫",
    "またやれるよ！",
    "あなたは十分がんばった",
    "焦らなくていいからね",
    "続けてるだけで偉い🌟",
  ];

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _confetti.play();
    ref.read(hapticsProvider.notifier).heavyImpact();

    final selectedTask = ref.read(selectedTaskProvider);
    final selectedNode = ref.read(selectedNodeProvider);
    if (selectedNode != null) {
      _titleCtrl.text = selectedNode.title;
      _selectedNodeId = selectedNode.id;
    } else if (selectedTask != null) {
      _titleCtrl.text = selectedTask;
    }

    _praiseMessage = _praiseMessages[Random().nextInt(_praiseMessages.length)];
    _motivationalQuote = MOTIVATIONAL_QUOTES[Random().nextInt(MOTIVATIONAL_QUOTES.length)];
    _loadSuggestions();
    _updateGrade();
  }

  void _updateGrade() {
    final session = ref.read(sessionProvider);
    final mins = session?.durationMinutes ?? 0;
    final score = mins * _focusRating;
    setState(() {
      if (score >= 180) {
        _gradeLabel = "S"; _gradeEmoji = "🌟"; _gradeColor = const Color(0xFFFFD700);
      } else if (score >= 100) {
        _gradeLabel = "A"; _gradeEmoji = "✨"; _gradeColor = Colors.green;
      } else if (score >= 50) {
        _gradeLabel = "B"; _gradeEmoji = "👍"; _gradeColor = Colors.blue;
      } else {
        _gradeLabel = "C"; _gradeEmoji = "🙂"; _gradeColor = Colors.grey;
      }
    });
  }

  Future<void> _loadSuggestions() async {
    final results = await DatabaseHelper().getSuggestions();
    if (mounted) setState(() => _suggestions = results);
  }

  @override
  void dispose() {
    _confetti.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  void _finish() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final session = ref.read(sessionProvider);
    if (session != null) {
      final title = _titleCtrl.text.isNotEmpty
          ? _titleCtrl.text
          : (_selectedNodeId != null
              ? (_suggestions.firstWhere((s) => s['id'] == _selectedNodeId,
                  orElse: () => {'title': '無題'})['title'] as String)
              : "無題のセッション");
      final mins = session.durationMinutes ?? 0;

      await DatabaseHelper().insertSession(
        draftTitle: title,
        startAt: session.startAt,
        minutes: mins,
        isOnCampus: ref.read(locationBonusProvider) == LocationBonus.campus,
        nodeId: _selectedNodeId,
        moodPre: session.moodPre,
        moodPost: session.moodPost,
        focusRating: _focusRating,
      );

      ref.refresh(userStatsProvider);
      ref.refresh(historyProvider);
      ref.refresh(dailyAggProvider);
      ref.refresh(weeklyAggProvider);

      final homeBonus = ref.read(locationBonusProvider) == LocationBonus.home;
      final newAchievements = await ref.read(achievementProvider.notifier)
          .checkAchievements(mins, session.startAt, homeBonus);

      final challengeCompleted = await DatabaseHelper().checkChallengeCompletion();
        if (challengeCompleted && mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("🎉 デイリーチャレンジ達成！"),
              content: const Text("ボーナス 100 XPを獲得しました！"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("やったね！"),
                ),
              ],
            ),
          );
          ref.refresh(dailyChallengeProvider);
        }

        // 3. Mark Node as Completed if applicable
        if (_selectedNodeId != null) {
          await DatabaseHelper().completeNode(_selectedNodeId!);
          // Bonus Coins for completing a planned task
          await ref.read(currencyProvider.notifier).addMokoCoins(10);
        }

        // 4. Reset Providers
        ref.read(selectedNodeProvider.notifier).state = null;
        ref.read(selectedTaskProvider.notifier).state = null;

      final currencyService = ref.read(currencyProvider.notifier);
      int earnedCoins = (mins / 10).floor();
      int earnedGems = 0;
      int earnedCrystals = 0;
      if (earnedCoins > 0) await currencyService.addMokoCoins(earnedCoins);
      if (ref.read(locationBonusProvider) == LocationBonus.campus) {
        earnedGems = (mins / 20).floor();
        if (earnedGems > 0) await currencyService.addCampusGems(earnedGems);
      }
      if (mins >= 45) {
        earnedCrystals = 1;
        await currencyService.addStarCrystals(1);
      }

      if (mounted) {
        if (newAchievements.isNotEmpty) {
          _showAchievementDialog(context, newAchievements, ref);
        }
        String rewardMsg = "";
        if (earnedCoins > 0) rewardMsg += " +${earnedCoins}コイン";
        if (earnedGems > 0) rewardMsg += " +${earnedGems}ジェム";
        if (earnedCrystals > 0) rewardMsg += " +${earnedCrystals}スター";
        await showNotification("セッション完了", "お疲れ様でした！ ${mins}分間の集中を記録しました。$rewardMsg");

        if (mounted && (earnedCoins > 0 || earnedGems > 0 || earnedCrystals > 0)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("報酬獲得！$rewardMsg"),
            backgroundColor: Colors.amber[700],
            behavior: SnackBarBehavior.floating,
          ));
        }
        if (context.canPop()) context.pop();
        context.go('/');
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(sessionProvider);
    final mins = session?.durationMinutes ?? 0;
    final worldStatus = ref.watch(worldStatusProvider).asData?.value;
    final raidBuff = worldStatus?.raidBuff ?? 1.0;
    
    final previewXP = (30.0 * mins * (_focusRating / 3.0) *
        (ref.read(locationBonusProvider) == LocationBonus.campus ? 1.5 : 1.0) * raidBuff).toStringAsFixed(0);

    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              colors: const [Colors.blue, Colors.pink, Colors.orange],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // ── Grade Card ─────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _gradeColor.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFFB5EAD7), size: 64)
                            .animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                        const SizedBox(height: 12),
                        Text(
                          _praiseMessage,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text("$mins分間の集中", style: TextStyle(color: Colors.grey[500])),

                        const SizedBox(height: 20),
                        // Grade Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_gradeEmoji, style: const TextStyle(fontSize: 40))
                                .animate().scale(curve: Curves.elasticOut, duration: 600.ms),
                            const SizedBox(width: 12),
                            Text(
                              "Grade $_gradeLabel",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: _gradeColor,
                              ),
                            ).animate().fadeIn().slideX(begin: 0.2, end: 0),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "+$previewXP XP（予定）",
                          style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 16),
                  
                  // ── Phase 37: Global Raid Damage Card ──────────────────────
                  Consumer(builder: (context, ref, _) {
                    final raid = ref.watch(globalRaidProvider).asData?.value;
                    if (raid == null) return const SizedBox.shrink();
                    
                    final damage = mins * 10;
                    
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 10)],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt, color: Colors.redAccent, size: 32)
                            .animate(onPlay: (c) => c.repeat()).shake(hz: 3, duration: 1.seconds),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "GLOBAL RAID DAMAGE",
                                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                ),
                                Text(
                                  "ボスに $damage ダメージ！",
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Text("⚔️", style: const TextStyle(fontSize: 24))
                            .animate().scale(delay: 500.ms, curve: Curves.elasticOut),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2, end: 0);
                  }),

                  const SizedBox(height: 16),
                  
                  // ── Motivational Quote ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "\"$_motivationalQuote\"",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontFamily: 'serif',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 20),

                  // ── Focus Rating ────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("集中度はどうでしたか？", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(5, (i) {
                            final val = i + 1;
                            final isSelected = _focusRating == val;
                            return GestureDetector(
                              onTap: () {
                                ref.read(hapticsProvider.notifier).lightImpact();
                                setState(() => _focusRating = val);
                                _updateGrade();
                              },
                              child: AnimatedContainer(
                                duration: 200.ms,
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? const Color(0xFFFFB7B2) : Colors.grey[100],
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFFF9AA2) : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    ["😫", "😔", "😐", "🙂", "😃"][i],
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            ["かなりしんどかった", "やや集中できた", "普通に集中", "よく集中できた！", "超ゾーン状態！🔥"][_focusRating - 1],
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 20),

                  // ── Post-session Mood ──────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("今の気分は？", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Consumer(builder: (context, ref, _) {
                          final sess = ref.watch(sessionProvider);
                          final moods = ['😃', '🙂', '😐', '😔', '😫'];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: moods.map((m) => GestureDetector(
                              onTap: () {
                                ref.read(hapticsProvider.notifier).lightImpact();
                                ref.read(sessionProvider.notifier).state = Session(
                                  id: sess?.id, startAt: sess?.startAt ?? DateTime.now(),
                                  durationMinutes: sess?.durationMinutes,
                                  moodPre: sess?.moodPre, moodPost: m,
                                );
                              },
                              child: AnimatedContainer(
                                duration: 200.ms,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: sess?.moodPost == m ? const Color(0xFFC7CEEA).withOpacity(0.4) : Colors.grey[50],
                                  shape: BoxShape.circle,
                                  border: sess?.moodPost == m ? Border.all(color: const Color(0xFFC7CEEA), width: 2) : null,
                                ),
                                child: Text(m, style: const TextStyle(fontSize: 24)),
                              ),
                            )).toList(),
                          );
                        }),
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 20),

                  // ── Title Input + Suggestions ──────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("何をやりましたか？", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _titleCtrl,
                          onChanged: (_) => setState(() => _selectedNodeId = null),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFFFF5F6),
                            hintText: "タスク名を入力...",
                            prefixIcon: const Icon(Icons.edit_note, color: Color(0xFFFFB7B2)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        if (_suggestions.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text("最近のタスクから選択：", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _suggestions.take(8).map((s) {
                              final isSelected = _selectedNodeId == s['id'];
                              return GestureDetector(
                                onTap: () {
                                  ref.read(hapticsProvider.notifier).lightImpact();
                                  setState(() {
                                    _selectedNodeId = s['id'];
                                    _titleCtrl.text = s['title'];
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: 200.ms,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFB5EAD7) : const Color(0xFFE2F0CB),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? Colors.green.shade300 : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    s['title'] as String,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 24),

                  // ── Share Button ────────────────────────────────
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final task = _titleCtrl.text.isNotEmpty ? _titleCtrl.text : "集中";
                        final mins = ref.read(sessionProvider)?.durationMinutes ?? 0;
                        final text = "🎓 #DaigakuAPP で $mins分間 $task に集中しました！\n"
                            "🔥 評価: $_gradeLabel $_gradeEmoji\n"
                            "あなたも一緒にモコモコしませんか？\n"
                            "https://github.com/furukawa1020/daigakuappfurukawa";
                        Share.share(text);
                      },
                      icon: const Icon(Icons.share, size: 18, color: Colors.grey),
                      label: const Text("成果をシェアして応援！", style: TextStyle(color: Colors.grey)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ).animate().fadeIn(delay: 250.ms),

                  const SizedBox(height: 16),

                  // ── Save Button ────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB7B2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: _isSaving ? null : _finish,
                      child: _isSaving
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text("記録して終了 🎉", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
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
// ---------------------------------------------------------------------------
// HELPERS
// ---------------------------------------------------------------------------

/// Top-level shortcut so FinishScreen can call without storing a service reference.
Future<void> showNotification(String title, String body) async {
  await NotificationService().showNotification(title, body);
}

/// Achievement celebration dialog — called from FinishScreen._finish()
void _showAchievementDialog(
  BuildContext context,
  List<Achievement> achievements,
  WidgetRef ref,
) {
  ref.read(hapticsProvider.notifier).heavyImpact();

  showDialog(
    context: context,
    builder: (ctx) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 24)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "🏆 バッジ獲得！",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              ...achievements.map((a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(a.icon, size: 32, color: a.color)
                        .animate().scale(curve: Curves.elasticOut, duration: 600.ms),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        a.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 20),
              const Text(
                "新しい実績をアンロックしました！",
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("やったー！🎉", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ).animate().scale(curve: Curves.elasticOut, duration: 800.ms).fadeIn(),
      ),
    ),
  );
}
