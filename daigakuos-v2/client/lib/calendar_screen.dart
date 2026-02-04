import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart'; // Add go_router import
import 'main.dart';
import 'database_helper.dart';

// Provider to fetch sessions for a specific day
final sessionsForDayProvider = FutureProvider.family<List<Map<String, dynamic>>, DateTime>((ref, date) async {
  // Ideally, query DB for this specific date range. For now, we can fetch all and filter or add a DB method.
  // Optimization: Add getSessionsForDate(DateTime) to DatabaseHelper later. 
  // For now, let's use the existing getting all sessions (or limit 100) and filtering client side.
  // Actually, let's add the method to DatabaseHelper for efficiency.
  return await DatabaseHelper().getSessionsForDate(date);
});

// Provider to get all session dates for markers
final sessionDatesProvider = FutureProvider<List<DateTime>>((ref) async {
  return await DatabaseHelper().getSessionDates();
});

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    // Watch markers (events)
    final eventsAsync = ref.watch(sessionDatesProvider);

    return Scaffold(
      body: PremiumBackground(
        child: Column(
          children: [
            AppBar(
              title: const Text("Study Calendar", style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              actions: [
                IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: "Export Data",
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Exporting data...")));
                    await DatabaseHelper().exportData();
                  },
                )
              ],
            ),
            
            // Calendar Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassCard(
                child: eventsAsync.when(
                  data: (dates) => TableCalendar(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    
                    // Style
                    headerStyle: HeaderStyle(
                       titleCentered: true,
                       formatButtonVisible: false,
                       TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                       leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).primaryColor),
                       rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).primaryColor),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(color: Colors.blue.withOpacity(0.5), shape: BoxShape.circle),
                      selectedDecoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                      markerDecoration: const BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle),
                    ),
                    
                    eventLoader: (day) {
                      // Check if day matches any in dates list
                      // Simple check for now (ignoring time)
                      return dates.where((d) => isSameDay(d, day)).toList();
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const Center(child: Text("Error loading calendar")),
                ),
              ),
            ),
            
            const Divider(),
            
            // Session List for Selected Day
            Expanded(
              child: _selectedDay == null 
                ? const SizedBox() 
                : Consumer(
                    builder: (context, ref, _) {
                      final sessionsAsync = ref.watch(sessionsForDayProvider(_selectedDay!));
                      return sessionsAsync.when(
                        data: (sessions) {
                          if (sessions.isEmpty) {
                            return Center(child: Text("No study history for ${DateFormat('M/d').format(_selectedDay!)}", style: const TextStyle(color: Colors.grey)));
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: sessions.length,
                            itemBuilder: (context, index) {
                              final s = sessions[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(12),
                                  child: ListTile(
                                    title: Text(s['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text("${s['minutes']} min • ${s['points'].toStringAsFixed(0)} pts"),
                                    leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                                    trailing: Text(
                                       DateTime.parse(s['startAt']).toLocal().toString().substring(11, 16),
                                       style: const TextStyle(fontSize: 12, color: Colors.grey)
                                    ),
                                  ),
                                ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text("Error: $e")),
                      );
                    },
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
}
