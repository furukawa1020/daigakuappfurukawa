import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:math';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'daigaku_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE nodes (
            id TEXT PRIMARY KEY,
            title TEXT,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE sessions (
            id TEXT PRIMARY KEY,
            node_id TEXT,
            draft_title TEXT,
            start_at TEXT,
            minutes INTEGER,
            points REAL,
            focus INTEGER,
            is_on_campus INTEGER,
            FOREIGN KEY(node_id) REFERENCES nodes(id)
          )
        ''');
      },
    );
  }

  // --- Logic ---

  Future<void> insertSession({
    required DateTime startAt,
    required int minutes,
    required String draftTitle,
    String? nodeId,
    required bool isOnCampus,
  }) async {
    final db = await database;
    final now = DateTime.now();

    // 1. Calculate Points
    // Base: 30 pts per minute (assuming focus 3)
    // Multiplier: 1.5x if on campus
    double basePoints = 30.0 * minutes;
    double multiplier = isOnCampus ? 1.5 : 1.0;
    double finalPoints = basePoints * multiplier;

    // 2. Handle Node (Auto-create or Update)
    String? finalNodeId = nodeId;
    
    if (finalNodeId != null) {
      await db.update(
        'nodes', 
        {'updated_at': now.toIso8601String()}, 
        where: 'id = ?', 
        whereArgs: [finalNodeId]
      );
    } else if (draftTitle.isNotEmpty) {
      // Try to find existing node by title
      final List<Map<String, dynamic>> maps = await db.query(
        'nodes',
        where: 'title = ?',
        whereArgs: [draftTitle],
      );
      
      if (maps.isNotEmpty) {
        finalNodeId = maps.first['id'] as String;
        await db.update(
          'nodes', 
          {'updated_at': now.toIso8601String()}, 
          where: 'id = ?', 
          whereArgs: [finalNodeId]
        );
      } else {
        // Create New Node
        finalNodeId = 'node_${now.millisecondsSinceEpoch}';
        await db.insert('nodes', {
          'id': finalNodeId,
          'title': draftTitle,
          'updated_at': now.toIso8601String(),
        });
      }
    }

    // 3. Insert Session
    final sessionId = now.millisecondsSinceEpoch.toString();
    await db.insert('sessions', {
      'id': sessionId,
      'node_id': finalNodeId,
      'draft_title': draftTitle,
      'start_at': startAt.toIso8601String(),
      'minutes': minutes,
      'points': finalPoints,
      'focus': 3, // Default Focus
      'is_on_campus': isOnCampus ? 1 : 0,
    });
  }

  Future<List<Map<String, dynamic>>> getSessions({int limit = 50}) async {
    final db = await database;
    final res = await db.query(
      'sessions', 
      orderBy: 'start_at DESC', 
      limit: limit
    );
    // Convert keys to match expected output if needed, but we can adapt UI
    return res.map((e) => {
      'id': e['id'],
      'title': e['draft_title'],
      'startAt': e['start_at'],
      'minutes': e['minutes'],
      'points': e['points'],
    }).toList();
  }
  
  Future<void> deleteSession(String id) async {
    final db = await database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<void> updateSessionTitle(String id, String newTitle) async {
    final db = await database;
    await db.update('sessions', {'draft_title': newTitle}, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getUserStats() async {
    final db = await database;
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10); // YYYY-MM-DD

    // 1. Lifetime Points
    final sumRes = await db.rawQuery('SELECT SUM(points) as total FROM sessions');
    double totalPoints = (sumRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // 2. Daily Stats
    final dailyRes = await db.rawQuery(
      "SELECT SUM(points) as pts, SUM(minutes) as mins FROM sessions WHERE start_at LIKE '$todayStr%'"
    );
    double dailyPoints = (dailyRes.first['pts'] as num?)?.toDouble() ?? 0.0;
    int dailyMinutes = (dailyRes.first['mins'] as num?)?.toInt() ?? 0;

    // 3. Level Calc (Sqrt Curve)
    // Level = sqrt(Points / 100)
    double val = totalPoints / 100.0;
    int level = (sqrt(val)).toInt() + 1;

    double currentBase = 100.0 * (level - 1) * (level - 1);
    double nextBase = 100.0 * level * level;
    double pointsToNext = nextBase - totalPoints;
    double progress = 0.0;
    if (nextBase > currentBase) {
      progress = (totalPoints - currentBase) / (nextBase - currentBase);
    }
    if (progress > 1.0) progress = 1.0;

    // 4. Streak Calculation
    // Get unique days
    final daysRes = await db.rawQuery(
      "SELECT DISTINCT substr(start_at, 1, 10) as day FROM sessions ORDER BY day DESC"
    );
    
    int streak = 0;
    List<String> days = daysRes.map((e) => e['day'] as String).toList();
    
    if (days.isNotEmpty) {
      // Check today
      if (days[0] == todayStr) {
        streak = 1;
        // Check backwards
        for (int i = 1; i < days.length; i++) {
          final expected = now.subtract(Duration(days: i)).toIso8601String().substring(0, 10);
          if (days[i] == expected) {
            streak++;
          } else {
             break; 
          }
        }
      } else {
        // Check yesterday (grace period)
        final yesterdayStr = now.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
        if (days[0] == yesterdayStr) {
           streak = 1;
           for (int i = 1; i < days.length; i++) {
              final expected = now.subtract(Duration(days: i + 1)).toIso8601String().substring(0, 10);
              if (days[i] == expected) {
                streak++;
              } else {
                 break; 
              }
           }
        }
      }
    }

    return {
      'totalPoints': totalPoints,
      'level': level,
      'progress': progress,
      'pointsToNext': pointsToNext,
      'dailyPoints': dailyPoints,
      'dailyMinutes': dailyMinutes,
      'currentStreak': streak,
    };
  }

  Future<Map<String, dynamic>> getDailyAgg() async {
    final stats = await getUserStats();
    return {
      'totalPoints': stats['dailyPoints'],
      'totalMinutes': stats['dailyMinutes'],
      'sessionCount': 0, // Not vital
    };
  }

  Future<List<Map<String, dynamic>>> getWeeklyAgg() async {
    final db = await database;
    final now = DateTime.now();
    // 7 days ago
    final start = now.subtract(const Duration(days: 6)); 
    final startStr = start.toIso8601String().substring(0, 10);
    
    final res = await db.rawQuery(
      "SELECT substr(start_at, 1, 10) as day, SUM(points) as points, SUM(minutes) as minutes FROM sessions WHERE start_at >= '$startStr' GROUP BY day ORDER BY day ASC"
    );
    
    return res.map((e) => {
      'day': e['day'],
      'points': (e['points'] as num).toDouble(),
      'minutes': (e['minutes'] as num).toInt(),
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getSuggestions() async {
    final db = await database;
    final hour = DateTime.now().hour;
    // Simple logic: return most updated nodes
    // Ideal: Filter by time of day like backend, but simple is fine for now
    
    final res = await db.query(
      'nodes',
      orderBy: 'updated_at DESC',
      limit: 10
    );
    
    return res.map((e) => {
      'id': e['id'],
      'title': e['title'],
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getSessionsForDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final res = await db.query(
      'sessions',
      where: 'start_at LIKE ?',
      whereArgs: ['$dateStr%'],
      orderBy: 'start_at DESC'
    );
    return res.map((e) => {
      'id': e['id'],
      'title': e['draft_title'],
      'startAt': e['start_at'],
      'minutes': e['minutes'],
      'points': e['points'],
    }).toList();
  }

  Future<List<DateTime>> getSessionDates() async {
    final db = await database;
    final res = await db.rawQuery("SELECT DISTINCT substr(start_at, 1, 10) as day FROM sessions");
    return res.map((e) => DateTime.parse(e['day'] as String)).toList();
  }
}
