import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database_helper.dart';

class ApiService {
  // Use http://10.0.2.2:3000 for Android Emulator connecting to local Rails server.
  // Use http://127.0.0.1:3000 for iOS Simulator and Windows Desktop.
  // Override at build time with: --dart-define=API_BASE_URL_ANDROID=http://...
  static String get baseUrl {
    if (Platform.isAndroid) {
      return '${const String.fromEnvironment('API_BASE_URL_ANDROID', defaultValue: 'http://10.0.2.2:3000')}/api/v1';
    } else {
      return '${const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:3000')}/api/v1';
    }
  }

  // Override at build time with: --dart-define=API_SECRET_TOKEN=<your_token>
  // Intentionally invalid default ensures unauthenticated builds fail server-side.
  static const String _authToken =
      String.fromEnvironment('API_SECRET_TOKEN', defaultValue: 'MISSING_TOKEN_CONFIGURE_BUILD');

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
      await prefs.setString('device_id', deviceId);
    }
    return deviceId;
  }

  static Future<bool> pushSync() async {
    try {
      final deviceId = await getDeviceId();
      final db = DatabaseHelper();
      
      final stats = await db.getUserStats();
      final sessions = await db.getSessions();
      
      final payload = {
        'device_id': deviceId,
        'level': stats['level'],
        'xp': stats['totalPoints'],
        'streak': stats['currentStreak'],
        'coins': 0,
        'rest_days': stats['isRestDay'] ? 1 : 0,
        'sessions': sessions.map((s) => {
          'started_at': s['date'], 
          'ended_at': s['date'],
          'duration': s['durationMinutes'],
          'points': s['pointsEarned'],
          'quality': s['quality'] ?? 'A'
        }).toList(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/sync/push'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken'
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print("Sync Push Successful: ${response.body}");
        return true;
      } else {
        print("Sync Push Failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print('Sync Push Error: $e');
      return false;
    }
  }

  static Future<List<dynamic>> fetchMokoDictionary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mokos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken'
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['payload'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      print('Fetch Dictionary Error: $e');
      return [];
    }
  }

  static Future<List<dynamic>> fetchRankings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rankings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken'
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Fetch Rankings Error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> fetchGlobalStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken'
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Fetch Global Stats Error: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>?> fetchRaidStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/raid/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken'
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Fetch Raid Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> fetchWorldStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/world/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken'
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Fetch World Error: $e');
      return {};
    }
  }

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_authToken',
      };

  Future<bool> updateRole(String deviceId, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sync/update_role'),
      headers: _authHeaders,
      body: jsonEncode({'device_id': deviceId, 'role': role}),
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> useSkill(String deviceId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/skills/use'),
      headers: _authHeaders,
      body: jsonEncode({'device_id': deviceId}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Skill failed';
      throw Exception(error);
    }
  }

  // Phase 43: Monster Hunter Loop
  Future<Map<String, dynamic>> fetchQuests(String deviceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quests?device_id=$deviceId'),
      headers: _authHeaders,
    );
    return jsonDecode(response.body);
  }

  Future<bool> startQuest(String deviceId, int questId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quests/$questId/start'),
      headers: _authHeaders,
      body: jsonEncode({'device_id': deviceId}),
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> fetchBlacksmith(String deviceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/blacksmith?device_id=$deviceId'),
      headers: _authHeaders,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> craftItem(String deviceId, String itemId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/blacksmith/craft'),
      headers: _authHeaders,
      body: jsonEncode({'device_id': deviceId, 'item_id': itemId}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Crafting failed';
      throw Exception(error);
    }
  }

  Future<Map<String, dynamic>> sharpen(String deviceId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/skills/sharpen'),
      headers: _authHeaders,
      body: jsonEncode({'device_id': deviceId}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Sharpening failed';
      throw Exception(error);
    }
  }

  Future<Map<String, dynamic>> heal(String deviceId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/skills/heal'),
      headers: _authHeaders,
      body: jsonEncode({'device_id': deviceId}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Healing failed';
      throw Exception(error);
    }
  }

  Future<Map<String, dynamic>> eat(String deviceId, String mealId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/skills/eat'),
      headers: _authHeaders,
      body: jsonEncode({'device_id': deviceId, 'meal_id': mealId}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> combine(String deviceId, String itemId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/skills/combine'),
      headers: _authHeaders,
      body: jsonEncode({'device_id': deviceId, 'item_id': itemId}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> useItem(String deviceId, String itemId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/skills/use_item'),
      headers: _authHeaders,
      body: jsonEncode({'device_id': deviceId, 'item_id': itemId}),
    );
    return jsonDecode(response.body);
  }
}
