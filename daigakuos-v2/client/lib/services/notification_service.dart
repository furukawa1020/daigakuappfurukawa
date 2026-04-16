import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
         // Phase 49: Handle Actions
         if (response.actionId == 'action_sharpen') {
            // logic to trigger sharpen API
         }
      },
    );

    // Request permissions (Android 13+)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleMokoInvitation() async {
    // Cancel existing to avoid duplicates
    await cancelAll();

    // Schedule for 24 hours later (or test with 10 seconds for debug?)
    // For production logic: 24 hours.
    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'ねぇ...',
      '1分だけでいいから、やってみない？',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'moko_channel',
          'Moko Notifications',
          channelDescription: 'Invitations from Moko',
          importance: Importance.max,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction('action_focus', '集中を始める (5分)', showsUserInterface: true),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'daigaku_channel', 
      'DaigakuAPP Notifications',
      channelDescription: 'Notifications for study session completion',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin.show(0, title, body, notificationDetails);
  }

  /// Schedule a daily 9 PM summary notification (XP + streak recap).
  /// Call once from app startup; it auto-repeats daily.
  Future<void> scheduleDailySummary({required int todayXP, required int streak}) async {
    await flutterLocalNotificationsPlugin.cancel(999); // clear previous

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 21, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final streakText = streak > 0 ? '🔥 $streak日連続！' : '今日から始めよう！';
    final xpText = todayXP > 0 ? '今日の獲得XP: $todayXP' : 'まだ記録がありません';

    await flutterLocalNotificationsPlugin.zonedSchedule(
      999,
      'Moko より今日のまとめ 🐾',
      '$xpText ｜ $streakText',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_summary_channel',
          '日次サマリー',
          channelDescription: 'Daily study summary from Moko',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at same time
    );
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
