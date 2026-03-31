package com.hatake.daigakuos.utils

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.hatake.daigakuos.MainActivity
import com.hatake.daigakuos.data.local.AppDatabase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Receives a repeating daily alarm at 9 PM and shows a summary notification.
 * Uses direct Room access (no Hilt injection needed in BroadcastReceiver).
 */
class DailySummaryReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val db = AppDatabase.getInstance(context)
                val todayXP = getTodayXP(db)
                val streak = computeStreak(db)
                showNotification(context, todayXP, streak)
            } finally {
                pendingResult.finish()
            }
        }
    }

    private suspend fun getTodayXP(db: AppDatabase): Int {
        val cal = java.util.Calendar.getInstance().apply {
            set(java.util.Calendar.HOUR_OF_DAY, 0)
            set(java.util.Calendar.MINUTE, 0)
            set(java.util.Calendar.SECOND, 0)
            set(java.util.Calendar.MILLISECOND, 0)
        }
        val startOfDayMs = cal.timeInMillis
        // Use all sessions where completedAt >= today midnight
        val allSessions = db.sessionDao().getSessionsSince(startOfDayMs)
        return allSessions.sumOf { it.points ?: 0.0 }.toInt()
    }

    private suspend fun computeStreak(db: AppDatabase): Int {
        val activeDays = db.aggDao().getActiveDaysDesc()
        if (activeDays.isEmpty()) return 0

        val today = todayKey()
        var streak = 0
        var expected = today
        for (entry in activeDays) {
            if (entry.yyyymmdd == expected) {
                streak++
                expected = prevDay(expected)
            } else if (entry.yyyymmdd == prevDay(today) && expected == today) {
                expected = prevDay(today)
                if (entry.yyyymmdd == expected) {
                    streak++
                    expected = prevDay(expected)
                } else break
            } else break
        }
        return streak
    }

    private fun todayKey(): Int {
        val c = java.util.Calendar.getInstance()
        return c.get(java.util.Calendar.YEAR) * 10000 +
                (c.get(java.util.Calendar.MONTH) + 1) * 100 +
                c.get(java.util.Calendar.DAY_OF_MONTH)
    }

    private fun prevDay(key: Int): Int {
        val c = java.util.Calendar.getInstance().apply {
            set(key / 10000, (key / 100) % 100 - 1, key % 100)
            add(java.util.Calendar.DAY_OF_MONTH, -1)
        }
        return c.get(java.util.Calendar.YEAR) * 10000 +
                (c.get(java.util.Calendar.MONTH) + 1) * 100 +
                c.get(java.util.Calendar.DAY_OF_MONTH)
    }

    private fun showNotification(context: Context, xp: Int, streak: Int) {
        val channelId = "daily_summary"
        val notifManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notifManager.createNotificationChannel(
                NotificationChannel(channelId, "日次サマリー", NotificationManager.IMPORTANCE_DEFAULT)
            )
        }

        val tapIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, tapIntent, PendingIntent.FLAG_IMMUTABLE
        )

        val streakText = if (streak > 0) "🔥 ${streak}日連続！" else "今日から始めよう！"
        val xpText = if (xp > 0) "今日の獲得XP: $xp" else "まだ記録がありません"

        val notif = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Moko より今日のまとめ 🐾")
            .setContentText("$xpText ｜ $streakText")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("$xpText\n$streakText\n\nアプリを開いて続けてみよう！")
            )
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        notifManager.notify(999, notif)
    }

    companion object {
        fun scheduleDailySummary(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, DailySummaryReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context, 1001, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val trigger = java.util.Calendar.getInstance().apply {
                set(java.util.Calendar.HOUR_OF_DAY, 21)
                set(java.util.Calendar.MINUTE, 0)
                set(java.util.Calendar.SECOND, 0)
                set(java.util.Calendar.MILLISECOND, 0)
                if (timeInMillis <= System.currentTimeMillis()) {
                    add(java.util.Calendar.DAY_OF_YEAR, 1)
                }
            }.timeInMillis

            alarmManager.setRepeating(
                AlarmManager.RTC_WAKEUP,
                trigger,
                AlarmManager.INTERVAL_DAY,
                pendingIntent
            )
        }
    }
}
