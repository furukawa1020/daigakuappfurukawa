import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

// -----------------------------------------------------------------------------
// 1. Models & State
// -----------------------------------------------------------------------------

class Session {
  final String? id;
  final DateTime startAt;
  final int? durationMinutes;

  Session({this.id, required this.startAt, this.durationMinutes});
}

// Models
class DailyAgg {
  final double totalPoints;
  final int totalMinutes;
  final int sessionCount;
  
  DailyAgg({required this.totalPoints, required this.totalMinutes, required this.sessionCount});
  
  factory DailyAgg.fromJson(Map<String, dynamic> json) {
    return DailyAgg(
      totalPoints: (json['totalPoints'] as num?)?.toDouble() ?? 0.0,
      totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? 0,
      sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
    );
  }
}

// Global Providers

String get baseUrl {
  if (kIsWeb) return 'http://localhost:8080';
  // if (Platform.isAndroid) return 'http://10.0.2.2:8080'; 
  if (Platform.isAndroid) return 'http://192.168.68.57:8080'; // Physical Device + Emulator Support
  return 'http://localhost:8080';
}

// Geofencing Configuration (Kanazawa University Natural Science Building No. 2)
const double CAMPUS_LAT = 36.5639;
const double CAMPUS_LON = 136.6845;
const double CAMPUS_RADIUS_METERS = 500.0; // 500m radius

final sessionProvider = StateProvider<Session?>((ref) => null);
final isOnCampusProvider = StateProvider<bool>((ref) => false);

Future<bool> checkIfOnCampus() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double distanceInMeters = Geolocator.distanceBetween(
      CAMPUS_LAT,
      CAMPUS_LON,
      position.latitude,
      position.longitude,
    );

    return distanceInMeters <= CAMPUS_RADIUS_METERS;
  } catch (e) {
    print("Geolocation Error: $e");
    return false;
  }
}

final dailyAggProvider = FutureProvider<DailyAgg>((ref) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/api/aggs/daily'));
    if (response.statusCode == 200) {
      return DailyAgg.fromJson(jsonDecode(response.body));
    }
  } catch (e) {
    print("Fetch Stats Error: $e");
  }
  return DailyAgg(totalPoints: 0, totalMinutes: 0, sessionCount: 0);
});

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

final userStatsProvider = FutureProvider<UserStats>((ref) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/api/user/stats'));
    if (response.statusCode == 200) {
      return UserStats.fromJson(jsonDecode(response.body));
    }
  } catch (e) { print("UserStats Error: $e"); }
  return UserStats(totalPoints: 0, level: 1, progress: 0, pointsToNext: 100, dailyPoints: 0, dailyMinutes: 0, currentStreak: 0);
});

final historyProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/api/sessions'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
  } catch(e) { print("History Error: $e"); }
  return [];
});

// -----------------------------------------------------------------------------
// 2. Navigation
// -----------------------------------------------------------------------------

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/now',
      builder: (context, state) => const NowScreen(),
    ),
    GoRoute(
      path: '/finish',
      builder: (context, state) => const FinishScreen(),
    ),
  ],
);

// -----------------------------------------------------------------------------
// 3. UI
// -----------------------------------------------------------------------------

void main() {
  runApp(const ProviderScope(child: DaigakuAPPApp()));
}

class DaigakuAPPApp extends StatelessWidget {
  const DaigakuAPPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DaigakuAPP v2',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

// ...

final weeklyAggProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/api/aggs/weekly'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
  } catch(e) { print("Weekly Error: $e"); }
  return [];
});

// ...

