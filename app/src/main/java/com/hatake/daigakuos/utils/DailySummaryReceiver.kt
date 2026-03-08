package com.hatake.daigakuos.utils

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.hatake.daigakuos.MainActivity
import com.hatake.daigakuos.R
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class DailySummaryReceiver : BroadcastReceiver() {

    @Inject
    lateinit var sessionDao: com.hatake.daigakuos.data.local.dao.SessionDao

    @Inject
    lateinit var getStreakUseCase: com.hatake.daigakuos.domain.usecase.GetStreakUseCase

    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val todayXP = getTodayXP()
                val streak = getStreakUseCase()
                showNotification(context, todayXP, streak)
            } finally {
                pendingResult.finish()
            }
        }
    }

    private suspend fun getTodayXP(): Int {
        val cal = java.util.Calendar.getInstance()
        val startOfDay = cal.apply {
            set(java.util.Calendar.HOUR_OF_DAY, 0)
            set(java.util.Calendar.MINUTE, 0)
            set(java.util.Calendar.SECOND, 0)
            set(java.util.Calendar.MILLISECOND, 0)
        }.timeInMillis
        val todaySessions = sessionDao.getSessionsSince(startOfDay)
        return todaySessions.sumOf { it.points ?: 0.0 }.toInt()
    }

    private fun showNotification(context: Context, xp: Int, streak: Int) {
        val channelId = "daily_summary"
        val notifManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "日次サマリー",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "今日の勉強まとめをお知らせします"
            }
            notifManager.createNotificationChannel(channel)
        }

        val tapIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, tapIntent, PendingIntent.FLAG_IMMUTABLE
        )

        val streakText = if (streak > 0) "🔥 $streak日連続！" else "今日から始めよう！"
        val xpText = if (xp > 0) "今日の獲得XP: $xp" else "まだ記録がありません"

        val notif = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.moko_egg)
            .setContentTitle("Moko より今日のまとめ 🐾")
            .setContentText("$xpText ｜ $streakText")
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("$xpText\n$streakText\n\nアプリを開いて続けてみよう！"))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        notifManager.notify(999, notif)
    }
}
