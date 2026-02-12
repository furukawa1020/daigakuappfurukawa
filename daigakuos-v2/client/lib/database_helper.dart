import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
      version: 3,
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
            mood_pre TEXT,
            mood_post TEXT,
            FOREIGN KEY(node_id) REFERENCES nodes(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE rest_days (
            day TEXT PRIMARY KEY
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('CREATE TABLE IF NOT EXISTS rest_days (day TEXT PRIMARY KEY)');
        }
        if (oldVersion < 3) {
           await db.execute('ALTER TABLE sessions ADD COLUMN mood_pre TEXT');
           await db.execute('ALTER TABLE sessions ADD COLUMN mood_post TEXT');
        }
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
    String? moodPre,
    String? moodPost,
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
      'mood_pre': moodPre,
      'mood_post': moodPost,
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

  // -----------------------------------------------------------------------------
  // REST DAYS
  // -----------------------------------------------------------------------------

  Future<void> toggleRestDay(String day) async {
    final db = await database;
    final res = await db.query('rest_days', where: 'day = ?', whereArgs: [day]);
    if (res.isNotEmpty) {
      await db.delete('rest_days', where: 'day = ?', whereArgs: [day]);
    } else {
      await db.insert('rest_days', {'day': day});
    }
  }

  Future<bool> isRestDay(String day) async {
    final db = await database;
    final res = await db.query('rest_days', where: 'day = ?', whereArgs: [day]);
    return res.isNotEmpty;
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
    
    // 2.5 Total Minutes
    final totalMinsRes = await db.rawQuery('SELECT SUM(minutes) as total FROM sessions');
    int totalMinutes = (totalMinsRes.first['total'] as num?)?.toInt() ?? 0;

    // 3. Level Calc (Sqrt Curve)
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

    // 4. Streak Calculation (ADHD-Special: 2-day grace + Rest Days)
    // Get unique session days
    final sessionDaysRes = await db.rawQuery(
      "SELECT DISTINCT substr(start_at, 1, 10) as day FROM sessions"
    );
    // Get unique rest days
    final restDaysRes = await db.query('rest_days', columns: ['day']);
    
    Set<String> allActiveDays = {
      ...sessionDaysRes.map((e) => e['day'] as String),
      ...restDaysRes.map((e) => e['day'] as String),
    };
    
    List<DateTime> sortedDates = allActiveDays
        .map((d) => DateTime.parse(d))
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Descending

    int streak = 0;
    if (sortedDates.isNotEmpty) {
      DateTime latest = sortedDates.first;
      int daysSinceLatest = now.difference(latest).inDays;
      
      // If latest activity is within 2 days (today, yesterday, or day before), continue
      if (daysSinceLatest <= 2) {
        streak = 1;
        for (int i = 0; i < sortedDates.length - 1; i++) {
          int gap = sortedDates[i].difference(sortedDates[i+1]).inDays;
          if (gap <= 3) { // Allow skipping 2 days (X, skip, skip, Y -> diff is 3)
            streak++;
          } else {
            break;
          }
        }
      }
    }

    bool todayIsRest = await isRestDay(todayStr);

    return {
      'totalPoints': totalPoints,
      'totalMinutes': totalMinutes,
      'level': level,
      'progress': progress,
      'pointsToNext': pointsToNext,
      'dailyPoints': dailyPoints,
      'dailyMinutes': dailyMinutes,
      'currentStreak': streak,
      'isRestDay': todayIsRest,
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

  Future<void> exportData() async {
    final db = await database;
    final sessions = await db.query('sessions');
    final nodes = await db.query('nodes');
    
    final data = {
      'generated_at': DateTime.now().toIso8601String(),
      'sessions': sessions,
      'nodes': nodes,
    };
    
    final jsonStr = jsonEncode(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/daigaku_export_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonStr);
    
    await Share.shareXFiles([XFile(file.path)], text: 'DaigakuAPP Data Backup');
  }

  Future<void> importData(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final db = await database;
      
      // Clear existing data
      await db.delete('sessions');
      await db.delete('nodes');
      
      // Restore Nodes
      final nodes = data['nodes'] as List;
      for (var n in nodes) {
        await db.insert('nodes', n as Map<String, dynamic>);
      }
      
      // Restore Sessions
      final sessions = data['sessions'] as List;
      for (var s in sessions) {
        await db.insert('sessions', s as Map<String, dynamic>);
      }
    } catch (e) {
      print("Import Error: $e");
      throw Exception("データの復元に失敗しました。ファイル形式を確認してください。");
    }
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('sessions');
    await db.delete('nodes');
  }
}
