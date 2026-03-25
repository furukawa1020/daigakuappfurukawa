import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final globalRankingsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchRankings();
});

final globalStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchGlobalStats();
});

// For Activity Feed, we would normally use a WebSocket listener (ActionCable).
// For now, let's implement the API calls in ApiService first.
