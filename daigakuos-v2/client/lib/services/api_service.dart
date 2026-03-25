import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database_helper.dart';

class ApiService {
  // Use http://10.0.2.2:3000 for Android Emulator connecting to local Rails server.
  // Use http://127.0.0.1:3000 for iOS Simulator and Windows Desktop.
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1';
    } else {
      return 'http://127.0.0.1:3000/api/v1';
    }
  }

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
          'Authorization': 'Bearer daigaku_secret_token'
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
          'Authorization': 'Bearer daigaku_secret_token'
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
  static Future<List<dynamic>> fetchRankings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rankings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer daigaku_secret_token'
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
          'Authorization': 'Bearer daigaku_secret_token'
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
}
