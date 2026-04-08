import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

// -----------------------------------------------------------------------------
// 1. Models & State
// -----------------------------------------------------------------------------

class Session {
  final String? id;
  final DateTime startAt;
  final int? durationMinutes;

  Session({this.id, required this.startAt, this.durationMinutes});
}

// Global Providers
final sessionProvider = StateProvider<Session?>((ref) => null);

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

// --- Screens ---

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('DaigakuOS v2')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Zero Future Input", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                // Start Unspecified Session
                ref.read(sessionProvider.notifier).state = Session(startAt: DateTime.now());
                context.push('/now');
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text("DO NOW (Unspecified)", style: TextStyle(fontSize: 20)),
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(24)),
            ),
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

  Future<void> _submit() async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    
    setState(() => _isSubmitting = true);

    try {
      final url = Uri.parse('http://localhost:8080/api/sessions'); // Android Emulator needs 10.0.2.2 usually
      final response = await http.post(
        url,
        body: jsonEncode({
          "draftTitle": _titleController.text,
          "minutes": session.durationMinutes,
          "startAt": session.startAt.toIso8601String(),
          "endAt": DateTime.now().toIso8601String(),
          "points": (session.durationMinutes ?? 0) * 1.0, // Basic Calc
          "focus": 3 
        }),
      );
      
      if (response.statusCode == 201) {
        if (mounted) context.go('/');
      } else {
        // Fallback for demo without backend
        if (mounted) context.go('/');
      }
    } catch (e) {
      print("Network Error: $e");
      // Proceed mostly for demo
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
               onPressed: _isSubmitting ? null : _submit,
               child: _isSubmitting ? const CircularProgressIndicator() : const Text("RECORD RESULT"),
               style: FilledButton.styleFrom(padding: const EdgeInsets.all(20)),
            )
          ],
        ),
      ),
    );
  }
}
