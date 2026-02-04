import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

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
import 'dart:io';
import 'package:flutter/foundation.dart';

String get baseUrl {
  if (kIsWeb) return 'http://localhost:8080';
  if (Platform.isAndroid) return 'http://192.168.68.57:8080'; // LAN IP for Physical Device
  return 'http://localhost:8080';
}

final sessionProvider = StateProvider<Session?>((ref) => null);

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
  runApp(const ProviderScope(child: DaigakuOSApp()));
}

class DaigakuOSApp extends StatelessWidget {
  const DaigakuOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DaigakuOS v2',
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
                final res = await http.put(
                  Uri.parse('$baseUrl/api/sessions/${session['id']}'),
                  body: jsonEncode({"draftTitle": titleCtrl.text})
                );
                if (res.statusCode != 200) throw "Status ${res.statusCode}";
                
                ref.refresh(historyProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch(e) { 
                print(e); 
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Error: $e")));
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
    final aggAsync = ref.watch(dailyAggProvider);
    final weeklyAsync = ref.watch(weeklyAggProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('DaigakuOS v2')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.refresh(dailyAggProvider);
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
             SizedBox(
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
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: aggAsync.when(
                  data: (agg) => Column(
                    children: [
                       Text("Today's Output", style: Theme.of(context).textTheme.labelLarge),
                       const SizedBox(height: 8),
                       Text("${agg.totalPoints.toStringAsFixed(1)} Pts", style: Theme.of(context).textTheme.displayMedium),
                       Text("${agg.totalMinutes} min / ${agg.sessionCount} sessions", style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => const Text("Failed to load stats"),
                ),
              ),
            ),
            
            // Simulation Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Mock Location: "),
                Switch(
                  value: true, 
                  onChanged: (val) => _toggleCampus(val, ref), 
                ),
                const Text("On Campus"),
              ],
            ),
            
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
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                  // Delete
                                  try {
                                    final id = s['id'];
                                    final url = Uri.parse('http://localhost:8080/api/sessions/$id');
                                    final res = await http.delete(url);
                                    if (res.statusCode == 200) {
                                      ref.refresh(historyProvider);
                                      ref.refresh(dailyAggProvider);
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
              onPressed: () {
                // Start Unspecified Session
                ref.read(sessionProvider.notifier).state = Session(startAt: DateTime.now());
                context.push('/now');
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
  Widget build(BuildContext context) {
    // ...
    // Note: I need to verify where to insert this method. 
    // It should be inside _HomeScreenState.
    // The previous view_file was useless (showed NowScreen).
    // I will Assume insertion before 'build' in _HomeScreenState
    // BUT I cannot "Assume". I need to find the right place.
    // Let's use view_file again on the correct lines 150-250 roughly.
    return Container(); // Dummy replacement to fail if I am wrong? No, I should READ first.

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
      final url = Uri.parse('$baseUrl/api/sessions'); 
      final response = await http.post(
        url,
        body: jsonEncode({
          "nodeId": selectedNodeId,
          "draftTitle": _titleController.text, // If creating new
          "minutes": session.durationMinutes,
          "startAt": session.startAt.toIso8601String(),
          "endAt": DateTime.now().toIso8601String(),
          // Points calculated by Server
          "focus": 3 
        }),
      );
      
      if (response.statusCode == 201) {
        ref.refresh(dailyAggProvider);
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