// --- Screens ---

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _toggleCampus(bool isOn, WidgetRef ref) async {
    try {
       await http.post(
         Uri.parse('$baseUrl/api/context'),
         body: jsonEncode({"isOnCampus": isOn})
       );
       ref.refresh(dailyAggProvider); // Refresh stats just in case
    } catch(e) { print(e); }
  }

  Future<void> _editSession(BuildContext context, Map<String, dynamic> session, WidgetRef ref) async {
    final titleCtrl = TextEditingController(text: session['title']);
    if (!context.mounted) return;
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Session"),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: "Task Name"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () async {
               // Delete Logic
               final confirm = await showDialog<bool>(
                 context: ctx,
                 builder: (c) => AlertDialog(
                   title: const Text("Delete?"), 
                   actions: [
                     TextButton(onPressed: ()=>Navigator.pop(c,false), child: const Text("Cancel")),
                     TextButton(onPressed: ()=>Navigator.pop(c,true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                   ]
                 )
               );
               if (confirm == true) {
                  try {
                    final res = await http.delete(Uri.parse('$baseUrl/api/sessions/${session['id']}'));
                    if (res.statusCode != 200) throw "Status ${res.statusCode}";
                    
                    ref.refresh(historyProvider);
                    ref.refresh(dailyAggProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch(e) { 
                     print(e);
                     if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
               }
            }, 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
          FilledButton(
            onPressed: () async {
              // Edit Logic
              try {
                final url = Uri.parse('$baseUrl/api/sessions/${session['id']}');
                print("PUT $url");
                final res = await http.put(
                  url,
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({"draftTitle": titleCtrl.text})
                );
                
                if (res.statusCode != 200) {
                   throw "Server Error: ${res.statusCode} ${res.body}";
                }
                
                ref.refresh(historyProvider);
                if (ctx.mounted) {
                   Navigator.pop(ctx);
                   ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Updated successfully!")));
                }
              } catch(e) { 
                print(e); 
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Edit Failed: $e"), backgroundColor: Colors.red));
              }
            }, 
            child: const Text("Save")
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final weeklyAsync = ref.watch(weeklyAggProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('DaigakuAPP v2')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.refresh(userStatsProvider);
          ref.refresh(weeklyAggProvider);
          ref.refresh(historyProvider);
        },
        child: const Icon(Icons.refresh),
      ),
      body: Center(
        child: Column(
          children: [
             const SizedBox(height: 16),
             // Weekly Chart
             Container(
               height: 150,
               padding: const EdgeInsets.symmetric(horizontal: 16),
               child: weeklyAsync.when(
                 data: (data) => BarChart(
                   BarChartData(
                     titlesData: FlTitlesData(
                       leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                       topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                       bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) {
                          if (val.toInt() >= 0 && val.toInt() < data.length) {
                            return Text(data[val.toInt()]['day'].toString().substring(8), style: const TextStyle(fontSize: 10)); // return DD
                          }
                          return const Text("");
                       })),
                     ),
                     borderData: FlBorderData(show: false),
                     gridData: FlGridData(show: false),
                     barGroups: data.asMap().entries.map((e) {
                       final idx = e.key;
                       final item = e.value;
                       final pts = (item['points'] as num).toDouble();
                       return BarChartGroupData(x: idx, barRods: [BarChartRodData(toY: pts, color: Theme.of(context).primaryColor, width: 16)]);
                     }).toList(),
                   )
                 ),
                 loading: () => const Center(child: Text("Loading Chart...")),
                 error: (_,__) => const SizedBox(),
               )
             ),
             
             // Stats Card (Today)
             // Stats Card (Gamification)
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: statsAsync.when(
                  data: (stats) => Column(
                    children: [
                       // Streak Badge
                       if (stats.currentStreak > 0)
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                           decoration: BoxDecoration(
                             gradient: LinearGradient(
                               colors: [Colors.orange.shade400, Colors.red.shade400],
                               begin: Alignment.centerLeft,
                               end: Alignment.centerRight,
                             ),
                             borderRadius: BorderRadius.circular(20),
                           ),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               const Text("🔥", style: TextStyle(fontSize: 20)),
                               const SizedBox(width: 8),
                               Text(
                                 "${stats.currentStreak} Day Streak", 
                                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                               ),
                             ],
                           ),
                         ),
                       SizedBox(height: stats.currentStreak > 0 ? 16 : 0),
                       Text("LEVEL ${stats.level}", style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                       const SizedBox(height: 16),
                       LinearProgressIndicator(
                         value: stats.progress, 
                         minHeight: 12, 
                         borderRadius: BorderRadius.circular(6),
                         backgroundColor: Colors.grey[200],
                       ),
                       const SizedBox(height: 8),
                       Text("${stats.pointsToNext.toStringAsFixed(0)} XP to Next Level", style: Theme.of(context).textTheme.bodySmall),
                       const SizedBox(height: 24),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceAround,
                         children: [
                           Column(children: [
                             Text("${stats.dailyPoints.toStringAsFixed(0)}", style: Theme.of(context).textTheme.titleLarge),
                             const Text("Today's Pts", style: TextStyle(fontSize: 10, color: Colors.grey))
                           ]),
                           Column(children: [
                             Text("${stats.dailyMinutes}", style: Theme.of(context).textTheme.titleLarge),
                             const Text("Minutes", style: TextStyle(fontSize: 10, color: Colors.grey))
                           ]),
                           Column(children: [
                             Text("${stats.totalPoints.toStringAsFixed(0)}", style: Theme.of(context).textTheme.titleLarge),
                             const Text("Total Pts", style: TextStyle(fontSize: 10, color: Colors.grey))
                           ]),
                         ],
                       )
                    ],
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => const Text("Failed to load stats"),
                ),
              ),
            ),
            
            
            // Real Location Status
            Consumer(builder: (context, ref, _) {
              final isOnCampus = ref.watch(isOnCampusProvider);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOnCampus ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isOnCampus ? Colors.green : Colors.grey),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOnCampus ? Icons.school : Icons.home,
                      color: isOnCampus ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnCampus ? "📍 On Campus (Kakuma)" : "📍 Off Campus",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOnCampus ? Colors.green.shade700 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            const Divider(),
            
            // History List
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Recent History", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final historyAsync = ref.watch(historyProvider);
                  return historyAsync.when(
                    data: (sessions) => ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (ctx, i) {
                        final s = sessions[i];
                        return ListTile(
                          title: Text(s['title']),
                          subtitle: Text("${s['minutes']} min • ${s['points']} pts"),
                        leading: const Icon(Icons.check_circle_outline),
                        onTap: () => _editSession(context, s, ref),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                               DateTime.parse(s['startAt']).toLocal().toString().substring(11, 16),
                               style: const TextStyle(fontSize: 12, color: Colors.grey)
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.blueGrey),
                              onPressed: () async {
                                  // Delete
                                  try {
                                    final id = s['id'];
                                    final url = Uri.parse('$baseUrl/api/sessions/$id');
                                    final res = await http.delete(url, headers: {'Content-Type': 'application/json'});
                                    if (res.statusCode == 200) {
                                      ref.refresh(historyProvider);
                                      ref.refresh(dailyAggProvider);
                                      ref.refresh(userStatsProvider);
                                    }
                                  } catch (e) { print(e); }
                              },
                            )
                          ],
                        ),
                      );
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const SizedBox(),
                  );
                },
              ),
            ),

            FilledButton.icon(
              onPressed: () async {
                // Check GPS location first
                bool onCampus = await checkIfOnCampus();
                ref.read(isOnCampusProvider.notifier).state = onCampus;
                
                // Start Unspecified Session
                ref.read(sessionProvider.notifier).state = Session(startAt: DateTime.now());
                if (context.mounted) context.push('/now');
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text("DO NOW"),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class NowScreen extends ConsumerStatefulWidget {
  const NowScreen({super.key});

  @override
  ConsumerState<NowScreen> createState() => _NowScreenState();
}

class _NowScreenState extends ConsumerState<NowScreen> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionProvider);
    if (session == null) {
      // Logic error recovery
      _elapsed = Duration.zero;
    } else {
      _elapsed = DateTime.now().difference(session.startAt);
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final s = ref.read(sessionProvider);
      if (s != null) {
        setState(() {
          _elapsed = DateTime.now().difference(s.startAt);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds % 60;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("FOCUSING", style: TextStyle(letterSpacing: 4, color: Colors.grey[600])),
            const SizedBox(height: 48),
            // Timer Ring Visualization Mock
            Stack(
              alignment: Alignment.center,
              children: [
                 SizedBox(
                   width: 300, height: 300,
                   child: CircularProgressIndicator(
                     value: (minutes % 90) / 90.0, 
                     strokeWidth: 20,
                     backgroundColor: Colors.grey[200],
                   ),
                 ),
                 Column(
                   children: [
                     Text("${minutes.toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 96, fontWeight: FontWeight.w200)),
                     Text("${seconds.toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 32, color: Colors.grey)),
                   ],
                 )
              ],
            ),
            const SizedBox(height: 64),
            OutlinedButton.icon(
              onPressed: () {
                // Update session state with duration
                final s = ref.read(sessionProvider);
                if (s != null) {
                  ref.read(sessionProvider.notifier).state = Session(
                    id: s.id,
                    startAt: s.startAt,
                    durationMinutes: minutes == 0 ? 1 : minutes // Min 1 min
                  );
                }
                context.pushReplacement('/finish');
              },
              icon: const Icon(Icons.check, size: 32),
              label: const Text("COMPLETE"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                shape: const StadiumBorder()
              ),
            )
          ],
        ),
      ),
    );
  }
}

class FinishScreen extends ConsumerStatefulWidget {
  const FinishScreen({super.key});

  @override
  ConsumerState<FinishScreen> createState() => _FinishScreenState();
}

class _FinishScreenState extends ConsumerState<FinishScreen> {
  final TextEditingController _titleController = TextEditingController();
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  Future<void> _fetchSuggestions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/nodes/suggestions'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _suggestions = data.map((e) => {"id": e['id'], "title": e['title']}).toList();
        });
      }
    } catch(e) { print("Error fetching suggestions: $e"); }
  }

  Future<void> _submit({String? selectedNodeId}) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    
    setState(() => _isSubmitting = true);

    try {
      final minutes = DateTime.now().difference(session.startAt).inMinutes;
      final isOnCampus = ref.read(isOnCampusProvider);
      
      final url = Uri.parse('$baseUrl/api/sessions'); 
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "startAt": session.startAt.toIso8601String(),
          "minutes": minutes,
          "draftTitle": _titleController.text.isEmpty ? "(No Title)" : _titleController.text,
          "nodeId": selectedNodeId,
          "isOnCampus": isOnCampus,
        }),
      );
      
      if (response.statusCode == 201) {
        ref.refresh(dailyAggProvider);
        ref.refresh(userStatsProvider);
        ref.refresh(historyProvider); // Refresh history
        if (mounted) context.go('/');
      } else {
        if (mounted) context.go('/');
      }
    } catch (e) {
      print("Network Error: $e");
       if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(sessionProvider);
    final mins = session?.durationMinutes ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text("Attribute Result")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("$mins Minutes Completed!", style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 32),
            const Text("What did you do?"),
            const SizedBox(height: 16),
            
            // Suggestions Chips
            Wrap(
              spacing: 8,
              children: _suggestions.map((s) => ActionChip(
                label: Text(s['title']),
                onPressed: () {
                  _titleController.text = s['title'];
                  // Auto-submit? Or just fill? Let's direct submit for speed.
                  _submit(selectedNodeId: s['id']);
                },
              )).toList(),
            ),
            
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Task Name (One-liner)',
                hintText: 'e.g. Studied Go Backend'
              ),
            ),
            const Spacer(),
            FilledButton(
               onPressed: _isSubmitting ? null : () => _submit(),
               child: _isSubmitting ? const CircularProgressIndicator() : const Text("RECORD RESULT"),
               style: FilledButton.styleFrom(padding: const EdgeInsets.all(20)),
            )
          ],
        ),
      ),
    );
  }
}
