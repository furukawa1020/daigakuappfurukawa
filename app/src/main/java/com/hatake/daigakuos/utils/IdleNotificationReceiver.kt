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
import com.hatake.daigakuos.R

class IdleNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        showNotification(context)
    }

    private fun showNotification(context: Context) {
        val channelId = "moko_idle_channel"
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create Channel for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Moko Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications from Moko when idle"
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Deep link intent to open the app
        val contentIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent: PendingIntent = PendingIntent.getActivity(
            context,
            0,
            contentIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Build Notification
        val builder = NotificationCompat.Builder(context, channelId)
            // Use ic_launcher as a fallback if real icon doesn't exist yet
            .setSmallIcon(R.mipmap.ic_launcher_round) 
            .setContentTitle("Moko 🐾")
            .setContentText("暇してる...？ 1分だけやってみる？")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)

        notificationManager.notify(1001, builder.build())
    }

    companion object {
        fun scheduleIdleNotification(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, IdleNotificationReceiver::class.java)
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Cancel any existing alarm first
            alarmManager.cancel(pendingIntent)

            // Schedule for 2 hours later (represented in milliseconds)
            val triggerTime = System.currentTimeMillis() + (2 * 60 * 60 * 1000L)
            
            // Note: In Android 12+, inexact alarms might be restricted based on exact alarm permission.
            // Using set() which is inexact and safe by default.
            alarmManager.set(
                AlarmManager.RTC_WAKEUP,
                triggerTime,
                pendingIntent
            )
        }

        fun cancelIdleNotification(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, IdleNotificationReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
        }
    }
}
